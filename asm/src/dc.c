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
#include <inttypes.h>
#include <sys/mman.h>


static uint32_t dc_t2cycles(uint32_t t_ns) {
    if (t_ns < NS_PER_CYCLE) return 0;
    const uint64_t max_cycles = (1ull << DC_CYCLE_BITS) - 1ull;
    uint64_t cycles = ((uint64_t)t_ns + (NS_PER_CYCLE/2)) / (uint64_t)NS_PER_CYCLE - 1;
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
    insn->sticky_arm = swp->opt.sticky_arm;
    insn->idle = 0;
    insn->marker = swp->opt.marker;

}

static void dc_lvl2insn(dc_lvl_t *lvl, dc_insn_t *insn) {

    uint32_t v_code = (uint32_t)real2twos(VMIN, VMAX, DC_DAC_BITS, lvl->v, 0);

    uint32_t din = (1u << 20) | (v_code & ((1u << 20) - 1u));

    insn->iters = 0;
    insn->spi_din = din;
    insn->dspi_din = lvl->opt.has_vplus ? lvl->opt.vplus : 0;
    insn->spi_rd = lvl->opt.rd;
    insn->strb_ldac = 1;
    insn->hold_cycles = dc_t2cycles(lvl->t_ns);
    insn->modify = lvl->opt.has_vplus;
    insn->arm = lvl->opt.arm;
    insn->sticky_arm = lvl->opt.sticky_arm;
    insn->idle = 0;
    insn->marker = lvl->opt.marker;

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
    insn->sticky_arm = set->opt.sticky_arm;
    insn->idle = 0;
    insn->marker = set->opt.marker;

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
    insn->sticky_arm = get->opt.sticky_arm;
    insn->idle = 0;
    insn->marker = get->opt.marker;

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
    insn->sticky_arm = nop->opt.sticky_arm;
    insn->idle = 0;
    insn->marker = nop->opt.marker;

}

static void dc_idl2insn(dc_idl_t *idl, dc_insn_t *insn) {

    insn->iters = 0;
    insn->spi_din = 0;
    insn->dspi_din = idl->opt.has_vplus ? idl->opt.vplus / NS_PER_CYCLE : 0;
    insn->spi_rd = 0;
    insn->strb_ldac = 0;
    insn->hold_cycles = dc_t2cycles(idl->t_ns);
    insn->modify = idl->opt.has_vplus;
    insn->arm = idl->opt.arm;
    insn->sticky_arm = idl->opt.sticky_arm;
    insn->idle = 1;
    insn->marker = idl->opt.marker;

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
    insn->sticky_arm = ful->opt.sticky_arm;
    insn->idle = 1;
    insn->marker = ful->opt.marker;

}

static int dc_parse_opt(char *paren, dc_opt_t *opt) {

    opt->arm = 0;
    opt->rd = 0;
    opt->vplus = 0;
    opt->ldc = 0;
    opt->sticky_arm = 0;
    opt->marker = 0;

    char tmp[256];
    snprintf(tmp, sizeof(tmp), "%s", paren);

    char *save = NULL;

    for (char *tok = strtok_r(tmp, " \t\r\n", &save); tok != NULL;
         tok = strtok_r(NULL, " \t\r\n", &save)) {

        if (strcmp(tok, "arm") == 0) {

            opt->arm = 1;

        } else if (strcmp(tok, "sticky_arm") == 0) {

            opt->sticky_arm = 1;

        } else if (strcmp(tok, "marker") == 0) {

            opt->marker = 1;

        } else if (strcmp(tok, "rd") == 0) {

            opt->rd = 1;

        } else if (strcmp(tok, "ldc") == 0) {

            opt->ldc = 1;

        } else if (strncmp(tok, "v+", 2) == 0) {

            char *endp = NULL;
            double v = strtod(tok + 2, &endp);

            if (endp == tok + 2 || *endp != '\0') 
                return -1;

            uint32_t v_code = (uint32_t)real2twos(VMIN, VMAX, DC_DAC_BITS, v, 0);
            opt->has_vplus = 1;
            opt->vplus = v_code;

        } else if (strncmp(tok, "t+", 2) == 0) {

            if (parse_time(tok + 2, &opt->vplus) != 0)
                return -1;

            opt->has_vplus = 1;

        } else {
            // unknown flag/token inside parens
            return -1;
        }

    }

    return 0;
}

