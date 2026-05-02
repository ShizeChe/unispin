#include "common.h"
#include "rf.h"
#include "dc.h"
#include <math.h>
#include <string.h>
#include <stdio.h>
#include <assert.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <sys/mman.h>

static uint32_t rf_t2samples(double t_ns) {
    uint32_t samples = (uint32_t)llround(t_ns / RF_NS_PER_SAMPLE);
    if (samples > RF_MAX_SAMPLES) samples = RF_MAX_SAMPLES;
    return samples;
}

static void rf_chp2insn(rf_chp_t *chp, rf_insn_t *insn, long double fnco_hz) {

    long double k_deg = (chp->f2 - chp->f1) / ((long double)chp->t_ns) * 90e-9;
    long double b_deg = (chp->f1 - fnco_hz) * 180e-9 + k_deg;

    uint64_t k = real2twos(-180, 180 - ldexpl(1.0L, -RF_KBC_BITS), RF_KBC_BITS, k_deg, 1);
    uint64_t b = real2twos(-180, 180 - ldexpl(1.0L, -RF_KBC_BITS), RF_KBC_BITS, b_deg, 1);

    insn->arm = chp->opt.arm;
    insn->sticky_arm = 0;
    insn->kbc_mode = 1;
    insn->kbc1 = k;
    insn->kbc2 = b;
    insn->samples = rf_t2samples(chp->t_ns);
    insn->dsamples = rf_t2samples(chp->opt.tplus_ns);
    insn->marker = 0;

}

static void rf_ply2insn(rf_ply_t *ply, rf_insn_t *insn) {
    insn->arm = ply->opt.arm;
    insn->sticky_arm = 0;
    insn->kbc_mode = 2;
    insn->kbc1 = 0;
    insn->kbc2 = real2twos(-180, 180 - ldexpl(1.0L, -RF_KBC_BITS), RF_KBC_BITS, ply->phs, 1);
    insn->samples = rf_t2samples(ply->t_ns);
    insn->dsamples = rf_t2samples(ply->opt.tplus_ns);
    insn->marker = 0;
}

static void rf_idl2insn(rf_idl_t *idl, rf_insn_t *insn) {
    insn->arm = idl->opt.arm;
    insn->sticky_arm = 0;
    insn->kbc_mode = 3;
    insn->kbc1 = 0;
    insn->kbc2 = 0;
    insn->samples = rf_t2samples(idl->t_ns);
    insn->dsamples = rf_t2samples(idl->opt.tplus_ns);
    insn->marker = 0;
}

static void rf_ful2insn(rf_ful_t *ful, rf_insn_t *insn) {
    insn->arm = ful->opt.arm;
    insn->sticky_arm = 0;
    insn->kbc_mode = ful->kbc_mode;
    insn->kbc1 = ful->kbc1;
    insn->kbc2 = ful->kbc2;
    insn->samples = rf_t2samples(ful->t_ns);
    insn->dsamples = rf_t2samples(ful->opt.tplus_ns);
    insn->marker = 0;
}

static int rf_parse_opt(char *paren, rf_opt_t *opt) {

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

static int rf_parse_chp(char *line, rf_chp_t *chp) {

    chp->opt.arm = 0;
    chp->opt.tplus_ns = 0;

    char f1_tok[32] = {0};
    char f2_tok[32] = {0};
    char t_tok[32] = {0};
    char paren[256] = {0};

    int got = sscanf(line,
        " chp f1=%31s f2=%31s t=%31s ( %255[^)] )",
        f1_tok, f2_tok, t_tok, paren);

    if (got < 3) return -1;
    if (got == 3) paren[0] = '\0';

    if (parse_freq(f1_tok, &(chp->f1)) != 0) return -1;
    if (parse_freq(f2_tok, &(chp->f2)) != 0) return -1;
    if (parse_time_double(t_tok, &(chp->t_ns)) != 0) return -1;

    if (paren[0] != '\0') {
        if (rf_parse_opt(paren, &(chp->opt)) != 0) return -1;
    }

    return 0;

}

static int rf_parse_ply(char *line, rf_ply_t *ply) {

    ply->opt.arm = 0;
    ply->opt.tplus_ns = 0;

    double phs;

    char t_tok[32] = {0};
    char paren[256] = {0};

    int got = sscanf(line,
        " ply phs=%lf t=%31s ( %255[^)] )",
        &phs, t_tok, paren);

    if (got < 2) return -1;
    if (got == 2) paren[0] = '\0';

    ply->phs = phs;

    if (parse_time_double(t_tok, &(ply->t_ns)) != 0) return -1;

    if (paren[0] != '\0') {
        if (rf_parse_opt(paren, &(ply->opt)) != 0) return -1;
    }

    return 0;

}

static int rf_parse_idl(char *line, rf_idl_t *idl) {

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
        if (rf_parse_opt(paren, &(idl->opt)) != 0) return -1;
    }

    return 0;

}

