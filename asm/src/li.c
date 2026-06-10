#include "common.h"
#include "li.h"
#include "dc.h"
#include "rf.h"
#include <math.h>
#include <string.h>
#include <stdio.h>
#include <assert.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <sys/mman.h>

static uint32_t li_t2samples(double t_ns) {
    uint32_t samples = (uint32_t)llround(t_ns / LI_NS_PER_SAMPLE);
    if (samples > LI_MAX_SAMPLES) samples = LI_MAX_SAMPLES;
    return samples;
}

static void li_sam2insn(li_sam_t *sam, li_insn_t *insn) {
    insn->arm = sam->opt.arm;
    insn->sticky_arm = 0;
    insn->idle = 0;
    insn->marker = 0;
    insn->samples = sam->samples;
    uint32_t tsamples = li_t2samples(sam->t_ns);
    insn->stride = (tsamples % sam->samples == 0) ?
        (tsamples / sam->samples) : (tsamples / sam->samples + 1);
    insn->dsamples = li_t2samples(sam->opt.tplus_ns);
}

static void li_idl2insn(li_idl_t *idl, li_insn_t *insn) {
    insn->arm = idl->opt.arm;
    insn->sticky_arm = 0;
    insn->idle = 1;
    insn->marker = 0;
    insn->samples = li_t2samples(idl->t_ns);
    insn->dsamples = li_t2samples(idl->opt.tplus_ns);
    insn->stride = 1;
}

static int li_parse_opt(char *paren, li_opt_t *opt) {

    opt->arm = 0;
    opt->tplus_ns = 0;

    char tmp[256];
    snprintf(tmp, sizeof(tmp), "%s", paren);

    char *save = NULL;

    for (char *tok = strtok_r(tmp, " \t\r\n", &save); tok != NULL;
         tok = strtok_r(NULL, " \t\r\n", &save)) {

        if (strcmp(tok, "arm") == 0) {

            opt->arm = 1;

        } else if (strncmp(tok, "t+", 2) == 0) {

            if (parse_time_double(tok + 2, &opt->tplus_ns) != 0)
                return -1;

        } else {
            // unknown flag/token inside parens
            return -1;
        }

    }

    return 0;

}

static int li_parse_sam(char *line, li_sam_t *sam) {

    sam->opt.arm = 0;
    sam->opt.tplus_ns = 0;

    uint32_t samples;

    char t_tok[32] = {0};
    char paren[256] = {0};

    int got = sscanf(line,
        " sam n=%u t=%31s ( %255[^)] )",
        &samples, t_tok, paren);

    if (got < 2) return -1;
    if (got == 2) paren[0] = '\0';

    sam->samples = samples;

    if (parse_time_double(t_tok, &(sam->t_ns)) != 0) return -1;

    if (paren[0] != '\0') {
        if (li_parse_opt(paren, &(sam->opt)) != 0) return -1;
    }

    return 0;

}

static int li_parse_idl(char *line, li_idl_t *idl) {

    idl->opt.arm = 0;
    idl->opt.tplus_ns = 0;

    char t_tok[32] = {0};
    char paren[256] = {0};

    int got = sscanf(line,
        " idl t=%31s ( %255[^)] )", t_tok, paren);

    if (got < 1) return -1;
    if (got == 1) paren[0] = '\0';

    if (parse_time_double(t_tok, &(idl->t_ns)) != 0) return -1;

    if (paren[0] != '\0') {
        if (li_parse_opt(paren, &(idl->opt)) != 0) return -1;
    }

    return 0;

}

int li_parse_insn(char *line, li_insn_t *insn) {

    char op[4] = {0};

    if (!sscanf(line, " %3s", op)) {
        return -1;
    }

    if (strcmp(op, "sam") == 0) {

        li_sam_t sam;
        li_parse_sam(line, &sam);
        li_sam2insn(&sam, insn);

    } else if (strcmp(op, "idl") == 0) {

        li_idl_t idl;
        li_parse_idl(line, &idl);
        li_idl2insn(&idl, insn);

    } else {

        return -1;

    }

    return 0;

}