static int dc_parse_swp(char *line, dc_swp_t *swp) {

    swp->opt.arm = 0;
    swp->opt.sticky_arm = 0;
    swp->opt.marker = 0;
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
    lvl->opt.sticky_arm = 0;
    lvl->opt.marker = 0;
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
    set->opt.sticky_arm = 0;
    set->opt.marker = 0;
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
    get->opt.sticky_arm = 0;
    get->opt.marker = 0;
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
    nop->opt.sticky_arm = 0;
    nop->opt.marker = 0;
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

static int dc_parse_idl(char *line, dc_idl_t *idl) {

    idl->opt.arm = 0;
    idl->opt.sticky_arm = 0;
    idl->opt.marker = 0;
    idl->opt.rd = 0;
    idl->opt.has_vplus = 0;
    idl->opt.vplus = 0;
    idl->opt.ldc = 0;

    char dt_tok[32] = {0};
    char paren[256] = {0};

    int got = sscanf(line, " idl t=%31s ( %255[^)] )", dt_tok, paren);

    if (got < 1) return -1;
    if (got == 1) paren[0] = '\0';

    if (parse_time(dt_tok, &(idl->t_ns)) != 0) return -1;

    assert(idl->t_ns <= DC_MAX_HOLD_NS);

    if (paren[0] != '\0') {
        if (dc_parse_opt(paren, &(idl->opt)) != 0) return -1;
    }

    return 0;

}

static int dc_parse_ful(char *line, dc_ful_t *ful) {

    ful->opt.arm = 0;
    ful->opt.sticky_arm = 0;
    ful->opt.marker = 0;
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

    } else if (strcmp(op, "idl") == 0) {

        dc_idl_t idl;
        dc_parse_idl(line, &idl);
        dc_idl2insn(&idl, insn);

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
        uint32_t *reg = &(prog->insn_mem[i * DC_REG_PER_INSN]);

        reg[0] = (insn->iters << 17) | (insn->spi_din >> 7);
        reg[1] = ((insn->spi_din & 0x7f) << 25) | (insn->dspi_din << 5) |
                 (insn->spi_rd << 4) | (insn->strb_ldac << 3) |
                 (insn->hold_cycles >> 27);
        reg[2] = ((insn->hold_cycles & 0x7FFFFFFu) << 5) | (insn->modify << 4) |
                 (insn->arm << 3) | (insn->sticky_arm << 2) |
                 (insn->idle << 1) | insn->marker;

        prog->pc_mem[i] = i;

    }

}

int dc_store_insns(int dc_channel, dc_program_t *dc_program) {

    assert(0 <= dc_channel && dc_channel <= DC_CHANNELS - 1);

    char uio_path[32];
    snprintf(uio_path, sizeof(uio_path), "/dev/uio%d", dc_uio_map[dc_channel]);

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
    unsigned int n = dc_program->len;

    // Write ctrl regs from ctrl struct; last reg is the write strobe
    if (dc_program->ctrl.dvsr != -1 || dc_program->ctrl.delay_cycles != -1 ||
        dc_program->ctrl.cs_up_cycles != -1 || dc_program->ctrl.ldac_cycles != -1) {
        *(dc_base + DC_BRAM_SEQ_REGS + DC_CTRL_REGS - 1) = 0;
        if (dc_program->ctrl.dvsr         != -1) *(dc_base + DC_BRAM_SEQ_REGS + 0) = (uint32_t)dc_program->ctrl.dvsr;
        if (dc_program->ctrl.delay_cycles != -1) *(dc_base + DC_BRAM_SEQ_REGS + 1) = (uint32_t)dc_program->ctrl.delay_cycles;
        if (dc_program->ctrl.cs_up_cycles != -1) *(dc_base + DC_BRAM_SEQ_REGS + 2) = (uint32_t)dc_program->ctrl.cs_up_cycles;
        if (dc_program->ctrl.ldac_cycles  != -1) *(dc_base + DC_BRAM_SEQ_REGS + 3) = (uint32_t)dc_program->ctrl.ldac_cycles;
        *(dc_base + DC_BRAM_SEQ_REGS + DC_CTRL_REGS - 1) = 1;
    }

    // Write IMEM
    for (unsigned int i = 0; i < n; i++) {
        dc_base[BRAM_IST_ADDR] = i;
        for (unsigned int k = 0; k < DC_REG_PER_INSN; k++)
            dc_base[BRAM_IST_LO + k] = dc_program->insn_mem[i * DC_REG_PER_INSN + k];
        dc_base[BRAM_IST_STRB(DC_REG_PER_INSN)] = 0;
        dc_base[BRAM_IST_STRB(DC_REG_PER_INSN)] = 1;
    }

    // Write PCMEM
    for (unsigned int j = 0; j < n; j++) {
        dc_base[BRAM_PCST_ADDR] = j;
        dc_base[BRAM_PCST]      = dc_program->pc_mem[j];
        dc_base[BRAM_PCST_STRB] = 0;
        dc_base[BRAM_PCST_STRB] = 1;
    }

    dc_base[BRAM_ITERS(DC_REG_PER_INSN)] = dc_program->repeat;
    dc_base[BRAM_DEPTH(DC_REG_PER_INSN)] = n - 1;
    dc_base[BRAM_START(DC_REG_PER_INSN)] = 0;
    dc_base[BRAM_START(DC_REG_PER_INSN)] = 1;

#if EXE
    __asm__ __volatile__("dsb oshst" ::: "memory");
#endif

    munmap(dc_va, 0x1000);
    close(dc_fd);
    return 0;

}

