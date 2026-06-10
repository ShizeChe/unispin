#include "disasm.h"
#include "dc.h"
#include "rf.h"
#include "li.h"
#include "ex.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>

/*
 * Read a bin file produced by write_bin and reconstruct program structs.
 * Caller must free all non-NULL entries in the arrays and *launch.
 */
int disassemble(FILE *fp,
                dc_program_t *dc_programs[],
                rf_program_t *rf_programs[],
                li_program_t *li_programs[],
                ex_program_t *ex_programs[],
                launch_t **launch) {

    char line[256];

    typedef enum {
        TOP,
        DC_HDR, DC_IMEM, DC_PCMEM,
        RF_HDR, RF_IMEM, RF_PCMEM,
        LI_HDR, LI_IMEM, LI_PCMEM,
        EX_HDR, EX_IMEM, EX_PCMEM,
        LAUNCH_DATA
    } state_t;

    state_t  state   = TOP;
    unsigned ch      = 0;
    unsigned idx     = 0;
    unsigned n       = 0;
    int      advance = 1;

    line[0] = '\0';

    for (;;) {
        if (advance) {
            if (!fgets(line, sizeof(line), fp)) break;
            line[strcspn(line, "\r\n")] = '\0';
            if (line[0] == '\0') continue;
        }
        advance = 1;

        switch (state) {  /* advance=0 on non-consuming transitions */

            case TOP:
                if (sscanf(line, "dc%u", &ch) == 1) {
                    dc_programs[ch] = (dc_program_t *)calloc(1, sizeof(dc_program_t));
                    dc_programs[ch]->ctrl.dvsr         = -1;
                    dc_programs[ch]->ctrl.delay_cycles = -1;
                    dc_programs[ch]->ctrl.cs_up_cycles = -1;
                    dc_programs[ch]->ctrl.ldac_cycles  = -1;
                    state = DC_HDR;
                } else if (sscanf(line, "rf%u", &ch) == 1) {
                    rf_programs[ch] = (rf_program_t *)calloc(1, sizeof(rf_program_t));
                    rf_programs[ch]->nco_freq       = -1;
                    rf_programs[ch]->ctrl.default_I = -1;
                    rf_programs[ch]->ctrl.default_Q = -1;
                    state = RF_HDR;
                } else if (sscanf(line, "li%u", &ch) == 1) {
                    li_programs[ch] = (li_program_t *)calloc(1, sizeof(li_program_t));
                    li_programs[ch]->ctrl.nco_freq  = -1;
                    li_programs[ch]->ctrl.nco_phase = -1;
                    li_programs[ch]->ctrl.default_I = -1;
                    li_programs[ch]->ctrl.default_Q = -1;
                    li_programs[ch]->ctrl.max_burst = -1;
                    li_programs[ch]->ctrl.base_addr = -1;
                    state = LI_HDR;
                } else if (sscanf(line, "ex%u", &ch) == 1) {
                    ex_programs[ch] = (ex_program_t *)calloc(1, sizeof(ex_program_t));
                    state = EX_HDR;
                } else if (strcmp(line, "launch") == 0) {
                    *launch = (launch_t *)calloc(1, sizeof(launch_t));
                    idx     = 0;
                    state   = LAUNCH_DATA;
                }
                break;

            case DC_HDR: {
                uint32_t v32; int32_t s32;
                if (sscanf(line, "repeat %"SCNu32, &v32) == 1)
                    dc_programs[ch]->repeat = v32;
                else if (sscanf(line, "len %u", &n) == 1)
                    dc_programs[ch]->len = n;
                else if (sscanf(line, "dvsr %"SCNd32, &s32) == 1)
                    dc_programs[ch]->ctrl.dvsr = s32;
                else if (sscanf(line, "delay_cycles %"SCNd32, &s32) == 1)
                    dc_programs[ch]->ctrl.delay_cycles = s32;
                else if (sscanf(line, "cs_up_cycles %"SCNd32, &s32) == 1)
                    dc_programs[ch]->ctrl.cs_up_cycles = s32;
                else if (sscanf(line, "ldac_cycles %"SCNd32, &s32) == 1)
                    dc_programs[ch]->ctrl.ldac_cycles = s32;
                else if (strcmp(line, "imem") == 0) {
                    idx = 0; state = DC_IMEM;
                }
                break;
            }

            case DC_IMEM: {
                uint32_t w;
                if (sscanf(line, "0x%"SCNx32, &w) == 1) {
                    dc_programs[ch]->insn_mem[idx++] = w;
                } else if (strcmp(line, "pcmem") == 0) {
                    idx = 0; state = DC_PCMEM;
                }
                break;
            }

            case DC_PCMEM: {
                uint32_t w;
                if (sscanf(line, "0x%"SCNx32, &w) == 1)
                    dc_programs[ch]->pc_mem[idx++] = w;
                else { state = TOP; advance = 0; }
                break;
            }

            case RF_HDR: {
                uint32_t v32; int32_t s32; uint64_t u64;
                if (sscanf(line, "repeat %"SCNu32, &v32) == 1)
                    rf_programs[ch]->repeat = v32;
                else if (sscanf(line, "len %u", &n) == 1)
                    rf_programs[ch]->len = n;
                else if (sscanf(line, "nco_freq 0x%"SCNx64, &u64) == 1)
                    rf_programs[ch]->nco_freq = (int64_t)u64;
                else if (sscanf(line, "default_I %"SCNd32, &s32) == 1)
                    rf_programs[ch]->ctrl.default_I = s32;
                else if (sscanf(line, "default_Q %"SCNd32, &s32) == 1)
                    rf_programs[ch]->ctrl.default_Q = s32;
                else if (strcmp(line, "imem") == 0) {
                    idx = 0; state = RF_IMEM;
                }
                break;
            }

            case RF_IMEM: {
                uint32_t w;
                if (sscanf(line, "0x%"SCNx32, &w) == 1)
                    rf_programs[ch]->insn_mem[idx++] = w;
                else if (strcmp(line, "pcmem") == 0) {
                    idx = 0; state = RF_PCMEM;
                }
                break;
            }

            case RF_PCMEM: {
                uint32_t w;
                if (sscanf(line, "0x%"SCNx32, &w) == 1)
                    rf_programs[ch]->pc_mem[idx++] = w;
                else { state = TOP; advance = 0; }
                break;
            }

            case LI_HDR: {
                uint32_t v32; int32_t s32; uint64_t u64;
                if (sscanf(line, "repeat %"SCNu32, &v32) == 1)
                    li_programs[ch]->repeat = v32;
                else if (sscanf(line, "len %u", &n) == 1)
                    li_programs[ch]->len = n;
                else if (sscanf(line, "nco_freq 0x%"SCNx64, &u64) == 1)
                    li_programs[ch]->ctrl.nco_freq = (int64_t)u64;
                else if (sscanf(line, "nco_phase %"SCNd32, &s32) == 1)
                    li_programs[ch]->ctrl.nco_phase = s32;
                else if (sscanf(line, "default_I %"SCNd32, &s32) == 1)
                    li_programs[ch]->ctrl.default_I = s32;
                else if (sscanf(line, "default_Q %"SCNd32, &s32) == 1)
                    li_programs[ch]->ctrl.default_Q = s32;
                else if (sscanf(line, "max_burst %"SCNd32, &s32) == 1)
                    li_programs[ch]->ctrl.max_burst = s32;
                else if (sscanf(line, "base_addr 0x%"SCNx64, &u64) == 1)
                    li_programs[ch]->ctrl.base_addr = (int64_t)u64;
                else if (strcmp(line, "imem") == 0) {
                    idx = 0; state = LI_IMEM;
                }
                break;
            }

            case LI_IMEM: {
                uint32_t w;
                if (sscanf(line, "0x%"SCNx32, &w) == 1)
                    li_programs[ch]->insn_mem[idx++] = w;
                else if (strcmp(line, "pcmem") == 0) {
                    idx = 0; state = LI_PCMEM;
                }
                break;
            }

            case LI_PCMEM: {
                uint32_t w;
                if (sscanf(line, "0x%"SCNx32, &w) == 1)
                    li_programs[ch]->pc_mem[idx++] = w;
                else { state = TOP; advance = 0; }
                break;
            }

            case EX_HDR: {
                uint32_t v32;
                if (sscanf(line, "repeat %"SCNu32, &v32) == 1)
                    ex_programs[ch]->repeat = v32;
                else if (sscanf(line, "len %u", &n) == 1)
                    ex_programs[ch]->len = n;
                else if (strcmp(line, "imem") == 0) {
                    idx = 0; state = EX_IMEM;
                }
                break;
            }

            case EX_IMEM: {
                uint32_t w;
                if (sscanf(line, "0x%"SCNx32, &w) == 1)
                    ex_programs[ch]->insn_mem[idx++] = w;
                else if (strcmp(line, "pcmem") == 0) {
                    idx = 0; state = EX_PCMEM;
                }
                break;
            }

            case EX_PCMEM: {
                uint32_t w;
                if (sscanf(line, "0x%"SCNx32, &w) == 1)
                    ex_programs[ch]->pc_mem[idx++] = w;
                else { state = TOP; advance = 0; }
                break;
            }

            case LAUNCH_DATA: {
                uint32_t w;
                if (sscanf(line, "0x%"SCNx32, &w) == 1) {
                    switch (idx++) {
                        case 0: (*launch)->dc_chmask    = w; break;
                        case 1: (*launch)->rf_chmask    = w; break;
                        case 2: (*launch)->li_chmask    = w; break;
                        case 3: (*launch)->ex_chmask    = w; break;
                        case 4: (*launch)->use_trigger  = w; break;
                        case 5: (*launch)->iters        = w; break;
                        default: break;
                    }
                } else { state = TOP; advance = 0; }
                break;
            }
        }
    }

    return 0;
}