static int rf_parse_ful(char *line, rf_ful_t *ful) {

    ful->opt.arm = 0;
    ful->opt.tplus_ns = 0;

    char kbc_mode[3] = {0};
    uint64_t kbc1 = 0;
    uint64_t kbc2 = 0;
    char t_tok[32] = {0};
    char paren[256] = {0};

    int got = sscanf(line, " ful %2s ", kbc_mode);

    if (got < 1) return -1;

    if (strcmp(kbc_mode, "kb") == 0) {

        ful->kbc_mode = 1;
        got = sscanf(line,
            " ful kb %lx %lx t=%31s ( %255[^)] )", 
            &kbc1, &kbc2, t_tok, paren);

        if (got < 3) return -1;
        if (got == 3) paren[0] = '\0';

    } else if (strcmp(kbc_mode, "bc") == 0) {

        ful->kbc_mode = 2;
        got = sscanf(line,
            " ful bc %lx %lx t=%31s ( %255[^)] )", 
            &kbc1, &kbc2, t_tok, paren);

        if (got < 3) return -1;
        if (got == 3) paren[0] = '\0';

    } else if (strcmp(kbc_mode, "id") == 0) {

        ful->kbc_mode = 3;
        got = sscanf(line,
            " ful id t=%31s ( %255[^)] )", t_tok, paren);

        if (got < 1) return -1;
        if (got == 1) paren[0] = '\0';

    } else {
        return -1;
    }

    ful->kbc1 = kbc1;
    ful->kbc2 = kbc2;

    if (parse_time_double(t_tok, &(ful->t_ns)) != 0) return -1;

    if (paren[0] != '\0') {
        if (rf_parse_opt(paren, &(ful->opt)) != 0) return -1;
    }

    return 0;

}

int rf_parse_insn(char *line, rf_insn_t *insn, long double fnco_hz) {

    char op[4] = {0};

    if (!sscanf(line, " %3s", op)) {
        return -1;
    }

    if (strcmp(op, "chp") == 0) {

        rf_chp_t chp;
        rf_parse_chp(line, &chp);
        rf_chp2insn(&chp, insn, fnco_hz);

    } else if (strcmp(op, "ply") == 0) {

        rf_ply_t ply;
        rf_parse_ply(line, &ply);
        rf_ply2insn(&ply, insn);

    } else if (strcmp(op, "idl") == 0) {

        rf_idl_t idl;
        rf_parse_idl(line, &idl);
        rf_idl2insn(&idl, insn);

    } else if (strcmp(op, "ful") == 0) {

        rf_ful_t ful;
        rf_parse_ful(line, &ful);
        rf_ful2insn(&ful, insn);

    } else {

        return -1;

    }

    return 0;

}

