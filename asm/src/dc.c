#include "common.h"
#include "dc.h"
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <assert.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <sys/mman.h>


static uint32_t dc_v2dac_code(double v) {
    const double span = (VMAX - VMIN);
    const double fullscale   = (double)((1u << DC_DAC_BITS) - 1u);
    if (span <= 0.0) return 0;

    double norm   = (v - VMIN) / span;   // ideal 0..1
    double scaled = norm * fullscale;           // ideal 0..(2^N-1)

    if (scaled < 0.0)       scaled = 0.0;
    if (scaled > fullscale) scaled = fullscale;
    return (uint32_t)llround(scaled);
}

static uint32_t dc_t2cycles(uint32_t t_ns) {
    const uint64_t max_cycles = (1ull << DC_CYCLE_BITS) - 1ull;
    uint64_t cycles = ( (uint64_t)t_ns + (NS_PER_CYCLE/2) ) / (uint64_t)NS_PER_CYCLE;
    if (cycles == 0) cycles = 1;
    if (cycles > max_cycles) cycles = max_cycles;
    return (uint32_t)cycles;
}

static void dc_swp2insn(dc_swp_t *swp, dc_insn_t *insn) {

    int64_t v1_code = (int64_t)real2twos(VMIN, VMAX, DC_DAC_BITS, swp->v1, 0);
    int64_t v2_code = (int64_t)real2twos(VMIN, VMAX, DC_DAC_BITS, swp->v2, 0);
    uint32_t cycles = dc_t2cycles(swp->dt_ns);

    uint32_t steps = swp->n - 1;
    int64_t dv = (v2_code - v1_code) / (int64_t)steps;

    uint32_t din = (1u << 20) | ((uint32_t)v1_code & ((1u << 20) - 1u));

    insn->iters = steps;
    insn->spi_din = din;
    insn->dspi_din = (uint32_t)dv;
    insn->spi_rd = swp->opt.rd;
    insn->strb_ldac = 1;
    insn->hold_cycles = cycles;
    insn->modify = 0;
    insn->arm = swp->opt.arm;

}

static void dc_lvl2insn(dc_lvl_t *lvl, dc_insn_t *insn) {

    uint32_t din = (1u << 20) | dc_v2dac_code(lvl->v);

    insn->iters = 0;
    insn->spi_din = din;
    insn->dspi_din = lvl->opt.has_vplus ? lvl->opt.vplus : 0;
    insn->spi_rd = lvl->opt.rd;
    insn->strb_ldac = 1;
    insn->hold_cycles = dc_t2cycles(lvl->t_ns);
    insn->modify = lvl->opt.has_vplus;
    insn->arm = lvl->opt.arm;

}

static void dc_set2insn(dc_set_t *set, dc_insn_t *insn) {

    uint32_t din = (set->r << 20) | set->din;

    insn->iters = 0;
    insn->spi_din = din;
    insn->dspi_din = set->opt.has_vplus ? set->opt.vplus : 0;
    insn->spi_rd = set->opt.rd;
    insn->strb_ldac = set->opt.ldc;
    insn->hold_cycles = 0;
    insn->modify = set->opt.has_vplus;
    insn->arm = set->opt.arm;

}

static void dc_get2insn(dc_get_t *get, dc_insn_t *insn) {

    uint32_t din = (1u << 23) | (get->r << 20);

    insn->iters = 0;
    insn->spi_din = din;
    insn->dspi_din = get->opt.has_vplus ? get->opt.vplus : 0;
    insn->spi_rd = get->opt.rd;
    insn->strb_ldac = get->opt.ldc;
    insn->hold_cycles = 0;
    insn->modify = get->opt.has_vplus;
    insn->arm = get->opt.arm;

}

