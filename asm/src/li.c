#include "common.h"
#include "li.h"
#include "dc.h"
#include "rf.h"
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
        uint32_t *reg = &(prog->insn_mem[i * LI_REG_PER_INSN]);

        reg[0] = (insn->arm << 29) | (insn->sticky_arm << 28) |
                 (insn->idle << 27) | (insn->marker << 26) |
                 (insn->samples << 6) | (insn->dsamples >> 14);
        reg[1] = ((insn->dsamples & 0x3FFF) << 18) | insn->stride;

        prog->pc_mem[i] = i;

    }

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

    *(li_base + LI_BRAM_SEQ_REGS + LI_CTRL_REGS - 1) = 0;
    if (li_program->ctrl.default_I != -1) *(li_base + LI_BRAM_SEQ_REGS + 0) = (uint32_t)(li_program->ctrl.default_I & 0x3fff);
    if (li_program->ctrl.default_Q != -1) *(li_base + LI_BRAM_SEQ_REGS + 1) = (uint32_t)(li_program->ctrl.default_Q & 0x3fff);
    if (li_program->ctrl.max_burst != -1) *(li_base + LI_BRAM_SEQ_REGS + 2) = (uint32_t)(li_program->ctrl.max_burst & 0xff);
    if (li_program->ctrl.base_addr != -1) {
        *(li_base + LI_BRAM_SEQ_REGS + 3) = (uint32_t)(((uint64_t)li_program->ctrl.base_addr >> 32) & 0x1ffff);
        *(li_base + LI_BRAM_SEQ_REGS + 4) = (uint32_t)((uint64_t)li_program->ctrl.base_addr & 0xffffffff);
    }
    *(li_base + LI_BRAM_SEQ_REGS + LI_CTRL_REGS - 1) = 1;

    for (unsigned int i = 0; i < n; i++) {
        li_base[BRAM_IST_ADDR] = i;
        for (unsigned int k = 0; k < LI_REG_PER_INSN; k++)
            li_base[BRAM_IST_LO + k] = li_program->insn_mem[i * LI_REG_PER_INSN + k];
        li_base[BRAM_IST_STRB(LI_REG_PER_INSN)] = 0;
        li_base[BRAM_IST_STRB(LI_REG_PER_INSN)] = 1;
    }

    for (unsigned int j = 0; j < n; j++) {
        li_base[BRAM_PCST_ADDR] = j;
        li_base[BRAM_PCST]      = li_program->pc_mem[j];
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

// ---- disassembler ----

static void li_fmt_ns(double ns, char *buf, size_t sz) {
    if      (ns >= 1e9) snprintf(buf, sz, "%gs",  ns * 1e-9);
    else if (ns >= 1e6) snprintf(buf, sz, "%gms", ns * 1e-6);
    else if (ns >= 1e3) snprintf(buf, sz, "%gus", ns * 1e-3);
    else                snprintf(buf, sz, "%gns", ns);
}

static void li_build_opts(char *buf, size_t sz,
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

void disasm_li(const uint32_t *r, char *buf, size_t sz) {
    uint32_t arm        = (r[0] >> 29) & 1u;
    uint32_t sticky_arm = (r[0] >> 28) & 1u;
    uint32_t idle       = (r[0] >> 27) & 1u;
    uint32_t marker     = (r[0] >> 26) & 1u;
    uint32_t samples    = (r[0] >> 6) & 0xFFFFFu;
    uint32_t dsamples   = ((r[0] & 0x3Fu) << 14) | (r[1] >> 18);
    uint32_t stride     = r[1] & 0x3FFFFu;

    char extra[48] = "";
    if (dsamples) {
        char dtbuf[32];
        li_fmt_ns((double)dsamples * LI_NS_PER_SAMPLE, dtbuf, sizeof(dtbuf));
        snprintf(extra, sizeof(extra), "t+%s", dtbuf);
    }
    char opts[96];
    li_build_opts(opts, sizeof(opts), (int)arm, (int)sticky_arm, (int)marker, extra);

    if (idle) {
        char tbuf[32];
        li_fmt_ns((double)samples * LI_NS_PER_SAMPLE, tbuf, sizeof(tbuf));
        snprintf(buf, sz, "idl t=%s%s", tbuf, opts);
    } else {
        char tbuf[32];
        li_fmt_ns((double)samples * (double)stride * LI_NS_PER_SAMPLE, tbuf, sizeof(tbuf));
        snprintf(buf, sz, "sam n=%u t=%s%s", samples, tbuf, opts);
    }
}

int li_inspect_channel(int ch) {

    if (ch < 0 || ch >= LI_CHANNELS) {
        fprintf(stderr, "li channel must be 0..%d\n", LI_CHANNELS - 1);
        return 1;
    }

    char path[32];
    snprintf(path, sizeof(path), "/dev/uio%d", li_uio_map[ch]);

    int fd = open(path, O_RDWR);
    if (fd < 0) { fprintf(stderr, "open(%s): %s\n", path, strerror(errno)); return 1; }

    void *va = mmap(NULL, 0x1000, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (va == MAP_FAILED) {
        fprintf(stderr, "mmap(%s): %s\n", path, strerror(errno));
        close(fd);
        return 1;
    }

    volatile uint32_t *base   = (volatile uint32_t *)va;
    int                sb     = BRAM_SEQ_TOTAL(LI_REG_PER_INSN) + LI_CTRL_REGS;
    volatile uint32_t *status = base + sb;

    uint32_t depth  = base[BRAM_DEPTH(LI_REG_PER_INSN)];
    uint32_t nsteps = depth + 1;
    if (nsteps > (uint32_t)LI_PC_MEM_DEPTH) nsteps = LI_PC_MEM_DEPTH;

    uint32_t flags = status[LI_REG_PER_INSN + 3];
    uint32_t iters = status[LI_REG_PER_INSN + 1];

    printf("li%d:\n", ch);
    printf("  depth:  %u (%u steps)\n", depth, nsteps);
    printf("  iters:  %u\n", iters);
    printf("  armed:  %u\n", (flags >> 1) & 1u);
    printf("  empty:  %u\n",  flags & 1u);
    if (LI_STATUS_REGS > LI_REG_PER_INSN + 4)
        printf("  samples_lost:  %08" PRIX32 "\n", (uint32_t)status[LI_REG_PER_INSN + 4]);
    if (LI_STATUS_REGS > LI_REG_PER_INSN + 5)
        printf("  samples_inbuf: %08" PRIX32 "\n", (uint32_t)status[LI_REG_PER_INSN + 5]);

    uint32_t *pc_seq     = malloc(nsteps * sizeof(uint32_t));
    uint32_t *insn_cache = calloc((size_t)LI_DEPTH * LI_REG_PER_INSN, sizeof(uint32_t));
    uint8_t  *fetched    = calloc(LI_DEPTH, 1);
    int       ret        = 0;

    if (!pc_seq || !insn_cache || !fetched) {
        fprintf(stderr, "malloc failed\n");
        ret = 1;
        goto done;
    }

    for (uint32_t addr = 0; addr < nsteps; addr++) {
        base[BRAM_PCST_ADDR]              = addr;
        base[BRAM_PCLD_STRB(LI_REG_PER_INSN)] = 0;
        base[BRAM_PCLD_STRB(LI_REG_PER_INSN)] = 1;
        pc_seq[addr] = (uint32_t)status[LI_REG_PER_INSN];
    }

    for (uint32_t addr = 0; addr < nsteps; addr++) {
        uint32_t pc = pc_seq[addr] & (LI_DEPTH - 1);
        if (!fetched[pc]) {
            base[BRAM_IST_ADDR]               = pc;
            base[BRAM_ILD_STRB(LI_REG_PER_INSN)] = 0;
            base[BRAM_ILD_STRB(LI_REG_PER_INSN)] = 1;
            for (int k = 0; k < LI_REG_PER_INSN; k++)
                insn_cache[pc * LI_REG_PER_INSN + k] = (uint32_t)status[k];
            fetched[pc] = 1;
        }
    }

    printf("  program:\n");
    for (uint32_t addr = 0; addr < nsteps; addr++) {
        uint32_t pc = pc_seq[addr] & (LI_DEPTH - 1);
        char abuf[128] = "???";
        disasm_li(&insn_cache[pc * LI_REG_PER_INSN], abuf, sizeof(abuf));
        printf("    [%u] pc=%u: %s\n", addr, pc, abuf);
    }

    printf("  status:\n");
    for (int k = 0; k < LI_REG_PER_INSN; k++)
        printf("    insn_rd[%d]:   %08" PRIX32 "\n", k, (uint32_t)status[k]);
    printf("    pc_rd:        %08" PRIX32 "\n", (uint32_t)status[LI_REG_PER_INSN]);
    printf("    iters:        %08" PRIX32 "\n", (uint32_t)status[LI_REG_PER_INSN + 1]);
    printf("    pcmem_depth:  %08" PRIX32 "\n", (uint32_t)status[LI_REG_PER_INSN + 2]);
    printf("    flags:        %08" PRIX32 " (armed=%u empty=%u)\n",
           (uint32_t)status[LI_REG_PER_INSN + 3],
           (flags >> 1) & 1u, flags & 1u);

done:
    free(pc_seq);
    free(insn_cache);
    free(fetched);
    munmap(va, 0x1000);
    close(fd);
    return ret;

}