static void fmt_hz(long double hz, char *buf, size_t sz) {
    if (hz >= 1e9L || hz <= -1e9L)
        snprintf(buf, sz, "%.6LgGHz", hz / 1e9L);
    else if (hz >= 1e6L || hz <= -1e6L)
        snprintf(buf, sz, "%.6LgMHz", hz / 1e6L);
    else if (hz >= 1e3L || hz <= -1e3L)
        snprintf(buf, sz, "%.6LgkHz", hz / 1e3L);
    else
        snprintf(buf, sz, "%.6LgHz", hz);
}

/*
 * Write a .asm source file reconstructed from populated program structs.
 * Uses the per-channel disasm_xx functions to format each instruction.
 */
void write_asm(FILE *out,
               dc_program_t *dc_programs[],
               rf_program_t *rf_programs[],
               li_program_t *li_programs[],
               ex_program_t *ex_programs[],
               launch_t *launch) {

    char buf[256];

    for (int i = 0; i < DC_CHANNELS; i++) {
        if (dc_programs[i] == NULL) continue;
        dc_program_t *p = dc_programs[i];

        fprintf(out, ".program dc%d\n", i);
        if (p->ctrl.dvsr         != -1) fprintf(out, ".dvsr %d\n", p->ctrl.dvsr);
        if (p->ctrl.delay_cycles != -1) fprintf(out, ".dlay %d\n", p->ctrl.delay_cycles);
        if (p->ctrl.cs_up_cycles != -1) fprintf(out, ".csup %d\n", p->ctrl.cs_up_cycles);
        if (p->ctrl.ldac_cycles  != -1) fprintf(out, ".ldac %d\n", p->ctrl.ldac_cycles);
        fprintf(out, ".repeat %"PRIu32"\n", p->repeat);

        unsigned int n = p->len;
        for (unsigned int j = 0; j < n; j++) {
            uint32_t pc = p->pc_mem[j];
            disasm_dc(&p->insn_mem[pc * DC_REG_PER_INSN], buf, sizeof(buf));
            fprintf(out, "    %s\n", buf);
        }
        fprintf(out, "\n");
    }

    for (int i = 0; i < RF_CHANNELS; i++) {
        if (rf_programs[i] == NULL) continue;
        rf_program_t *p = rf_programs[i];

        fprintf(out, ".program rf%d\n", i);
        if (p->nco_freq != -1) {
            long double hz = twos2real(RF_FNCO_MIN, RF_FNCO_MAX, RF_FNCO_BITS, p->nco_freq);
            char hzbuf[32];
            fmt_hz(hz, hzbuf, sizeof(hzbuf));
            fprintf(out, ".fnco %s\n", hzbuf);
        }
        if (p->ctrl.default_I != -1) fprintf(out, ".defI 0x%04"PRIX32"\n", (uint32_t)(p->ctrl.default_I & 0x3fff));
        if (p->ctrl.default_Q != -1) fprintf(out, ".defQ 0x%04"PRIX32"\n", (uint32_t)(p->ctrl.default_Q & 0x3fff));
        fprintf(out, ".repeat %"PRIu32"\n", p->repeat);

        unsigned int n = p->len;
        for (unsigned int j = 0; j < n; j++) {
            uint32_t pc = p->pc_mem[j];
            disasm_rf(&p->insn_mem[pc * RF_REG_PER_INSN], buf, sizeof(buf));
            fprintf(out, "    %s\n", buf);
        }
        fprintf(out, "\n");
    }

    for (int i = 0; i < LI_CHANNELS; i++) {
        if (li_programs[i] == NULL) continue;
        li_program_t *p = li_programs[i];

        fprintf(out, ".program li%d\n", i);
        if (p->ctrl.nco_freq != -1) {
            long double hz = twos2real(LI_FNCO_MIN, LI_FNCO_MAX, LI_FNCO_BITS, p->ctrl.nco_freq);
            char hzbuf[32];
            fmt_hz(hz, hzbuf, sizeof(hzbuf));
            fprintf(out, ".fnco %s\n", hzbuf);
        }
        if (p->ctrl.nco_phase != -1) {
            long double deg = twos2real(LI_PNCO_MIN, LI_PNCO_MAX, LI_PNCO_BITS, (uint64_t)(uint32_t)p->ctrl.nco_phase);
            fprintf(out, ".pnco %.6Lg\n", deg);
        }
        if (p->ctrl.default_I != -1) fprintf(out, ".defI 0x%04"PRIX32"\n", (uint32_t)(p->ctrl.default_I & 0x3fff));
        if (p->ctrl.default_Q != -1) fprintf(out, ".defQ 0x%04"PRIX32"\n", (uint32_t)(p->ctrl.default_Q & 0x3fff));
        if (p->ctrl.max_burst != -1) fprintf(out, ".maxb %"PRId32"\n", p->ctrl.max_burst);
        if (p->ctrl.base_addr != -1) fprintf(out, ".addr 0x%016"PRIX64"\n", (uint64_t)p->ctrl.base_addr);
        fprintf(out, ".repeat %"PRIu32"\n", p->repeat);

        unsigned int n = p->len;
        for (unsigned int j = 0; j < n; j++) {
            uint32_t pc = p->pc_mem[j];
            disasm_li(&p->insn_mem[pc * LI_REG_PER_INSN], buf, sizeof(buf));
            fprintf(out, "    %s\n", buf);
        }
        fprintf(out, "\n");
    }

    for (int i = 0; i < EX_CHANNELS; i++) {
        if (ex_programs[i] == NULL) continue;
        ex_program_t *p = ex_programs[i];

        fprintf(out, ".program ex%d\n", i);
        fprintf(out, ".repeat %"PRIu32"\n", p->repeat);

        unsigned int n = p->len;
        for (unsigned int j = 0; j < n; j++) {
            uint32_t pc = p->pc_mem[j];
            disasm_ex(&p->insn_mem[pc * EX_REG_PER_INSN], buf, sizeof(buf));
            fprintf(out, "    %s\n", buf);
        }
        fprintf(out, "\n");
    }

    if (launch != NULL) {
        fprintf(out, ".launch");
        for (int i = 0; i < DC_CHANNELS; i++)
            if (launch->dc_chmask & (1u << i)) fprintf(out, " dc%d", i);
        for (int i = 0; i < RF_CHANNELS; i++)
            if (launch->rf_chmask & (1u << i)) fprintf(out, " rf%d", i);
        for (int i = 0; i < LI_CHANNELS; i++)
            if (launch->li_chmask & (1u << i)) fprintf(out, " li%d", i);
        for (int i = 0; i < EX_CHANNELS; i++)
            if (launch->ex_chmask & (1u << i)) fprintf(out, " ex%d", i);
        fprintf(out, "\n");
    }
}

