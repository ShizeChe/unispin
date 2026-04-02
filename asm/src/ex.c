#include "common.h"
#include "dc.h"
#include "rf.h"
#include "li.h"
#include "ex.h"
#include <math.h>
#include <string.h>
#include <stdio.h>
#include <assert.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <sys/mman.h>

static uint32_t ex_t2samples(double t_ns) {
    uint32_t samples = (uint32_t)llround(t_ns / EX_NS_PER_SAMPLE);
    if (samples > EX_MAX_SAMPLES) samples = EX_MAX_SAMPLES;
    return samples;
}

static void ex_lvl2insn(ex_lvl_t *lvl, ex_insn_t *insn) {

    uint32_t v_code = (uint32_t)real2twos(EX_VMIN, EX_VMAX, EX_REAL_BITS, lvl->v, 0);

    insn->arm = lvl->opt.arm;
    insn->real = v_code;
    insn->samples = ex_t2samples(lvl->t_ns);
    insn->dsamples = ex_t2samples(lvl->opt.tplus_ns);
}

static void ex_idl2insn(ex_idl_t *idl, ex_insn_t *insn) {
    insn->arm = idl->opt.arm;
    insn->real = 0;
    insn->samples = ex_t2samples(idl->t_ns);
    insn->dsamples = ex_t2samples(idl->opt.tplus_ns);
}

static int ex_parse_opt(char *paren, ex_opt_t *opt) {

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

static int ex_parse_lvl(char *line, ex_lvl_t *lvl) {

    lvl->opt.arm = 0;
    lvl->opt.tplus_ns = 0;

    double v;

    char t_tok[32] = {0};
    char paren[256] = {0};

    int got = sscanf(line,
        " lvl v=%lf t=%31s ( %255[^)] )",
        &v, t_tok, paren);

    if (got < 2) return -1;
    if (got == 2) paren[0] = '\0';

    lvl->v = v;

    if (parse_time_double(t_tok, &(lvl->t_ns)) != 0) return -1;

    if (paren[0] != '\0') {
        if (ex_parse_opt(paren, &(lvl->opt)) != 0) return -1;
    }

    return 0;

}

static int ex_parse_idl(char *line, ex_idl_t *idl) {

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
        if (ex_parse_opt(paren, &(idl->opt)) != 0) return -1;
    }

    return 0;

}

int ex_parse_insn(char *line, ex_insn_t *insn) {

    char op[4] = {0};

    if (!sscanf(line, " %3s", op)) {
        return -1;
    }

    if (strcmp(op, "lvl") == 0) {

        ex_lvl_t lvl;
        ex_parse_lvl(line, &lvl);
        ex_lvl2insn(&lvl, insn);

    } else if (strcmp(op, "idl") == 0) {

        ex_idl_t idl;
        ex_parse_idl(line, &idl);
        ex_idl2insn(&idl, insn);

    } else {

        return -1;

    }

    return 0;

}

void ex_assemble(ex_program_t *prog) {

    for (unsigned int i = 0; i < prog->len; i++) {

        ex_insn_t *insn = &(prog->insns[i]);
        uint32_t *reg = &(prog->seq_regs[i * EX_REG_PER_INSN]);

        reg[0] = (insn->arm << 22) | ((insn->real & 0x3fff) << 8) | 
                 (insn->samples >> 12); 
        reg[1] = (insn->samples << 20) | (insn->dsamples);

    }

    prog->seq_regs[EX_SEQ_REGS-2] = prog->repeat;
    prog->seq_regs[EX_SEQ_REGS-1] = 1;

}

int ex_load_insns(int ex_channel, ex_program_t *ex_program) {

    assert(0 <= ex_channel && ex_channel <= EX_CHANNELS - 1);

    char uio_path[32];
    snprintf(uio_path, sizeof(uio_path), "/dev/uio%d", ex_uio_map[ex_channel]);

    int ex_fd = open(uio_path, O_RDWR);
    if (ex_fd < 0) {
        fprintf(stderr, "open(\"%s\") failed: %s\n", uio_path, strerror(errno));
        return 1;
    }

    void *ex_va = mmap(NULL, 0x1000, PROT_READ | PROT_WRITE, MAP_SHARED, ex_fd, 0);
    if (ex_va == MAP_FAILED) {
        fprintf(stderr, "mmap() %s failed: %s\n", uio_path, strerror(errno));
        close(ex_fd);
        return 1;
    }

    volatile uint32_t *ex_base = (volatile uint32_t *)((char *)ex_va);
    *(ex_base + EX_SEQ_REGS - 1) = 0;
    for (int i = 0; i < EX_SEQ_REGS; i++) {
        *(ex_base + i) = ex_program->seq_regs[i];
    }

#if EXE
    __asm__ __volatile__("dsb oshst" ::: "memory");
#endif

    munmap(ex_va, 0x1000);
    close(ex_fd);
    return 0;
}

int ex_read_regs(int ex_channel, uint32_t *seq_regs) {

    assert(0 <= ex_channel && ex_channel <= EX_CHANNELS - 1);

    char uio_path[32];
    snprintf(uio_path, sizeof(uio_path), "/dev/uio%d", ex_uio_map[ex_channel]);

    int ex_fd = open(uio_path, O_RDWR);
    if (ex_fd < 0) {
        fprintf(stderr, "open(\"%s\") failed: %s\n", uio_path, strerror(errno));
        return 1;
    }

    void *ex_va = mmap(NULL, 0x1000, PROT_READ | PROT_WRITE, MAP_SHARED, ex_fd, 0);
    if (ex_va == MAP_FAILED) {
        fprintf(stderr, "mmap() %s failed: %s\n", uio_path, strerror(errno));
        close(ex_fd);
        return 1;
    }

    volatile uint32_t *ex_base = (volatile uint32_t *)((char *)ex_va);

    for (int i = 0; i < EX_SEQ_REGS; i++) {
        seq_regs[i] = *(ex_base + i);
    }

    munmap(ex_va, 0x1000);
    close(ex_fd);
    return 0;

}

int ex_write_regs(int ex_channel, ex_program_t *ex_program, int uartfd) {

    uint8_t tx[6] = {0, 0, 0, 0, 0, 0};

    ssize_t n;

    int base = DC_SEQ_REGS + DC_CTRL_REGS + RF_SEQ_REGS + RF_CTRL_REGS + LI_SEQ_REGS + LI_CTRL_REGS;

    for (int i = 0; i < EX_SEQ_REGS - 1; i++) {

        tx[0] = (uint8_t)(base + i);
        tx[1] = (uint8_t)(ex_program->seq_regs[i] >> 24);
        tx[2] = (uint8_t)(ex_program->seq_regs[i] >> 16);
        tx[3] = (uint8_t)(ex_program->seq_regs[i] >> 8);
        tx[4] = (uint8_t)(ex_program->seq_regs[i]);

        n = write(uartfd, tx, sizeof(tx) - 1);
        if (n < 0) {
            perror("write error");
            return -1;
        }

    }

    tx[0] = (uint8_t)(base + EX_SEQ_REGS - 1);
    tx[1] = 0;
    tx[2] = 0;
    tx[3] = 0;
    tx[4] = 0;

    n = write(uartfd, tx, sizeof(tx) - 1);
    if (n < 0) {
        perror("write error");
        return -1;
    }

    tx[0] = (uint8_t)(base + EX_SEQ_REGS - 1);
    uint32_t chsel = 1U << ex_channel;
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