static void dc_nop2insn(dc_nop_t *nop, dc_insn_t *insn) {

    insn->iters = 0;
    insn->spi_din = 0;
    insn->dspi_din = nop->opt.has_vplus ? nop->opt.vplus : 0;
    insn->spi_rd = nop->opt.rd;
    insn->strb_ldac = nop->opt.ldc;
    insn->hold_cycles = 0;
    insn->modify = nop->opt.has_vplus;
    insn->arm = nop->opt.arm;

}

static void dc_ful2insn(dc_ful_t *ful, dc_insn_t *insn) {

    insn->iters = 0;
    insn->spi_din = 0;
    insn->dspi_din = ful->opt.has_vplus ? ful->opt.vplus : 0;
    insn->spi_rd = ful->opt.rd;
    insn->strb_ldac = ful->opt.ldc;
    insn->hold_cycles = 0;
    insn->modify = ful->opt.has_vplus;
    insn->arm = ful->opt.arm;

}

static int dc_parse_opt(char *paren, dc_opt_t *opt) {

    opt->arm = 0;
    opt->rd = 0;
    opt->vplus = 0;
    opt->ldc = 0;

    char tmp[256];
    snprintf(tmp, sizeof(tmp), "%s", paren);

    char *save = NULL;

    for (char *tok = strtok_r(tmp, " \t\r\n", &save); tok != NULL;
         tok = strtok_r(NULL, " \t\r\n", &save)) {

        if (strcmp(tok, "arm") == 0) {

            opt->arm = 1;

        } else if (strcmp(tok, "rd") == 0) {

            opt->rd = 1;

        } else if (strcmp(tok, "ldc") == 0) {

            opt->ldc = 1;

        } else if (strncmp(tok, "v+", 2) == 0) {

            char *endp = NULL;
            double v = strtod(tok + 2, &endp);

            if (endp == tok + 2 || *endp != '\0') 
                return -1;

            opt->has_vplus = 1;
            opt->vplus = v;

        } else {
            // unknown flag/token inside parens
            return -1;
        }

    }

    return 0;
}

static int dc_parse_swp(char *line, dc_swp_t *swp) {

    swp->opt.arm = 0;
    swp->opt.rd = 0;
    swp->opt.has_vplus = 0;
    swp->opt.vplus = 0;
    swp->opt.ldc = 0;

    double v1, v2;
    uint32_t n;

    char dt_tok[32] = {0};
    char paren[256] = {0};

    int got = sscanf(line,
        " swp v1=%lf v2=%lf n=%u dt=%31s ( %255[^)] )",
        &v1, &v2, &n, dt_tok, paren);

    assert(VMIN <= v1 && v1 <= VMAX);
    assert(VMIN <= v2 && v2 <= VMAX);
    assert(1 < n && n <= DC_MAX_CORE_ITERS);

    if (got < 4) return -1;
    if (got == 4) paren[0] = '\0';

    swp->v1 = v1;
    swp->v2 = v2;
    swp->n  = n;

    if (parse_time(dt_tok, &(swp->dt_ns)) != 0) return -1;

    assert(swp->dt_ns <= DC_MAX_HOLD_NS);

    if (paren[0] != '\0') {
        if (dc_parse_opt(paren, &(swp->opt)) != 0) return -1;
    }

    return 0;

}

static int dc_parse_lvl(char *line, dc_lvl_t *lvl) {

    lvl->opt.arm = 0;
    lvl->opt.rd = 0;
    lvl->opt.has_vplus = 0;
    lvl->opt.vplus = 0;
    lvl->opt.ldc = 0;

    double v;

    char dt_tok[32] = {0};
    char paren[256] = {0};

    int got = sscanf(line,
        " lvl v=%lf t=%31s ( %255[^)] )",
        &v, dt_tok, paren);

    assert(VMIN <= v && v <= VMAX);

    if (got < 2) return -1; 
    if (got == 2) paren[0] = '\0';

    lvl->v = v;

    if (parse_time(dt_tok, &(lvl->t_ns)) != 0) return -1;

    assert(lvl->t_ns <= DC_MAX_HOLD_NS);

    if (paren[0] != '\0') {
        if (dc_parse_opt(paren, &(lvl->opt)) != 0) return -1;
    }

    return 0;

}

