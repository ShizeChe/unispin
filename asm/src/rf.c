#include "common.h"
#include "rf.h"
#include "dc.h"
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
        uint32_t *reg = &(prog->insn_mem[i * RF_REG_PER_INSN]);

        reg[0] = (insn->arm << 20) | (insn->sticky_arm << 19) |
                 (insn->kbc_mode << 17) | (uint32_t)(insn->kbc1 >> 19);
        reg[1] = (uint32_t)((insn->kbc1 & 0x7FFFF) << 13) | (uint32_t)(insn->kbc2 >> 23);
        reg[2] = (uint32_t)((insn->kbc2 & 0x7FFFFF) << 9) | (insn->samples >> 11);
        reg[3] = ((insn->samples & 0x7FF) << 21) | (insn->dsamples << 1) | insn->marker;

        prog->pc_mem[i] = i;

    }

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

    *(rf_base + RF_BRAM_SEQ_REGS + RF_CTRL_REGS - 1) = 0;
    if (rf_program->ctrl.default_I != -1) *(rf_base + RF_BRAM_SEQ_REGS + 0) = (uint32_t)(rf_program->ctrl.default_I & 0x3fff);
    if (rf_program->ctrl.default_Q != -1) *(rf_base + RF_BRAM_SEQ_REGS + 1) = (uint32_t)(rf_program->ctrl.default_Q & 0x3fff);
    *(rf_base + RF_BRAM_SEQ_REGS + RF_CTRL_REGS - 1) = 1;

    for (unsigned int i = 0; i < n; i++) {
        rf_base[BRAM_IST_ADDR] = i;
        for (unsigned int k = 0; k < RF_REG_PER_INSN; k++)
            rf_base[BRAM_IST_LO + k] = rf_program->insn_mem[i * RF_REG_PER_INSN + k];
        rf_base[BRAM_IST_STRB(RF_REG_PER_INSN)] = 0;
        rf_base[BRAM_IST_STRB(RF_REG_PER_INSN)] = 1;
    }

    for (unsigned int j = 0; j < n; j++) {
        rf_base[BRAM_PCST_ADDR] = j;
        rf_base[BRAM_PCST]      = rf_program->pc_mem[j];
        rf_base[BRAM_PCST_STRB] = 0;
        rf_base[BRAM_PCST_STRB] = 1;
    }

    rf_base[BRAM_ITERS(RF_REG_PER_INSN)] = rf_program->repeat;
    rf_base[BRAM_DEPTH(RF_REG_PER_INSN)] = n - 1;
    rf_base[BRAM_START(RF_REG_PER_INSN)] = 0;
    rf_base[BRAM_START(RF_REG_PER_INSN)] = 1;

#if EXE
    __asm__ __volatile__("dsb oshst" ::: "memory");
#endif

    munmap(rf_va, 0x1000);
    close(rf_fd);
    return 0;

}

// ---- disassembler ----

static void rf_fmt_ns(double ns, char *buf, size_t sz) {
    if      (ns >= 1e9) snprintf(buf, sz, "%gs",  ns * 1e-9);
    else if (ns >= 1e6) snprintf(buf, sz, "%gms", ns * 1e-6);
    else if (ns >= 1e3) snprintf(buf, sz, "%gus", ns * 1e-3);
    else                snprintf(buf, sz, "%gns", ns);
}