void li_assemble(li_program_t *prog) {

    for (unsigned int i = 0; i < prog->len; i++) {

        li_insn_t *insn = &(prog->insns[i]);
        uint32_t *reg = &(prog->seq_regs[i * LI_REG_PER_INSN]);

        // Pack 62-bit li_insn_t into 2 x 32-bit registers
        // insn[61:32] → reg[0][29:0], insn[31:0] → reg[1]
        reg[0] = (insn->arm << 29) | (insn->sticky_arm << 28) |
                 (insn->idle << 27) | (insn->marker << 26) |
                 (insn->samples << 6) | (insn->dsamples >> 14);
        reg[1] = ((insn->dsamples & 0x3FFF) << 18) | insn->stride;

    }

    prog->ctrl_regs[0] = prog->ctrl.default_I == -1 ? -1 : (int32_t)(prog->ctrl.default_I & 0x3fff);
    prog->ctrl_regs[1] = prog->ctrl.default_Q == -1 ? -1 : (int32_t)(prog->ctrl.default_Q & 0x3fff);
    prog->ctrl_regs[2] = prog->ctrl.max_burst  == -1 ? -1 : (int32_t)(prog->ctrl.max_burst  & 0xff);
    if (prog->ctrl.base_addr == -1) {
        prog->ctrl_regs[3] = -1;
        prog->ctrl_regs[4] = -1;
    } else {
        prog->ctrl_regs[3] = (int32_t)(((uint64_t)prog->ctrl.base_addr >> 32) & 0x1ffff);
        prog->ctrl_regs[4] = (int32_t)((uint64_t)prog->ctrl.base_addr & 0xffffffff);
    }
    prog->ctrl_regs[LI_CTRL_REGS-1] = (prog->ctrl.default_I != -1) || (prog->ctrl.default_Q != -1) ||
        (prog->ctrl.max_burst != -1) || (prog->ctrl.base_addr != -1);

}

int li_load_insns(int li_channel, li_program_t *li_program) {

    assert(0 <= li_channel && li_channel <= LI_CHANNELS - 1);

    char uio_path[32];
    snprintf(uio_path, sizeof(uio_path), "/dev/uio%d", li_uio_map[li_channel]);

    int li_fd = open(uio_path, O_RDWR);
    if (li_fd < 0) {
        fprintf(stderr, "open(\"%s\") failed: %s\n", uio_path, strerror(errno));
        return 1;
    }

    void *li_va = mmap(NULL, 0x1000, PROT_READ | PROT_WRITE, MAP_SHARED, li_fd, 0);
    if (li_va == MAP_FAILED) {
        fprintf(stderr, "mmap() %s failed: %s\n", uio_path, strerror(errno));
        close(li_fd);
        return 1;
    }

    volatile uint32_t *li_base = (volatile uint32_t *)((char *)li_va);
    unsigned int n = li_program->len;

    for (int i = 0; i < LI_CTRL_REGS; i++) {
        if (li_program->ctrl_regs[i] != -1)
            *(li_base + LI_BRAM_SEQ_REGS + i) = li_program->ctrl_regs[i];
    }
    *(li_base + LI_BRAM_SEQ_REGS + LI_CTRL_REGS - 1) = 0;
    *(li_base + LI_BRAM_SEQ_REGS + LI_CTRL_REGS - 1) = 1;

    for (unsigned int i = 0; i < n; i++) {
        li_base[BRAM_IST_ADDR] = i;
        for (unsigned int k = 0; k < LI_REG_PER_INSN; k++)
            li_base[BRAM_IST_LO + k] = li_program->seq_regs[i * LI_REG_PER_INSN + k];
        li_base[BRAM_IST_STRB(LI_REG_PER_INSN)] = 0;
        li_base[BRAM_IST_STRB(LI_REG_PER_INSN)] = 1;
    }

    for (unsigned int j = 0; j < n; j++) {
        li_base[BRAM_PCST_ADDR] = j;
        li_base[BRAM_PCST]      = j;
        li_base[BRAM_PCST_STRB] = 0;
        li_base[BRAM_PCST_STRB] = 1;
    }

    li_base[BRAM_ITERS(LI_REG_PER_INSN)] = li_program->repeat;
    li_base[BRAM_DEPTH(LI_REG_PER_INSN)] = n - 1;
    li_base[BRAM_START(LI_REG_PER_INSN)] = 0;
    li_base[BRAM_START(LI_REG_PER_INSN)] = 1;

#if EXE
    __asm__ __volatile__("dsb oshst" ::: "memory");
#endif

    munmap(li_va, 0x1000);
    close(li_fd);
    return 0;
}