static int dc_parse_set(char *line, dc_set_t *set) {

    set->opt.arm = 0;
    set->opt.rd = 0;
    set->opt.has_vplus = 0;
    set->opt.vplus = 0;
    set->opt.ldc = 0;

    char r[4] = {0};
    uint32_t din;
    char paren[256] = {0};

    int got = sscanf(line, 
        " set %3s %x ( %255[^)] )", 
        r, &din, paren);

    if (got < 2) return -1;
    if (got == 2) paren[0] = '\0';

    assert(din <= 0xFFFFFu);

    if (strcmp(r, "dr") == 0) {
        set->r = 1;
    } else if (strcmp(r, "cr") == 0) {
        set->r = 2;
    } else if (strcmp(r, "clr") == 0) {
        set->r = 3;
    } else if (strcmp(r, "scr") == 0) {
        set->r = 4;
    } else {
        // unknown dac register
        return -1;
    }

    set->din = din;

    if (paren[0] != '\0') {
        if (dc_parse_opt(paren, &(set->opt)) != 0) return -1;
    }

    return 0;

}

static int dc_parse_get(char *line, dc_get_t *get) {

    get->opt.arm = 0;
    get->opt.rd = 0;
    get->opt.has_vplus = 0;
    get->opt.vplus = 0;
    get->opt.ldc = 0;

    char r[4] = {0};
    char paren[256] = {0};

    int got = sscanf(line, 
        " set %3s ( %255[^)] )", 
        r, paren);

    if (got < 1) return -1;
    if (got == 1) paren[0] = '\0';

    if (strcmp(r, "dr") == 0) {
        get->r = 1;
    } else if (strcmp(r, "cr") == 0) {
        get->r = 2;
    } else if (strcmp(r, "clr") == 0) {
        get->r = 3;
    } else if (strcmp(r, "scr") == 0) {
        get->r = 4;
    } else {
        // unknown dac register
        return -1;
    }

    if (paren[0] != '\0') {
        if (dc_parse_opt(paren, &(get->opt)) != 0) return -1;
    }

    return 0;

}

static int dc_parse_nop(char *line, dc_nop_t *nop) {

    nop->opt.arm = 0;
    nop->opt.rd = 0;
    nop->opt.has_vplus = 0;
    nop->opt.vplus = 0;
    nop->opt.ldc = 0;

    char paren[256] = {0};

    int got = sscanf(line, " nop ( %255[^)] )", paren);

    if (got == 0) paren[0] = '\0';

    if (paren[0] != '\0') {
        if (dc_parse_opt(paren, &(nop->opt)) != 0) return -1;
    }

    return 0;

}

static int dc_parse_ful(char *line, dc_ful_t *ful) {

    ful->opt.arm = 0;
    ful->opt.rd = 0;
    ful->opt.has_vplus = 0;
    ful->opt.vplus = 0;
    ful->opt.ldc = 0;

    uint32_t its, din, cyc;

    char paren[256] = {0};

    int got = sscanf(line,
        " ful its=%u din=%x cyc=%u ( %255[^)] )",
        &its, &din, &cyc, paren);

    if (got < 3) return -1;
    if (got == 3) paren[0] = '\0';

    assert(its <= DC_MAX_CORE_ITERS);
    assert(din <= 0xFFFFFu);
    assert(cyc <= DC_MAX_HOLD_CYCLES);

    ful->its = its;
    ful->din = din;
    ful->cyc = cyc;

    if (paren[0] != '\0') {
        if (dc_parse_opt(paren, &(ful->opt)) != 0) return -1;
    }

    return 0;

}