// ---- disassembler ----

static void fmt_ns(double ns, char *buf, size_t sz) {
    if      (ns >= 1e9) snprintf(buf, sz, "%gs",  ns * 1e-9);
    else if (ns >= 1e6) snprintf(buf, sz, "%gms", ns * 1e-6);
    else if (ns >= 1e3) snprintf(buf, sz, "%gus", ns * 1e-3);
    else                snprintf(buf, sz, "%gns", ns);
}

static void build_opts(char *buf, size_t sz,
                       int arm, int sticky_arm, int marker, const char *extra) {
    const char *flags[3];
    int nf = 0;
    if (arm)        flags[nf++] = "arm";
    if (sticky_arm) flags[nf++] = "sticky_arm";
    if (marker)     flags[nf++] = "marker";
    if (nf == 0 && (!extra || !extra[0])) { buf[0] = '\0'; return; }

    snprintf(buf, sz, " (");
    for (int i = 0; i < nf; i++) {
        strncat(buf, flags[i], sz - strlen(buf) - 1);
        if (i < nf - 1 || (extra && extra[0]))
            strncat(buf, " ", sz - strlen(buf) - 1);
    }
    if (extra && extra[0])
        strncat(buf, extra, sz - strlen(buf) - 1);
    strncat(buf, ")", sz - strlen(buf) - 1);
}

static const char *dc_reg_name(uint32_t r) {
    switch (r & 0x7u) {
        case 1: return "dr";
        case 2: return "cr";
        case 3: return "clr";
        case 4: return "scr";
        default: return "??";
    }
}