static void rf_build_opts(char *buf, size_t sz,
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

void disasm_rf(const uint32_t *r, char *buf, size_t sz) {
    uint32_t arm        = (r[0] >> 20) & 1u;
    uint32_t sticky_arm = (r[0] >> 19) & 1u;
    uint32_t kbc_mode   = (r[0] >> 17) & 3u;
    uint64_t kbc1       = ((uint64_t)(r[0] & 0x1FFFFu) << 19) | ((uint64_t)r[1] >> 13);
    uint64_t kbc2       = ((uint64_t)(r[1] & 0x1FFFu) << 23) | ((uint64_t)r[2] >> 9);
    uint32_t samples    = ((r[2] & 0x1FFu) << 11) | (r[3] >> 21);
    uint32_t dsamples   = (r[3] >> 1) & 0xFFFFFu;
    uint32_t marker     = r[3] & 1u;

    char tbuf[32];
    rf_fmt_ns((double)samples * RF_NS_PER_SAMPLE, tbuf, sizeof(tbuf));
    char extra[48] = "";
    if (dsamples) {
        char dtbuf[32];
        rf_fmt_ns((double)dsamples * RF_NS_PER_SAMPLE, dtbuf, sizeof(dtbuf));
        snprintf(extra, sizeof(extra), "t+%s", dtbuf);
    }
    char opts[96];
    rf_build_opts(opts, sizeof(opts), (int)arm, (int)sticky_arm, (int)marker, extra);

    switch (kbc_mode) {
        case 3:
            snprintf(buf, sz, "idl t=%s%s", tbuf, opts);
            break;
        case 2: {
            long double phs = twos2real(-180.0L,
                                        180.0L - ldexpl(1.0L, -RF_KBC_BITS),
                                        RF_KBC_BITS, kbc2);
            double phsd = round((double)phs * 1e5) / 1e5;
            if (phsd == 0.0) phsd = 0.0;
            snprintf(buf, sz, "ply phs=%g t=%s%s", phsd, tbuf, opts);
            break;
        }
        case 1:
            snprintf(buf, sz, "chp t=%s kbc1=0x%09" PRIx64 " kbc2=0x%09" PRIx64 "%s",
                     tbuf, kbc1, kbc2, opts);
            break;
        default:
            snprintf(buf, sz, "??? kbc_mode=%u t=%s%s", kbc_mode, tbuf, opts);
            break;
    }
}

int rf_inspect_channel(int ch) {

    if (ch < 0 || ch >= RF_CHANNELS) {
        fprintf(stderr, "rf channel must be 0..%d\n", RF_CHANNELS - 1);
        return 1;
    }

    char path[32];
    snprintf(path, sizeof(path), "/dev/uio%d", rf_uio_map[ch]);

    int fd = open(path, O_RDWR);
    if (fd < 0) { fprintf(stderr, "open(%s): %s\n", path, strerror(errno)); return 1; }

    void *va = mmap(NULL, 0x1000, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (va == MAP_FAILED) {
        fprintf(stderr, "mmap(%s): %s\n", path, strerror(errno));
        close(fd);
        return 1;
    }

    volatile uint32_t *base   = (volatile uint32_t *)va;
    int                sb     = BRAM_SEQ_TOTAL(RF_REG_PER_INSN) + RF_CTRL_REGS;
    volatile uint32_t *status = base + sb;

    uint32_t depth  = base[BRAM_DEPTH(RF_REG_PER_INSN)];
    uint32_t nsteps = depth + 1;
    if (nsteps > (uint32_t)RF_PC_MEM_DEPTH) nsteps = RF_PC_MEM_DEPTH;

    uint32_t flags = status[RF_REG_PER_INSN + 3];
    uint32_t iters = status[RF_REG_PER_INSN + 1];

    printf("rf%d:\n", ch);
    printf("  depth:  %u (%u steps)\n", depth, nsteps);
    printf("  iters:  %u\n", iters);
    printf("  armed:  %u\n", (flags >> 1) & 1u);
    printf("  empty:  %u\n",  flags & 1u);

    uint32_t *pc_seq     = malloc(nsteps * sizeof(uint32_t));
    uint32_t *insn_cache = calloc((size_t)RF_DEPTH * RF_REG_PER_INSN, sizeof(uint32_t));
    uint8_t  *fetched    = calloc(RF_DEPTH, 1);
    int       ret        = 0;

    if (!pc_seq || !insn_cache || !fetched) {
        fprintf(stderr, "malloc failed\n");
        ret = 1;
        goto done;
    }

    for (uint32_t addr = 0; addr < nsteps; addr++) {
        base[BRAM_PCST_ADDR]              = addr;
        base[BRAM_PCLD_STRB(RF_REG_PER_INSN)] = 0;
        base[BRAM_PCLD_STRB(RF_REG_PER_INSN)] = 1;
        pc_seq[addr] = (uint32_t)status[RF_REG_PER_INSN];
    }

    for (uint32_t addr = 0; addr < nsteps; addr++) {
        uint32_t pc = pc_seq[addr] & (RF_DEPTH - 1);
        if (!fetched[pc]) {
            base[BRAM_IST_ADDR]               = pc;
            base[BRAM_ILD_STRB(RF_REG_PER_INSN)] = 0;
            base[BRAM_ILD_STRB(RF_REG_PER_INSN)] = 1;
            for (int k = 0; k < RF_REG_PER_INSN; k++)
                insn_cache[pc * RF_REG_PER_INSN + k] = (uint32_t)status[k];
            fetched[pc] = 1;
        }
    }

    printf("  program:\n");
    for (uint32_t addr = 0; addr < nsteps; addr++) {
        uint32_t pc = pc_seq[addr] & (RF_DEPTH - 1);
        char abuf[128] = "???";
        disasm_rf(&insn_cache[pc * RF_REG_PER_INSN], abuf, sizeof(abuf));
        printf("    [%u] pc=%u: %s\n", addr, pc, abuf);
    }

    printf("  status:\n");
    for (int k = 0; k < RF_REG_PER_INSN; k++)
        printf("    insn_rd[%d]:   %08" PRIX32 "\n", k, (uint32_t)status[k]);
    printf("    pc_rd:        %08" PRIX32 "\n", (uint32_t)status[RF_REG_PER_INSN]);
    printf("    iters:        %08" PRIX32 "\n", (uint32_t)status[RF_REG_PER_INSN + 1]);
    printf("    pcmem_depth:  %08" PRIX32 "\n", (uint32_t)status[RF_REG_PER_INSN + 2]);
    printf("    flags:        %08" PRIX32 " (armed=%u empty=%u)\n",
           (uint32_t)status[RF_REG_PER_INSN + 3],
           (flags >> 1) & 1u, flags & 1u);

done:
    free(pc_seq);
    free(insn_cache);
    free(fetched);
    munmap(va, 0x1000);
    close(fd);
    return ret;

}