void rf_assemble(rf_program_t *prog) {

    for (unsigned int i = 0; i < prog->len; i++) {

        rf_insn_t *insn = &(prog->insns[i]);
        uint32_t *reg = &(prog->seq_regs[i * RF_REG_PER_INSN]);

        // Pack 117-bit rf_insn_t into 4 x 32-bit registers (MSB-first in concat)
        // insn[116:96] → reg[0][20:0], insn[95:64] → reg[1], insn[63:32] → reg[2],
        // insn[31:0] → reg[3]
        reg[0] = (insn->arm << 20) | (insn->sticky_arm << 19) |
                 (insn->kbc_mode << 17) | (uint32_t)(insn->kbc1 >> 19);
        reg[1] = (uint32_t)((insn->kbc1 & 0x7FFFF) << 13) | (uint32_t)(insn->kbc2 >> 23);
        reg[2] = (uint32_t)((insn->kbc2 & 0x7FFFFF) << 9) | (insn->samples >> 11);
        reg[3] = ((insn->samples & 0x7FF) << 21) | (insn->dsamples << 1) | insn->marker;

    }

    // Pack rf_ctrl_t: {w_default_I[27:14], w_default_Q[13:0]}
    prog->ctrl_regs[0] = (((uint32_t)prog->ctrl.default_I & 0x3fff) << 14) |
                         ((uint32_t)prog->ctrl.default_Q & 0x3fff);

    prog->ctrl_regs[RF_CTRL_REGS-1] = (prog->ctrl.default_I != -1) ||
        (prog->ctrl.default_Q != -1);

}

int rf_load_insns(int rf_channel, rf_program_t *rf_program) {

    assert(0 <= rf_channel && rf_channel <= RF_CHANNELS - 1);

    char uio_path[32];
    snprintf(uio_path, sizeof(uio_path), "/dev/uio%d", rf_uio_map[rf_channel]);

    int rf_fd = open(uio_path, O_RDWR);
    if (rf_fd < 0) {
        fprintf(stderr, "open(\"%s\") failed: %s\n", uio_path, strerror(errno));
        return 1;
    }

    void *rf_va = mmap(NULL, 0x1000, PROT_READ | PROT_WRITE, MAP_SHARED, rf_fd, 0);
    if (rf_va == MAP_FAILED) {
        fprintf(stderr, "mmap() %s failed: %s\n", uio_path, strerror(errno));
        close(rf_fd);
        return 1;
    }

    volatile uint32_t *rf_base = (volatile uint32_t *)((char *)rf_va);
    unsigned int n = rf_program->len;

    for (unsigned int i = 0; i < n; i++) {
        rf_base[BRAM_IST_ADDR] = i;
        for (unsigned int k = 0; k < RF_REG_PER_INSN; k++)
            rf_base[BRAM_IST_LO + k] = rf_program->seq_regs[i * RF_REG_PER_INSN + k];
        rf_base[BRAM_IST_STRB(RF_REG_PER_INSN)] = 0;
        rf_base[BRAM_IST_STRB(RF_REG_PER_INSN)] = 1;
    }

    for (unsigned int j = 0; j < n; j++) {
        rf_base[BRAM_PCST_ADDR] = j;
        rf_base[BRAM_PCST]      = j;
        rf_base[BRAM_PCST_STRB] = 0;
        rf_base[BRAM_PCST_STRB] = 1;
    }

    rf_base[BRAM_ITERS(RF_REG_PER_INSN)] = rf_program->repeat;
    rf_base[BRAM_DEPTH(RF_REG_PER_INSN)] = n - 1;
    rf_base[BRAM_START(RF_REG_PER_INSN)] = 0;
    rf_base[BRAM_START(RF_REG_PER_INSN)] = 1;

    *(rf_base + RF_BRAM_SEQ_REGS + RF_CTRL_REGS - 1) = 0;
    for (int i = 0; i < RF_CTRL_REGS; i++) {
        if (rf_program->ctrl_regs[i] != -1)
            *(rf_base + RF_BRAM_SEQ_REGS + i) = rf_program->ctrl_regs[i];
    }

#if EXE
    __asm__ __volatile__("dsb oshst" ::: "memory");
#endif

    munmap(rf_va, 0x1000);
    close(rf_fd);
    return 0;

}