void disasm_dc(const uint32_t *r, char *buf, size_t sz) {
    uint32_t iters       = r[0] >> 17;
    uint32_t spi_din     = ((r[0] & 0x1FFFFu) << 7) | (r[1] >> 25);
    uint32_t dspi_din    = (r[1] >> 5) & 0xFFFFFu;
    uint32_t spi_rd      = (r[1] >> 4) & 1u;
    uint32_t strb_ldac   = (r[1] >> 3) & 1u;
    uint32_t hold_cycles = ((r[1] & 0x7u) << 27) | (r[2] >> 5);
    uint32_t modify      = (r[2] >> 4) & 1u;
    uint32_t arm         = (r[2] >> 3) & 1u;
    uint32_t sticky_arm  = (r[2] >> 2) & 1u;
    uint32_t idle        = (r[2] >> 1) & 1u;
    uint32_t marker      = r[2] & 1u;

    /* sign-extend dspi_din as 20-bit two's complement */
    int32_t dspi_signed = (dspi_din & (1u << 19))
                          ? (int32_t)(dspi_din | 0xFFF00000u) : (int32_t)dspi_din;

    char tbuf[32], extra[48], opts[96];
    fmt_ns((double)(hold_cycles + 1u) * NS_PER_CYCLE, tbuf, sizeof(tbuf));

    if (idle) {
        extra[0] = '\0';
        if (modify) {
            char dtbuf[32];
            fmt_ns((double)dspi_signed * NS_PER_CYCLE, dtbuf, sizeof(dtbuf));
            snprintf(extra, sizeof(extra), "t+%s", dtbuf);
        }
        build_opts(opts, sizeof(opts), (int)arm, (int)sticky_arm, (int)marker, extra);
        snprintf(buf, sz, "%s t=%s%s",
                 (strb_ldac || spi_rd) ? "ful" : "idl", tbuf, opts);

    } else if (iters > 0 && strb_ldac) {
        /* sign-extend 20-bit DAC codes so twos2real's (int32_t)k cast is correct */
        uint32_t raw1 = spi_din & 0xFFFFFu;
        uint32_t se1  = (raw1 & (1u<<19)) ? (raw1 | 0xFFF00000u) : raw1;
        int64_t  v2k  = (int64_t)(int32_t)se1 + (int64_t)iters * (int64_t)dspi_signed;
        uint32_t raw2 = (uint32_t)(v2k & 0xFFFFFu);
        uint32_t se2  = (raw2 & (1u<<19)) ? (raw2 | 0xFFF00000u) : raw2;
        /* round to 0.1mV to suppress two's-complement asymmetry artifacts; clear -0 */
        double v1 = round((double)twos2real(VMIN, VMAX, DC_DAC_BITS, se1) * 1e4) / 1e4;
        double v2 = round((double)twos2real(VMIN, VMAX, DC_DAC_BITS, se2) * 1e4) / 1e4;
        if (v1 == 0.0) v1 = 0.0;
        if (v2 == 0.0) v2 = 0.0;
        build_opts(opts, sizeof(opts), (int)arm, (int)sticky_arm, (int)marker, "");
        snprintf(buf, sz, "swp v1=%g v2=%g n=%u dt=%s%s",
                 v1, v2, iters + 1u, tbuf, opts);

    } else if (strb_ldac && !((spi_din >> 23) & 1u)) {
        uint32_t raw = spi_din & 0xFFFFFu;
        uint32_t se  = (raw & (1u<<19)) ? (raw | 0xFFF00000u) : raw;
        double v = round((double)twos2real(VMIN, VMAX, DC_DAC_BITS, se) * 1e4) / 1e4;
        if (v == 0.0) v = 0.0;
        extra[0] = '\0';
        if (modify) {
            uint32_t dse = (uint32_t)dspi_signed;
            double vd = round((double)twos2real(VMIN, VMAX, DC_DAC_BITS, dse) * 1e4) / 1e4;
            snprintf(extra, sizeof(extra), "v+%g", vd);
        }
        build_opts(opts, sizeof(opts), (int)arm, (int)sticky_arm, (int)marker, extra);
        snprintf(buf, sz, "lvl v=%g t=%s%s", v, tbuf, opts);

    } else if ((spi_din >> 23) & 1u) {
        build_opts(opts, sizeof(opts), (int)arm, (int)sticky_arm, (int)marker, "");
        snprintf(buf, sz, "get %s%s", dc_reg_name((spi_din >> 20) & 0x7u), opts);

    } else if (spi_din != 0) {
        uint32_t ri  = (spi_din >> 20) & 0x7u;
        uint32_t din = spi_din & 0xFFFFFu;
        build_opts(opts, sizeof(opts), (int)arm, (int)sticky_arm, (int)marker, "");
        snprintf(buf, sz, "set %s 0x%x%s", dc_reg_name(ri), din, opts);

    } else {
        build_opts(opts, sizeof(opts), (int)arm, (int)sticky_arm, (int)marker, "");
        snprintf(buf, sz, "nop%s", opts);
    }
}

