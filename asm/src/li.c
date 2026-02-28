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
    samples = (samples + 3) / 4 * 4;
    if (samples == 0) samples = 8;
    return samples;
}

static void li_sam2insn(li_sam_t *sam, li_insn_t *insn) {
    insn->arm = sam->opt.arm;
    insn->idle = 0;
    uint32_t tsamples = li_t2samples(sam->t_ns);
    uint32_t tsamples_nxt = li_t2samples(sam->t_ns + sam->opt.tplus_ns);
    insn->samples = sam->samples;
    insn->stride = (tsamples % sam->samples == 0) ? 
        (tsamples / sam->samples) : (tsamples / sam->samples + 1);
    insn->dsamples = (tsamples_nxt / insn->stride) - insn->samples;
}

static void li_idl2insn(li_idl_t *idl, li_insn_t *insn) {
    insn->arm = idl->opt.arm;
    insn->idle = 1;
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

        reg[0] = (insn->arm << 27) | (insn->idle << 26) | (insn->samples << 6) | 
                 (insn->dsamples >> 14); 
        reg[1] = (insn->dsamples << 18) | (insn->stride);

    }

    prog->seq_regs[LI_SEQ_REGS-2] = prog->repeat;
    prog->seq_regs[LI_SEQ_REGS-1] = 1;

}

int li_load_insns(int li_channel, li_program_t *li_program) {

    assert(0 <= li_channel && li_channel <= LAUNCH_UIO - LI_UIO_BASE - 1);

    char uio_path[32];
    snprintf(uio_path, sizeof(uio_path), "/dev/uio%d", LI_UIO_BASE + li_channel);

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
    *(li_base + LI_SEQ_REGS - 1) = 0;
    for (int i = 0; i < LI_SEQ_REGS; i++) {
        *(li_base + i) = li_program->seq_regs[i];
    }
    *(li_base + LI_SEQ_REGS + LI_CTRL_REGS - 1) = 0;
    for (int i = 0; i < LI_CTRL_REGS; i++) {
        if (li_program->ctrl_regs[i] != -1)
            *(li_base + LI_SEQ_REGS + i) = li_program->ctrl_regs[i];
    }

#if EXE
    __asm__ __volatile__("dsb oshst" ::: "memory");
#endif

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
