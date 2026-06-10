#include "common.h"
#include "ex.h"
#include <math.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <inttypes.h>
#include <sys/mman.h>

static uint32_t ex_t2samples(double t_ns) {
    uint32_t samples = (uint32_t)llround(t_ns / EX_NS_PER_SAMPLE);
    if (samples > EX_MAX_SAMPLES) samples = EX_MAX_SAMPLES;
    return samples;
}

static void ex_lvl2insn(ex_lvl_t *lvl, ex_insn_t *insn) {

    uint32_t v_code = (uint32_t)real2twos(EX_VMIN, EX_VMAX, EX_REAL_BITS, lvl->v, 0);

    insn->arm = lvl->opt.arm;
    insn->sticky_arm = 0;
    insn->real = v_code;
    insn->samples = ex_t2samples(lvl->t_ns);
    insn->dsamples = ex_t2samples(lvl->opt.tplus_ns);
    insn->marker = 0;
}

static void ex_idl2insn(ex_idl_t *idl, ex_insn_t *insn) {
    insn->arm = idl->opt.arm;
    insn->sticky_arm = 0;
    insn->real = 0;
    insn->samples = ex_t2samples(idl->t_ns);
    insn->dsamples = ex_t2samples(idl->opt.tplus_ns);
    insn->marker = 0;
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
        uint32_t *reg = &(prog->insn_mem[i * EX_REG_PER_INSN]);

        reg[0] = (insn->arm << 24) | (insn->sticky_arm << 23) |
                 ((insn->real & 0x3FFF) << 9) | (insn->samples >> 11);
        reg[1] = ((insn->samples & 0x7FF) << 21) | (insn->dsamples << 1) | insn->marker;

        prog->pc_mem[i] = i;
    }

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
    unsigned int n = ex_program->len;

    for (unsigned int i = 0; i < n; i++) {
        ex_base[BRAM_IST_ADDR] = i;
        for (unsigned int k = 0; k < EX_REG_PER_INSN; k++)
            ex_base[BRAM_IST_LO + k] = ex_program->insn_mem[i * EX_REG_PER_INSN + k];
        ex_base[BRAM_IST_STRB(EX_REG_PER_INSN)] = 0;
        ex_base[BRAM_IST_STRB(EX_REG_PER_INSN)] = 1;
    }

    for (unsigned int j = 0; j < n; j++) {
        ex_base[BRAM_PCST_ADDR] = j;
        ex_base[BRAM_PCST]      = ex_program->pc_mem[j];
        ex_base[BRAM_PCST_STRB] = 0;
        ex_base[BRAM_PCST_STRB] = 1;
    }

    ex_base[BRAM_ITERS(EX_REG_PER_INSN)] = ex_program->repeat;
    ex_base[BRAM_DEPTH(EX_REG_PER_INSN)] = n - 1;
    ex_base[BRAM_START(EX_REG_PER_INSN)] = 0;
    ex_base[BRAM_START(EX_REG_PER_INSN)] = 1;

#if EXE
    __asm__ __volatile__("dsb oshst" ::: "memory");
#endif

    munmap(ex_va, 0x1000);
    close(ex_fd);
    return 0;
}

static void ex_fmt_ns(double ns, char *buf, size_t sz) {
    if      (ns >= 1e9) snprintf(buf, sz, "%gs",  ns * 1e-9);
    else if (ns >= 1e6) snprintf(buf, sz, "%gms", ns * 1e-6);
    else if (ns >= 1e3) snprintf(buf, sz, "%gus", ns * 1e-3);
    else                snprintf(buf, sz, "%gns", ns);
}

static void ex_build_opts(uint32_t arm, double tplus_ns, char *buf, size_t sz) {
    if (!arm && tplus_ns == 0.0) { buf[0] = '\0'; return; }
    char tmp[64] = {0};
    if (arm) snprintf(tmp, sizeof(tmp), "arm");
    if (tplus_ns != 0.0) {
        char tstr[32];
        ex_fmt_ns(tplus_ns, tstr, sizeof(tstr));
        if (tmp[0]) strncat(tmp, " ", sizeof(tmp) - strlen(tmp) - 1);
        char piece[48];
        snprintf(piece, sizeof(piece), "t+%s", tstr);
        strncat(tmp, piece, sizeof(tmp) - strlen(tmp) - 1);
    }
    snprintf(buf, sz, " (%s)", tmp);
}

void disasm_ex(const uint32_t *r, char *buf, size_t sz) {
    uint32_t w0 = r[0], w1 = r[1];

    uint32_t arm        = (w0 >> 24) & 0x1;
    uint32_t sticky_arm = (w0 >> 23) & 0x1;
    uint32_t real_raw   = (w0 >>  9) & 0x3FFF;
    uint32_t samples_hi =  w0        & 0x1FF;
    uint32_t samples_lo = (w1 >> 21) & 0x7FF;
    uint32_t dsamples   = (w1 >>  1) & 0xFFFFF;
    uint32_t marker     =  w1        & 0x1;

    uint32_t samples = (samples_hi << 11) | samples_lo;

    double v        = twos2real(EX_VMIN, EX_VMAX, EX_REAL_BITS, real_raw);
    double t_ns     = samples  * EX_NS_PER_SAMPLE;
    double tplus_ns = dsamples * EX_NS_PER_SAMPLE;

    char t_str[32], opts[80];
    ex_fmt_ns(t_ns, t_str, sizeof(t_str));
    ex_build_opts(arm || sticky_arm, tplus_ns, opts, sizeof(opts));

    (void)marker;

    if (real_raw == 0 && !sticky_arm)
        snprintf(buf, sz, "    idl t=%s%s", t_str, opts);
    else {
        char v_str[32];
        snprintf(v_str, sizeof(v_str), "%.6g", v);
        snprintf(buf, sz, "    lvl v=%s t=%s%s", v_str, t_str, opts);
    }
}

int ex_inspect_channel(int ch) {
    assert(0 <= ch && ch <= EX_CHANNELS - 1);

    char uio_path[32];
    snprintf(uio_path, sizeof(uio_path), "/dev/uio%d", ex_uio_map[ch]);

    int fd = open(uio_path, O_RDWR);
    if (fd < 0) {
        fprintf(stderr, "open(\"%s\") failed: %s\n", uio_path, strerror(errno));
        return 1;
    }

    void *va = mmap(NULL, 0x1000, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (va == MAP_FAILED) {
        fprintf(stderr, "mmap() %s failed: %s\n", uio_path, strerror(errno));
        close(fd);
        return 1;
    }

    volatile uint32_t *base = (volatile uint32_t *)va;

    uint32_t repeat = base[BRAM_ITERS(EX_REG_PER_INSN)];
    uint32_t depth  = base[BRAM_DEPTH(EX_REG_PER_INSN)] + 1;

    printf(".program ex%d\n", ch);
    printf(".repeat %"PRIu32"\n", repeat);

    char buf[256];
    for (uint32_t j = 0; j < depth; j++) {
        base[BRAM_PCST_ADDR] = j;
        uint32_t pc = base[BRAM_PCST];

        base[BRAM_IST_ADDR] = pc;
        uint32_t r[EX_REG_PER_INSN];
        for (unsigned k = 0; k < EX_REG_PER_INSN; k++)
            r[k] = base[BRAM_IST_LO + k];

        disasm_ex(r, buf, sizeof(buf));
        printf("%s\n", buf);
    }

    munmap(va, 0x1000);
    close(fd);
    return 0;
}