int dc_parse_insn(char *line, dc_insn_t *insn) {

    char op[4] = {0};

    if (!sscanf(line, " %3s", op)) {
        return -1;
    }

    if (strcmp(op, "swp") == 0) {

        dc_swp_t swp;
        dc_parse_swp(line, &swp);
        dc_swp2insn(&swp, insn);

    } else if (strcmp(op, "lvl") == 0) {

        dc_lvl_t lvl;
        dc_parse_lvl(line, &lvl);
        dc_lvl2insn(&lvl, insn);

    } else if (strcmp(op, "set") == 0) {

        dc_set_t set;
        dc_parse_set(line, &set);
        dc_set2insn(&set, insn);

    } else if (strcmp(op, "get") == 0) {

        dc_get_t get;
        dc_parse_get(line, &get);
        dc_get2insn(&get, insn);

    } else if (strcmp(op, "nop") == 0) {

        dc_nop_t nop;
        dc_parse_nop(line, &nop);
        dc_nop2insn(&nop, insn);

    } else if (strcmp(op, "ful") == 0) {

        dc_ful_t ful;
        dc_parse_ful(line, &ful);
        dc_ful2insn(&ful, insn);

    } else {

        return -1;

    }

    return 0;

}

void dc_assemble(dc_program_t *prog) {

    for (unsigned int i = 0; i < prog->len; i++) {

        dc_insn_t *insn = &(prog->insns[i]);
        uint32_t *reg = &(prog->seq_regs[i * DC_REG_PER_INSN]);

        reg[0] = (insn->iters << 14) | (insn->spi_din >> 10);
        reg[1] = (insn->spi_din << 22) | (insn->dspi_din << 2) | 
                 (insn->spi_rd << 1) | insn->strb_ldac;
        reg[2] = (insn->hold_cycles << 2) | (insn->modify << 1) | 
                 (insn->arm);

    }

    prog->seq_regs[DC_SEQ_REGS-2] = prog->repeat;
    prog->seq_regs[DC_SEQ_REGS-1] = 1;

    prog->ctrl_regs[0] = prog->ctrl.dvsr;
    prog->ctrl_regs[1] = prog->ctrl.cs_up_cycles;
    prog->ctrl_regs[2] = prog->ctrl.ldac_cycles;

    prog->ctrl_regs[DC_CTRL_REGS-1] = (prog->ctrl_regs[0] != -1) ||
        (prog->ctrl_regs[1] != -1) || (prog->ctrl_regs[2] != -1);

}

int dc_load_insns(int dc_channel, dc_program_t *dc_program) {

    assert(0 <= dc_channel && dc_channel <= RF_UIO_BASE - DC_UIO_BASE - 1);

    char uio_path[32];
    snprintf(uio_path, sizeof(uio_path), "/dev/uio%d", DC_UIO_BASE + dc_channel);

    int dc_fd = open(uio_path, O_RDWR);
    if (dc_fd < 0) {
        fprintf(stderr, "open(\"%s\") failed: %s\n", uio_path, strerror(errno));
        return 1;
    }

    void *dc_va = mmap(NULL, 0x1000, PROT_READ | PROT_WRITE, MAP_SHARED, dc_fd, 0);
    if (dc_va == MAP_FAILED) {
        fprintf(stderr, "mmap() %s failed: %s\n", uio_path, strerror(errno));
        close(dc_fd);
        return 1;
    }

    volatile uint32_t *dc_base = (volatile uint32_t *)((char *)dc_va);
    *(dc_base + DC_SEQ_REGS - 1) = 0;
    for (int i = 0; i < DC_SEQ_REGS; i++) {
        *(dc_base + i) = dc_program->seq_regs[i];
    }
    *(dc_base + DC_SEQ_REGS + DC_CTRL_REGS - 1) = 0;
    for (int i = 0; i < DC_CTRL_REGS; i++) {
        if (dc_program->ctrl_regs[i] != -1)
            *(dc_base + DC_SEQ_REGS + i) = dc_program->ctrl_regs[i];
    }

#if EXE
    __asm__ __volatile__("dsb oshst" ::: "memory");
#endif

    return 0;
}