int li_read_regs(int li_channel, uint32_t *seq_regs, uint32_t *ctrl_regs) {

    assert(0 <= li_channel && li_channel <= LI_CHANNELS - 1);

    char uio_path[32];
    snprintf(uio_path, sizeof(uio_path), "/dev/uio%d", li_uio_map[li_channel]);

    int li_fd = open(uio_path, O_RDWR);
    if (li_fd < 0) {
        fprintf(stderr, "open(\"%s\") failed: %s\n", uio_path, strerror(errno));
        return 1;
    }

    void *li_va = mmap(NULL, 0x1000, PROT_READ | PROT_WRITE, MAP_SHARED, li_fd, 0);
    if (li_va == MAP_FAILED) {
        fprintf(stderr, "mmap() %s failed: %s\n", uio_path, strerror(errno));
        close(li_fd);
        return 1;
    }

    volatile uint32_t *li_base = (volatile uint32_t *)((char *)li_va);

    for (int i = 0; i < LI_BRAM_SEQ_REGS; i++) {
        seq_regs[i] = *(li_base + i);
    }
    for (int i = 0; i < LI_CTRL_REGS; i++) {
        ctrl_regs[i] = *(li_base + LI_BRAM_SEQ_REGS + i);
    }

    munmap(li_va, 0x1000);
    close(li_fd);
    return 0;

}

int li_write_regs(int li_channel, li_program_t *li_program, int uartfd) {

    uint8_t tx[6] = {0, 0, 0, 0, 0, 0};

    ssize_t n;

    int base = DC_SEQ_REGS + DC_CTRL_REGS + RF_SEQ_REGS + RF_CTRL_REGS;

    for (int i = 0; i < LI_CTRL_REGS - 1; i++) {

        if (li_program->ctrl_regs[i] != -1) {
            tx[0] = (uint8_t)(base + LI_SEQ_REGS + i);
            tx[1] = (uint8_t)(((uint32_t)li_program->ctrl_regs[i]) >> 24);
            tx[2] = (uint8_t)(((uint32_t)li_program->ctrl_regs[i]) >> 16);
            tx[3] = (uint8_t)(((uint32_t)li_program->ctrl_regs[i]) >> 8);
            tx[4] = (uint8_t)(((uint32_t)li_program->ctrl_regs[i]));
        }

        n = write(uartfd, tx, sizeof(tx) - 1);
        if (n < 0) {
            perror("write error");
            return -1;
        }

    }

    tx[0] = (uint8_t)(base + LI_SEQ_REGS + LI_CTRL_REGS - 1);
    tx[1] = 0;
    tx[2] = 0;
    tx[3] = 0;
    tx[4] = 0;

    n = write(uartfd, tx, sizeof(tx) - 1);
    if (n < 0) {
        perror("write error");
        return -1;
    }

    tx[0] = (uint8_t)(base + LI_SEQ_REGS + LI_CTRL_REGS - 1);
    uint32_t chsel = 1U << li_channel;
    tx[1] = (uint8_t)(chsel >> 24);
    tx[2] = (uint8_t)(chsel >> 16);
    tx[3] = (uint8_t)(chsel >> 8);
    tx[4] = (uint8_t)(chsel);

    n = write(uartfd, tx, sizeof(tx) - 1);
    if (n < 0) {
        perror("write error");
        return -1;
    }

    for (int i = 0; i < LI_SEQ_REGS - 1; i++) {

        tx[0] = (uint8_t)(base + i);
        tx[1] = (uint8_t)(li_program->seq_regs[i] >> 24);
        tx[2] = (uint8_t)(li_program->seq_regs[i] >> 16);
        tx[3] = (uint8_t)(li_program->seq_regs[i] >> 8);
        tx[4] = (uint8_t)(li_program->seq_regs[i]);

        n = write(uartfd, tx, sizeof(tx) - 1);
        if (n < 0) {
            perror("write error");
            return -1;
        }

    }

    tx[0] = (uint8_t)(base + LI_SEQ_REGS - 1);
    tx[1] = 0;
    tx[2] = 0;
    tx[3] = 0;
    tx[4] = 0;

    n = write(uartfd, tx, sizeof(tx) - 1);
    if (n < 0) {
        perror("write error");
        return -1;
    }

    tx[0] = (uint8_t)(base + LI_SEQ_REGS - 1);
    chsel = 1U << li_channel;
    tx[1] = (uint8_t)(chsel >> 24);
    tx[2] = (uint8_t)(chsel >> 16);
    tx[3] = (uint8_t)(chsel >> 8);
    tx[4] = (uint8_t)(chsel);

    n = write(uartfd, tx, sizeof(tx) - 1);
    if (n < 0) {
        perror("write error");
        return -1;
    }

    return 0;

}