int inspect_named_channel(const char *name) {
    if (strncmp(name, "dc", 2) == 0) {
        int ch = atoi(name + 2);
        if (ch < 0 || ch >= DC_CHANNELS) {
            fprintf(stderr, "dc channel must be 0..%d\n", DC_CHANNELS - 1);
            return 1;
        }
        return dc_inspect_channel(ch);
    } else if (strncmp(name, "rf", 2) == 0) {
        int ch = atoi(name + 2);
        if (ch < 0 || ch >= RF_CHANNELS) {
            fprintf(stderr, "rf channel must be 0..%d\n", RF_CHANNELS - 1);
            return 1;
        }
        return rf_inspect_channel(ch);
    } else if (strncmp(name, "li", 2) == 0) {
        int ch = atoi(name + 2);
        if (ch < 0 || ch >= LI_CHANNELS) {
            fprintf(stderr, "li channel must be 0..%d\n", LI_CHANNELS - 1);
            return 1;
        }
        return li_inspect_channel(ch);
    } else if (strncmp(name, "ex", 2) == 0) {
        int ch = atoi(name + 2);
        if (ch < 0 || ch >= EX_CHANNELS) {
            fprintf(stderr, "ex channel must be 0..%d\n", EX_CHANNELS - 1);
            return 1;
        }
        return ex_inspect_channel(ch);
    } else {
        fprintf(stderr, "unknown channel '%s' (use dc<n>, rf<n>, li<n>, ex<n>)\n", name);
        return 1;
    }
}