int rf_read_regs(int rf_channel, uint32_t *seq_regs, uint32_t *ctrl_regs) {

    assert(0 <= rf_channel && rf_channel <= RF_CHANNELS - 1);

    char uio_path[32];
    snprintf(uio_path, sizeof(uio_path), "/dev/uio%d", rf_uio_map[rf_channel]);

    int rf_fd = open(uio_path, O_RDWR);
    if (rf_fd < 0) {
        fprintf(stderr, "open(\"%s\") failed: %s\n", uio_path, strerror(errno));
        return 1;
    }

    void *rf_va = mmap(NULL, 0x1000, PROT_READ | PROT_WRITE, MAP_SHARED, rf_fd, 0);
    if (rf_va == MAP_FAILED) {
        fprintf(stderr, "mmap() %s failed: %s\n", uio_path, strerror(errno));
        close(rf_fd);
        return 1;
    }

    volatile uint32_t *rf_base = (volatile uint32_t *)((char *)rf_va);

    for (int i = 0; i < RF_BRAM_SEQ_REGS; i++) {
        seq_regs[i] = *(rf_base + i);
    }
    for (int i = 0; i < RF_CTRL_REGS; i++) {
        ctrl_regs[i] = *(rf_base + RF_BRAM_SEQ_REGS + i);
    }

    munmap(rf_va, 0x1000);
    close(rf_fd);
    return 0;

}

int rf_write_regs(int rf_channel, rf_program_t *rf_program, int uartfd) {

    uint8_t tx[6] = {0, 0, 0, 0, 0, 0};

    ssize_t n;

    int base = DC_SEQ_REGS + DC_CTRL_REGS;

    for (int i = 0; i < RF_CTRL_REGS - 1; i++) {

        if (rf_program->ctrl_regs[i] != -1) {
            tx[0] = (uint8_t)(base + RF_SEQ_REGS + i);
            tx[1] = (uint8_t)(((uint32_t)rf_program->ctrl_regs[i]) >> 24);
            tx[2] = (uint8_t)(((uint32_t)rf_program->ctrl_regs[i]) >> 16);
            tx[3] = (uint8_t)(((uint32_t)rf_program->ctrl_regs[i]) >> 8);
            tx[4] = (uint8_t)(((uint32_t)rf_program->ctrl_regs[i]));
        }

        n = write(uartfd, tx, sizeof(tx) - 1);
        if (n < 0) {
            perror("write error");
            return -1;
        }

    }

    tx[0] = (uint8_t)(base + RF_SEQ_REGS + RF_CTRL_REGS - 1);
    tx[1] = 0;
    tx[2] = 0;
    tx[3] = 0;
    tx[4] = 0;

    n = write(uartfd, tx, sizeof(tx) - 1);
    if (n < 0) {
        perror("write error");
        return -1;
    }

    tx[0] = (uint8_t)(base + RF_SEQ_REGS + RF_CTRL_REGS - 1);
    uint32_t chsel = 1U << rf_channel;
    tx[1] = (uint8_t)(chsel >> 24);
    tx[2] = (uint8_t)(chsel >> 16);
    tx[3] = (uint8_t)(chsel >> 8);
    tx[4] = (uint8_t)(chsel);

    n = write(uartfd, tx, sizeof(tx) - 1);
    if (n < 0) {
        perror("write error");
        return -1;
    }

    for (int i = 0; i < RF_SEQ_REGS - 1; i++) {

        tx[0] = (uint8_t)(base + i);
        tx[1] = (uint8_t)(rf_program->seq_regs[i] >> 24);
        tx[2] = (uint8_t)(rf_program->seq_regs[i] >> 16);
        tx[3] = (uint8_t)(rf_program->seq_regs[i] >> 8);
        tx[4] = (uint8_t)(rf_program->seq_regs[i]);

        n = write(uartfd, tx, sizeof(tx) - 1);
        if (n < 0) {
            perror("write error");
            return -1;
        }

    }

    tx[0] = (uint8_t)(base + RF_SEQ_REGS - 1);
    tx[1] = 0;
    tx[2] = 0;
    tx[3] = 0;
    tx[4] = 0;

    n = write(uartfd, tx, sizeof(tx) - 1);
    if (n < 0) {
        perror("write error");
        return -1;
    }

    tx[0] = (uint8_t)(base + RF_SEQ_REGS - 1);
    chsel = 1U << rf_channel;
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