int dc_inspect_channel(int ch) {

    if (ch < 0 || ch >= DC_CHANNELS) {
        fprintf(stderr, "dc channel must be 0..%d\n", DC_CHANNELS - 1);
        return 1;
    }

    char path[32];
    snprintf(path, sizeof(path), "/dev/uio%d", dc_uio_map[ch]);

    int fd = open(path, O_RDWR);
    if (fd < 0) { fprintf(stderr, "open(%s): %s\n", path, strerror(errno)); return 1; }

    void *va = mmap(NULL, 0x1000, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (va == MAP_FAILED) {
        fprintf(stderr, "mmap(%s): %s\n", path, strerror(errno));
        close(fd);
        return 1;
    }

    volatile uint32_t *base   = (volatile uint32_t *)va;
    int                sb     = BRAM_SEQ_TOTAL(DC_REG_PER_INSN) + DC_CTRL_REGS;
    volatile uint32_t *status = base + sb;

    uint32_t depth  = base[BRAM_DEPTH(DC_REG_PER_INSN)];
    uint32_t nsteps = depth + 1;
    if (nsteps > (uint32_t)DC_PC_MEM_DEPTH) nsteps = DC_PC_MEM_DEPTH;

    uint32_t flags = status[DC_REG_PER_INSN + 3];
    uint32_t iters = status[DC_REG_PER_INSN + 1];

    printf("dc%d:\n", ch);
    printf("  depth:  %u (%u steps)\n", depth, nsteps);
    printf("  iters:  %u\n", iters);
    printf("  armed:  %u\n", (flags >> 1) & 1u);
    printf("  empty:  %u\n",  flags & 1u);

    uint32_t *pc_seq     = malloc(nsteps * sizeof(uint32_t));
    uint32_t *insn_cache = calloc((size_t)DC_DEPTH * DC_REG_PER_INSN, sizeof(uint32_t));
    uint8_t  *fetched    = calloc(DC_DEPTH, 1);
    int       ret        = 0;

    if (!pc_seq || !insn_cache || !fetched) {
        fprintf(stderr, "malloc failed\n");
        ret = 1;
        goto done;
    }

    for (uint32_t addr = 0; addr < nsteps; addr++) {
        base[BRAM_PCST_ADDR]             = addr;
        base[BRAM_PCLD_STRB(DC_REG_PER_INSN)] = 0;
        base[BRAM_PCLD_STRB(DC_REG_PER_INSN)] = 1;
        pc_seq[addr] = (uint32_t)status[DC_REG_PER_INSN];
    }

    for (uint32_t addr = 0; addr < nsteps; addr++) {
        uint32_t pc = pc_seq[addr] & (DC_DEPTH - 1);
        if (!fetched[pc]) {
            base[BRAM_IST_ADDR]              = pc;
            base[BRAM_ILD_STRB(DC_REG_PER_INSN)] = 0;
            base[BRAM_ILD_STRB(DC_REG_PER_INSN)] = 1;
            for (int k = 0; k < DC_REG_PER_INSN; k++)
                insn_cache[pc * DC_REG_PER_INSN + k] = (uint32_t)status[k];
            fetched[pc] = 1;
        }
    }

    printf("  program:\n");
    for (uint32_t addr = 0; addr < nsteps; addr++) {
        uint32_t pc = pc_seq[addr] & (DC_DEPTH - 1);
        char abuf[128] = "???";
        disasm_dc(&insn_cache[pc * DC_REG_PER_INSN], abuf, sizeof(abuf));
        printf("    [%u] pc=%u: %s\n", addr, pc, abuf);
    }

    printf("  status:\n");
    for (int k = 0; k < DC_REG_PER_INSN; k++)
        printf("    insn_rd[%d]:   %08" PRIX32 "\n", k, (uint32_t)status[k]);
    printf("    pc_rd:        %08" PRIX32 "\n", (uint32_t)status[DC_REG_PER_INSN]);
    printf("    iters:        %08" PRIX32 "\n", (uint32_t)status[DC_REG_PER_INSN + 1]);
    printf("    pcmem_depth:  %08" PRIX32 "\n", (uint32_t)status[DC_REG_PER_INSN + 2]);
    printf("    flags:        %08" PRIX32 " (armed=%u empty=%u)\n",
           (uint32_t)status[DC_REG_PER_INSN + 3],
           (flags >> 1) & 1u, flags & 1u);

done:
    free(pc_seq);
    free(insn_cache);
    free(fetched);
    munmap(va, 0x1000);
    close(fd);
    return ret;

}

