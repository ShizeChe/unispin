#include "asm.h"
#include "simcli.h"
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <math.h>
#include <string.h>
#include <inttypes.h>

static int line_empty(char *s) {
    while (isspace((unsigned char)*s))
        s++;
    return *s == '\0' || *s == ';';
}

int assemble(FILE *fp,
             dc_program_t *dc_programs[],
             rf_program_t *rf_programs[],
             li_program_t *li_programs[],
             ex_program_t *ex_programs[],
             launch_t **launch) {

    char line[256] = {0};

    typedef enum {
        PROGRAM,
        DC_CTRL, DC_REPEAT, DC_INSN,
        RF_CTRL, RF_REPEAT, RF_INSN,
        LI_CTRL, LI_REPEAT, LI_INSN,
        EX_REPEAT, EX_INSN,
        LAUNCH
    } state_t;

    state_t  state   = PROGRAM;
    uint32_t channel = 0;
    char     tmp[10];
    char    *success = tmp;
    int      i;

    while (success != NULL) {

        if (line_empty(line)) {
            success = fgets(line, sizeof(line), fp);
            continue;
        }

        switch (state) {

            case PROGRAM:
                if (sscanf(line, ".program dc%u ", &channel)) {
                    dc_programs[channel] = (dc_program_t *)calloc(1, sizeof(dc_program_t));
                    dc_programs[channel]->ctrl.dvsr         = -1;
                    dc_programs[channel]->ctrl.delay_cycles = -1;
                    dc_programs[channel]->ctrl.cs_up_cycles = -1;
                    dc_programs[channel]->ctrl.ldac_cycles  = -1;
                    state = DC_CTRL;
                    success = fgets(line, sizeof(line), fp);
                } else if (sscanf(line, ".program rf%u ", &channel)) {
                    rf_programs[channel] = (rf_program_t *)calloc(1, sizeof(rf_program_t));
                    rf_programs[channel]->nco_freq       = -1;
                    rf_programs[channel]->ctrl.default_I = -1;
                    rf_programs[channel]->ctrl.default_Q = -1;
                    state = RF_CTRL;
                    success = fgets(line, sizeof(line), fp);
                } else if (sscanf(line, ".program li%u ", &channel)) {
                    li_programs[channel] = (li_program_t *)calloc(1, sizeof(li_program_t));
                    li_programs[channel]->ctrl.nco_freq  = -1;
                    li_programs[channel]->ctrl.nco_phase = -1;
                    li_programs[channel]->ctrl.default_I = -1;
                    li_programs[channel]->ctrl.default_Q = -1;
                    li_programs[channel]->ctrl.max_burst = -1;
                    li_programs[channel]->ctrl.base_addr = -1;
                    state = LI_CTRL;
                    success = fgets(line, sizeof(line), fp);
                } else if (sscanf(line, ".program ex%u ", &channel)) {
                    ex_programs[channel] = (ex_program_t *)calloc(1, sizeof(ex_program_t));
                    state = EX_REPEAT;
                    success = fgets(line, sizeof(line), fp);
                } else if (strncmp(line, ".launch", 7) == 0) {
                    *launch = (launch_t *)calloc(1, sizeof(launch_t));
                    (*launch)->iters = 1;
                    state = LAUNCH;
                } else {
                    return -1;
                }
                break;

            case DC_CTRL: {
                int dc_dvsr, dc_delay_cycles, dc_cs_up_cycles, dc_ldac_cycles;
                if (sscanf(line, ".dvsr %d ", &dc_dvsr)) {
                    dc_programs[channel]->ctrl.dvsr = dc_dvsr;
                    assert(dc_dvsr > 0);
                    success = fgets(line, sizeof(line), fp);
                } else if (sscanf(line, ".dlay %d ", &dc_delay_cycles)) {
                    dc_programs[channel]->ctrl.delay_cycles = dc_delay_cycles;
                    assert(dc_delay_cycles > 0);
                    success = fgets(line, sizeof(line), fp);
                } else if (sscanf(line, ".csup %d ", &dc_cs_up_cycles)) {
                    dc_programs[channel]->ctrl.cs_up_cycles = dc_cs_up_cycles;
                    assert(dc_cs_up_cycles > 0);
                    success = fgets(line, sizeof(line), fp);
                } else if (sscanf(line, ".ldac %d ", &dc_ldac_cycles)) {
                    dc_programs[channel]->ctrl.ldac_cycles = dc_ldac_cycles;
                    assert(dc_ldac_cycles > 0);
                    success = fgets(line, sizeof(line), fp);
                } else {
                    state = DC_REPEAT;
                }
                break;
            }

            case DC_REPEAT: {
                uint32_t dc_repeat;
                if (sscanf(line, ".repeat %u ", &dc_repeat)) {
                    dc_programs[channel]->repeat = dc_repeat;
                    assert(dc_repeat > 0);
                    state = DC_INSN;
                    success = fgets(line, sizeof(line), fp);
                } else {
                    return -1;
                }
                break;
            }

            case DC_INSN: {
                dc_insn_t dc_insn;
                i = 0;
                while (success != NULL) {
                    if (dc_parse_insn(line, &dc_insn) == 0) {
                        if (i >= DC_DEPTH) {
                            printf("Exceeding maximum number of dc instructions:\n%s\n", line);
                            return -1;
                        }
                        dc_programs[channel]->insns[i] = dc_insn;
                        success = fgets(line, sizeof(line), fp);
                        i++;
                    } else {
                        dc_programs[channel]->len = i;
                        dc_assemble(dc_programs[channel]);
                        i = 0;
                        state = PROGRAM;
                        break;
                    }
                }
                break;
            }

            case RF_CTRL: {
                char rf_ctrl_tok[32];
                uint64_t rf_nco_freq_hex;
                long double rf_nco_freq;
                uint32_t rf_default_I_hex;
                double rf_default_I;
                uint32_t rf_default_Q_hex;
                double rf_default_Q;

                if (sscanf(line, ".fnco %31s ", rf_ctrl_tok)) {
                    if (sscanf(rf_ctrl_tok, "0x%lx", &rf_nco_freq_hex)) {
                        rf_programs[channel]->nco_freq = (int64_t)rf_nco_freq_hex;
                        success = fgets(line, sizeof(line), fp);
                    } else if (parse_freq(rf_ctrl_tok, &rf_nco_freq) == 0) {
                        rf_programs[channel]->nco_freq = real2twos(RF_FNCO_MIN,
                            RF_FNCO_MAX, RF_FNCO_BITS, rf_nco_freq, 1);
                        success = fgets(line, sizeof(line), fp);
                    } else { return -1; }
                } else if (sscanf(line, ".defI %31s ", rf_ctrl_tok)) {
                    if (sscanf(rf_ctrl_tok, "0x%x", &rf_default_I_hex)) {
                        rf_programs[channel]->ctrl.default_I = (int32_t)rf_default_I_hex;
                        success = fgets(line, sizeof(line), fp);
                    } else if (sscanf(rf_ctrl_tok, "%lf", &rf_default_I)) {
                        rf_programs[channel]->ctrl.default_I = real2twos(-1,
                            1, RF_IQ_BITS, rf_default_I, 1);
                        success = fgets(line, sizeof(line), fp);
                    } else { return -1; }
                } else if (sscanf(line, ".defQ %31s ", rf_ctrl_tok)) {
                    if (sscanf(rf_ctrl_tok, "0x%x", &rf_default_Q_hex)) {
                        rf_programs[channel]->ctrl.default_Q = (int32_t)rf_default_Q_hex;
                        success = fgets(line, sizeof(line), fp);
                    } else if (sscanf(rf_ctrl_tok, "%lf", &rf_default_Q)) {
                        rf_programs[channel]->ctrl.default_Q = real2twos(-1,
                            1, RF_IQ_BITS, rf_default_Q, 1);
                        success = fgets(line, sizeof(line), fp);
                    } else { return -1; }
                } else {
                    state = RF_REPEAT;
                }
                (void)rf_default_Q_hex; /* may be unused if hex branch not taken */
                break;
            }

            case RF_REPEAT: {
                uint32_t rf_repeat;
                if (sscanf(line, ".repeat %u ", &rf_repeat)) {
                    rf_programs[channel]->repeat = rf_repeat;
                    assert(rf_repeat > 0);
                    state = RF_INSN;
                    success = fgets(line, sizeof(line), fp);
                } else { return -1; }
                break;
            }

            case RF_INSN: {
                assert(rf_programs[channel]->nco_freq != -1);
                rf_insn_t rf_insn;
                i = 0;
                long double rf_fnco_hz = twos2real(RF_FNCO_MIN, RF_FNCO_MAX,
                    RF_FNCO_BITS, rf_programs[channel]->nco_freq);
                while (success != NULL) {
                    if (rf_parse_insn(line, &rf_insn, rf_fnco_hz) == 0) {
                        if (i >= RF_DEPTH) {
                            printf("Exceeding maximum number of rf instructions:\n%s\n", line);
                            return -1;
                        }
                        rf_programs[channel]->insns[i] = rf_insn;
                        success = fgets(line, sizeof(line), fp);
                        i++;
                    } else {
                        rf_programs[channel]->len = i;
                        rf_assemble(rf_programs[channel]);
                        i = 0;
                        state = PROGRAM;
                        break;
                    }
                }
                break;
            }

            case LI_CTRL: {
                char li_ctrl_tok[32];
                uint64_t li_nco_freq_hex;
                long double li_nco_freq;
                uint32_t li_nco_phase_hex;
                double li_nco_phase;
                uint32_t li_default_I_hex;
                double li_default_I;
                uint32_t li_default_Q_hex;
                double li_default_Q;
                uint32_t li_max_burst_val;
                uint64_t li_base_addr_hex;

                if (sscanf(line, ".fnco %31s ", li_ctrl_tok)) {
                    if (sscanf(li_ctrl_tok, "0x%lx", &li_nco_freq_hex)) {
                        li_programs[channel]->ctrl.nco_freq = (int64_t)li_nco_freq_hex;
                        success = fgets(line, sizeof(line), fp);
                    } else if (parse_freq(li_ctrl_tok, &li_nco_freq) == 0) {
                        li_programs[channel]->ctrl.nco_freq = real2twos(LI_FNCO_MIN,
                            LI_FNCO_MAX, LI_FNCO_BITS, li_nco_freq, 1);
                        success = fgets(line, sizeof(line), fp);
                    } else { return -1; }
                } else if (sscanf(line, ".pnco %31s ", li_ctrl_tok)) {
                    if (sscanf(li_ctrl_tok, "0x%x", &li_nco_phase_hex)) {
                        li_programs[channel]->ctrl.nco_phase = (int32_t)li_nco_phase_hex;
                        success = fgets(line, sizeof(line), fp);
                    } else if (sscanf(li_ctrl_tok, "%lf", &li_nco_phase)) {
                        li_programs[channel]->ctrl.nco_phase = real2twos(LI_PNCO_MIN,
                            LI_PNCO_MAX, LI_PNCO_BITS, li_nco_phase, 1);
                        success = fgets(line, sizeof(line), fp);
                    } else { return -1; }
                } else if (sscanf(line, ".defI %31s ", li_ctrl_tok)) {
                    if (sscanf(li_ctrl_tok, "0x%x", &li_default_I_hex)) {
                        li_programs[channel]->ctrl.default_I = (int32_t)li_default_I_hex;
                        success = fgets(line, sizeof(line), fp);
                    } else if (sscanf(li_ctrl_tok, "%lf", &li_default_I)) {
                        li_programs[channel]->ctrl.default_I = real2twos(-1,
                            1, LI_IQ_BITS, li_default_I, 1);
                        success = fgets(line, sizeof(line), fp);
                    } else { return -1; }
                } else if (sscanf(line, ".defQ %31s ", li_ctrl_tok)) {
                    if (sscanf(li_ctrl_tok, "0x%x", &li_default_Q_hex)) {
                        li_programs[channel]->ctrl.default_Q = (int32_t)li_default_Q_hex;
                        success = fgets(line, sizeof(line), fp);
                    } else if (sscanf(li_ctrl_tok, "%lf", &li_default_Q)) {
                        li_programs[channel]->ctrl.default_Q = real2twos(-1,
                            1, LI_IQ_BITS, li_default_Q, 1);
                        success = fgets(line, sizeof(line), fp);
                    } else { return -1; }
                } else if (sscanf(line, ".maxb %31s ", li_ctrl_tok)) {
                    if (sscanf(li_ctrl_tok, "0x%x", &li_max_burst_val) ||
                        sscanf(li_ctrl_tok, "%u",   &li_max_burst_val)) {
                        li_programs[channel]->ctrl.max_burst = (int32_t)li_max_burst_val;
                        success = fgets(line, sizeof(line), fp);
                    } else { return -1; }
                } else if (sscanf(line, ".addr %31s ", li_ctrl_tok)) {
                    if (sscanf(li_ctrl_tok, "0x%lx", &li_base_addr_hex)) {
                        li_programs[channel]->ctrl.base_addr = (int64_t)li_base_addr_hex;
                        success = fgets(line, sizeof(line), fp);
                    } else { return -1; }
                } else {
                    state = LI_REPEAT;
                }
                (void)li_nco_phase_hex;
                (void)li_default_I_hex;
                (void)li_default_Q_hex;
                break;
            }

            case LI_REPEAT: {
                uint32_t li_repeat;
                if (sscanf(line, ".repeat %u ", &li_repeat)) {
                    li_programs[channel]->repeat = li_repeat;
                    assert(li_repeat > 0);
                    state = LI_INSN;
                    success = fgets(line, sizeof(line), fp);
                } else { return -1; }
                break;
            }

            case LI_INSN: {
                li_insn_t li_insn;
                i = 0;
                while (success != NULL) {
                    if (li_parse_insn(line, &li_insn) == 0) {
                        if (i >= LI_DEPTH) {
                            printf("Exceeding maximum number of li instructions:\n%s\n", line);
                            return -1;
                        }
                        li_programs[channel]->insns[i] = li_insn;
                        success = fgets(line, sizeof(line), fp);
                        i++;
                    } else {
                        li_programs[channel]->len = i;
                        li_assemble(li_programs[channel]);
                        i = 0;
                        state = PROGRAM;
                        break;
                    }
                }
                break;
            }

            case EX_REPEAT: {
                uint32_t ex_repeat;
                if (sscanf(line, ".repeat %u ", &ex_repeat)) {
                    ex_programs[channel]->repeat = ex_repeat;
                    assert(ex_repeat > 0);
                    state = EX_INSN;
                    success = fgets(line, sizeof(line), fp);
                } else { return -1; }
                break;
            }

            case EX_INSN: {
                ex_insn_t ex_insn;
                i = 0;
                while (success != NULL) {
                    if (ex_parse_insn(line, &ex_insn) == 0) {
                        if (i >= EX_DEPTH) {
                            printf("Exceeding maximum number of ex instructions:\n%s\n", line);
                            return -1;
                        }
                        ex_programs[channel]->insns[i] = ex_insn;
                        success = fgets(line, sizeof(line), fp);
                        i++;
                    } else {
                        ex_programs[channel]->len = i;
                        ex_assemble(ex_programs[channel]);
                        i = 0;
                        state = PROGRAM;
                        break;
                    }
                }
                break;
            }

            case LAUNCH:
                launch_parse(line, *launch);
                state = PROGRAM;
                success = fgets(line, sizeof(line), fp);
                break;
        }
    }

    return 0;
}

uint64_t program_t(dc_program_t *dc_programs[],
                   rf_program_t *rf_programs[],
                   li_program_t *li_programs[],
                   ex_program_t *ex_programs[]) {

    uint64_t max_ns = 0;
    uint64_t cycle_ns = NS_PER_CYCLE;

    for (int i = 0; i < DC_CHANNELS; i++) {
        if (dc_programs[i] == NULL) continue;
        uint64_t t_ns = 0;
        for (unsigned int j = 0; j < dc_programs[i]->len; j++) {
            dc_insn_t *insn = &(dc_programs[i]->insns[j]);
            t_ns += (uint64_t)insn->iters * (uint64_t)insn->hold_cycles * cycle_ns;
        }
        t_ns *= dc_programs[i]->repeat;
        if (t_ns > max_ns) max_ns = t_ns;
    }

    double sample_ns = RF_NS_PER_SAMPLE;
    for (int i = 0; i < RF_CHANNELS; i++) {
        if (rf_programs[i] == NULL) continue;
        double t_ns = 0.0, dt_ns = 0.0;
        for (unsigned int j = 0; j < rf_programs[i]->len; j++) {
            rf_insn_t *insn = &(rf_programs[i]->insns[j]);
            t_ns  += (double)insn->samples  * sample_ns;
            dt_ns += (double)insn->dsamples * sample_ns;
        }
        uint64_t repeat = rf_programs[i]->repeat;
        t_ns  *= (double)repeat;
        dt_ns  = (double)(repeat - 1) * dt_ns * (double)repeat / 2.0;
        t_ns  += dt_ns;
        if ((uint64_t)llround(t_ns) > max_ns) max_ns = (uint64_t)llround(t_ns);
    }

    sample_ns = LI_NS_PER_SAMPLE;
    for (int i = 0; i < LI_CHANNELS; i++) {
        if (li_programs[i] == NULL) continue;
        double t_ns = 0.0, dt_ns = 0.0;
        for (unsigned int j = 0; j < li_programs[i]->len; j++) {
            li_insn_t *insn = &(li_programs[i]->insns[j]);
            t_ns  += (double)((uint64_t)insn->samples  * (uint64_t)insn->stride) * sample_ns;
            dt_ns += (double)((uint64_t)insn->dsamples * (uint64_t)insn->stride) * sample_ns;
        }
        uint64_t repeat = li_programs[i]->repeat;
        t_ns  *= (double)repeat;
        dt_ns  = (double)(repeat - 1) * dt_ns * (double)repeat / 2.0;
        t_ns  += dt_ns;
        if ((uint64_t)llround(t_ns) > max_ns) max_ns = (uint64_t)llround(t_ns);
    }

    sample_ns = EX_NS_PER_SAMPLE;
    for (int i = 0; i < EX_CHANNELS; i++) {
        if (ex_programs[i] == NULL) continue;
        double t_ns = 0.0, dt_ns = 0.0;
        for (unsigned int j = 0; j < ex_programs[i]->len; j++) {
            ex_insn_t *insn = &(ex_programs[i]->insns[j]);
            t_ns  += (double)insn->samples  * sample_ns;
            dt_ns += (double)insn->dsamples * sample_ns;
        }
        uint64_t repeat = ex_programs[i]->repeat;
        t_ns  *= (double)repeat;
        dt_ns  = (double)(repeat - 1) * dt_ns * (double)repeat / 2.0;
        t_ns  += dt_ns;
        if ((uint64_t)llround(t_ns) > max_ns) max_ns = (uint64_t)llround(t_ns);
    }

    return max_ns;
}

int write_sim(dc_program_t *dc_programs[],
              rf_program_t *rf_programs[],
              li_program_t *li_programs[],
              ex_program_t *ex_programs[],
              launch_t *launch) {

    if (sim_connect(SOCKET) != 0) {
        printf("Connection unseccessful\n");
        return -1;
    }

    uint32_t page_size = (1U << 12);

    for (int i = 0; i < DC_CHANNELS; i++) {
        if (dc_programs[i] == NULL) continue;
        uint32_t base = (uint32_t)i * page_size;
        dc_program_t *p = dc_programs[i];
        unsigned int n = p->len;

        sim_sendf("0x%08X 0x%08X\n", base + (DC_BRAM_SEQ_REGS + DC_CTRL_REGS - 1) * 4, 0);
        if (p->ctrl.dvsr         != -1) sim_sendf("0x%08X 0x%08X\n", base + (DC_BRAM_SEQ_REGS + 0) * 4, (uint32_t)p->ctrl.dvsr);
        if (p->ctrl.delay_cycles != -1) sim_sendf("0x%08X 0x%08X\n", base + (DC_BRAM_SEQ_REGS + 1) * 4, (uint32_t)p->ctrl.delay_cycles);
        if (p->ctrl.cs_up_cycles != -1) sim_sendf("0x%08X 0x%08X\n", base + (DC_BRAM_SEQ_REGS + 2) * 4, (uint32_t)p->ctrl.cs_up_cycles);
        if (p->ctrl.ldac_cycles  != -1) sim_sendf("0x%08X 0x%08X\n", base + (DC_BRAM_SEQ_REGS + 3) * 4, (uint32_t)p->ctrl.ldac_cycles);
        sim_sendf("0x%08X 0x%08X\n", base + (DC_BRAM_SEQ_REGS + DC_CTRL_REGS - 1) * 4, 1);

        for (unsigned int k = 0; k < n; k++) {
            sim_sendf("0x%08X 0x%08X\n", base + BRAM_IST_ADDR * 4, k);
            for (unsigned int r = 0; r < DC_REG_PER_INSN; r++)
                sim_sendf("0x%08X 0x%08X\n", base + (BRAM_IST_LO + r) * 4,
                          p->insn_mem[k * DC_REG_PER_INSN + r]);
            sim_sendf("0x%08X 0x%08X\n", base + BRAM_IST_STRB(DC_REG_PER_INSN) * 4, 0);
            sim_sendf("0x%08X 0x%08X\n", base + BRAM_IST_STRB(DC_REG_PER_INSN) * 4, 1);
        }

        for (unsigned int j = 0; j < n; j++) {
            sim_sendf("0x%08X 0x%08X\n", base + BRAM_PCST_ADDR * 4, j);
            sim_sendf("0x%08X 0x%08X\n", base + BRAM_PCST * 4, p->pc_mem[j]);
            sim_sendf("0x%08X 0x%08X\n", base + BRAM_PCST_STRB * 4, 0);
            sim_sendf("0x%08X 0x%08X\n", base + BRAM_PCST_STRB * 4, 1);
        }

        sim_sendf("0x%08X 0x%08X\n", base + BRAM_ITERS(DC_REG_PER_INSN) * 4, p->repeat);
        sim_sendf("0x%08X 0x%08X\n", base + BRAM_DEPTH(DC_REG_PER_INSN) * 4, n - 1);
        sim_sendf("0x%08X 0x%08X\n", base + BRAM_START(DC_REG_PER_INSN) * 4, 0);
        sim_sendf("0x%08X 0x%08X\n", base + BRAM_START(DC_REG_PER_INSN) * 4, 1);
    }

    for (int i = 0; i < RF_CHANNELS; i++) {
        if (rf_programs[i] == NULL) continue;
        uint32_t base = (uint32_t)(DC_CHANNELS + i) * page_size;
        rf_program_t *p = rf_programs[i];
        unsigned int n = p->len;

        sim_sendf("0x%08X 0x%08X\n", base + (RF_BRAM_SEQ_REGS + RF_CTRL_REGS - 1) * 4, 0);
        if (p->ctrl.default_I != -1) sim_sendf("0x%08X 0x%08X\n", base + (RF_BRAM_SEQ_REGS + 0) * 4, (uint32_t)(p->ctrl.default_I & 0x3fff));
        if (p->ctrl.default_Q != -1) sim_sendf("0x%08X 0x%08X\n", base + (RF_BRAM_SEQ_REGS + 1) * 4, (uint32_t)(p->ctrl.default_Q & 0x3fff));
        sim_sendf("0x%08X 0x%08X\n", base + (RF_BRAM_SEQ_REGS + RF_CTRL_REGS - 1) * 4, 1);

        for (unsigned int k = 0; k < n; k++) {
            sim_sendf("0x%08X 0x%08X\n", base + BRAM_IST_ADDR * 4, k);
            for (unsigned int r = 0; r < RF_REG_PER_INSN; r++)
                sim_sendf("0x%08X 0x%08X\n", base + (BRAM_IST_LO + r) * 4,
                          p->insn_mem[k * RF_REG_PER_INSN + r]);
            sim_sendf("0x%08X 0x%08X\n", base + BRAM_IST_STRB(RF_REG_PER_INSN) * 4, 0);
            sim_sendf("0x%08X 0x%08X\n", base + BRAM_IST_STRB(RF_REG_PER_INSN) * 4, 1);
        }

        for (unsigned int j = 0; j < n; j++) {
            sim_sendf("0x%08X 0x%08X\n", base + BRAM_PCST_ADDR * 4, j);
            sim_sendf("0x%08X 0x%08X\n", base + BRAM_PCST * 4, p->pc_mem[j]);
            sim_sendf("0x%08X 0x%08X\n", base + BRAM_PCST_STRB * 4, 0);
            sim_sendf("0x%08X 0x%08X\n", base + BRAM_PCST_STRB * 4, 1);
        }

        sim_sendf("0x%08X 0x%08X\n", base + BRAM_ITERS(RF_REG_PER_INSN) * 4, p->repeat);
        sim_sendf("0x%08X 0x%08X\n", base + BRAM_DEPTH(RF_REG_PER_INSN) * 4, n - 1);
        sim_sendf("0x%08X 0x%08X\n", base + BRAM_START(RF_REG_PER_INSN) * 4, 0);
        sim_sendf("0x%08X 0x%08X\n", base + BRAM_START(RF_REG_PER_INSN) * 4, 1);
    }

    for (int i = 0; i < LI_CHANNELS; i++) {
        if (li_programs[i] == NULL) continue;
        uint32_t base = (uint32_t)(DC_CHANNELS + RF_CHANNELS + i) * page_size;
        li_program_t *p = li_programs[i];
        unsigned int n = p->len;

        sim_sendf("0x%08X 0x%08X\n", base + (LI_BRAM_SEQ_REGS + LI_CTRL_REGS - 1) * 4, 0);
        if (p->ctrl.default_I != -1) sim_sendf("0x%08X 0x%08X\n", base + (LI_BRAM_SEQ_REGS + 0) * 4, (uint32_t)(p->ctrl.default_I & 0x3fff));
        if (p->ctrl.default_Q != -1) sim_sendf("0x%08X 0x%08X\n", base + (LI_BRAM_SEQ_REGS + 1) * 4, (uint32_t)(p->ctrl.default_Q & 0x3fff));
        if (p->ctrl.max_burst != -1) sim_sendf("0x%08X 0x%08X\n", base + (LI_BRAM_SEQ_REGS + 2) * 4, (uint32_t)(p->ctrl.max_burst & 0xff));
        if (p->ctrl.base_addr != -1) {
            sim_sendf("0x%08X 0x%08X\n", base + (LI_BRAM_SEQ_REGS + 3) * 4, (uint32_t)(((uint64_t)p->ctrl.base_addr >> 32) & 0x1ffff));
            sim_sendf("0x%08X 0x%08X\n", base + (LI_BRAM_SEQ_REGS + 4) * 4, (uint32_t)((uint64_t)p->ctrl.base_addr & 0xffffffff));
        }
        sim_sendf("0x%08X 0x%08X\n", base + (LI_BRAM_SEQ_REGS + LI_CTRL_REGS - 1) * 4, 1);

        for (unsigned int k = 0; k < n; k++) {
            sim_sendf("0x%08X 0x%08X\n", base + BRAM_IST_ADDR * 4, k);
            for (unsigned int r = 0; r < LI_REG_PER_INSN; r++)
                sim_sendf("0x%08X 0x%08X\n", base + (BRAM_IST_LO + r) * 4,
                          p->insn_mem[k * LI_REG_PER_INSN + r]);
            sim_sendf("0x%08X 0x%08X\n", base + BRAM_IST_STRB(LI_REG_PER_INSN) * 4, 0);
            sim_sendf("0x%08X 0x%08X\n", base + BRAM_IST_STRB(LI_REG_PER_INSN) * 4, 1);
        }

        for (unsigned int j = 0; j < n; j++) {
            sim_sendf("0x%08X 0x%08X\n", base + BRAM_PCST_ADDR * 4, j);
            sim_sendf("0x%08X 0x%08X\n", base + BRAM_PCST * 4, p->pc_mem[j]);
            sim_sendf("0x%08X 0x%08X\n", base + BRAM_PCST_STRB * 4, 0);
            sim_sendf("0x%08X 0x%08X\n", base + BRAM_PCST_STRB * 4, 1);
        }

        sim_sendf("0x%08X 0x%08X\n", base + BRAM_ITERS(LI_REG_PER_INSN) * 4, p->repeat);
        sim_sendf("0x%08X 0x%08X\n", base + BRAM_DEPTH(LI_REG_PER_INSN) * 4, n - 1);
        sim_sendf("0x%08X 0x%08X\n", base + BRAM_START(LI_REG_PER_INSN) * 4, 0);
        sim_sendf("0x%08X 0x%08X\n", base + BRAM_START(LI_REG_PER_INSN) * 4, 1);
    }

    for (int i = 0; i < EX_CHANNELS; i++) {
        if (ex_programs[i] == NULL) continue;
        uint32_t base = (uint32_t)(DC_CHANNELS + RF_CHANNELS + LI_CHANNELS + i) * page_size;
        ex_program_t *p = ex_programs[i];
        unsigned int n = p->len;

        for (unsigned int k = 0; k < n; k++) {
            sim_sendf("0x%08X 0x%08X\n", base + BRAM_IST_ADDR * 4, k);
            for (unsigned int r = 0; r < EX_REG_PER_INSN; r++)
                sim_sendf("0x%08X 0x%08X\n", base + (BRAM_IST_LO + r) * 4,
                          p->insn_mem[k * EX_REG_PER_INSN + r]);
            sim_sendf("0x%08X 0x%08X\n", base + BRAM_IST_STRB(EX_REG_PER_INSN) * 4, 0);
            sim_sendf("0x%08X 0x%08X\n", base + BRAM_IST_STRB(EX_REG_PER_INSN) * 4, 1);
        }

        for (unsigned int j = 0; j < n; j++) {
            sim_sendf("0x%08X 0x%08X\n", base + BRAM_PCST_ADDR * 4, j);
            sim_sendf("0x%08X 0x%08X\n", base + BRAM_PCST * 4, p->pc_mem[j]);
            sim_sendf("0x%08X 0x%08X\n", base + BRAM_PCST_STRB * 4, 0);
            sim_sendf("0x%08X 0x%08X\n", base + BRAM_PCST_STRB * 4, 1);
        }

        sim_sendf("0x%08X 0x%08X\n", base + BRAM_ITERS(EX_REG_PER_INSN) * 4, p->repeat);
        sim_sendf("0x%08X 0x%08X\n", base + BRAM_DEPTH(EX_REG_PER_INSN) * 4, n - 1);
        sim_sendf("0x%08X 0x%08X\n", base + BRAM_START(EX_REG_PER_INSN) * 4, 0);
        sim_sendf("0x%08X 0x%08X\n", base + BRAM_START(EX_REG_PER_INSN) * 4, 1);
    }

    if (launch != NULL) {
        uint32_t base = (uint32_t)(DC_CHANNELS + RF_CHANNELS + LI_CHANNELS + EX_CHANNELS) * page_size;
        sim_sendf("0x%08X 0x%08X\n", base + (LAUNCH_TOTAL_REGS - 1) * 4, 0);
        sim_sendf("0x%08X 0x%08X\n", base,      launch->dc_chmask);
        sim_sendf("0x%08X 0x%08X\n", base +  4, launch->rf_chmask);
        sim_sendf("0x%08X 0x%08X\n", base +  8, launch->li_chmask);
        sim_sendf("0x%08X 0x%08X\n", base + 12, launch->ex_chmask);
        sim_sendf("0x%08X 0x%08X\n", base + 16, launch->use_trigger);
        sim_sendf("0x%08X 0x%08X\n", base + 20, launch->iters);
        sim_sendf("0x%08X 0x%08X\n", base + (LAUNCH_TOTAL_REGS - 1) * 4, 1);
    }

    if (launch != NULL)
        sim_sendf("launch %"PRIu64"\n", program_t(dc_programs, rf_programs, li_programs, ex_programs) + 1000);
    else
        sim_sendf("run %"PRIu64"\n",    program_t(dc_programs, rf_programs, li_programs, ex_programs) + 1000);

    sim_close();
    return 0;
}

/*
 * Bin file format (text):
 *
 *   dc<N>
 *   repeat <uint32>
 *   len <uint32>
 *   dvsr <int32>
 *   delay_cycles <int32>
 *   cs_up_cycles <int32>
 *   ldac_cycles <int32>
 *   imem
 *   0x<hex>    (len * DC_REG_PER_INSN words)
 *   ...
 *   pcmem
 *   0x<hex>    (len words)
 *   ...
 *
 *   rf<N>
 *   repeat <uint32>
 *   len <uint32>
 *   nco_freq <int64 hex>
 *   default_I <int32>
 *   default_Q <int32>
 *   imem / pcmem sections (same pattern)
 *
 *   li<N>
 *   repeat <uint32>
 *   len <uint32>
 *   nco_freq <int64 hex>
 *   nco_phase <int32>
 *   default_I <int32>
 *   default_Q <int32>
 *   max_burst <int32>
 *   base_addr <int64 hex>
 *   imem / pcmem sections
 *
 *   ex<N>
 *   repeat <uint32>
 *   len <uint32>
 *   imem / pcmem sections
 *
 *   launch
 *   0x<dc_chmask>
 *   0x<rf_chmask>
 *   0x<li_chmask>
 *   0x<ex_chmask>
 *   0x<use_trigger>
 *   0x<iters>
 */
void write_bin(dc_program_t *dc_programs[],
               rf_program_t *rf_programs[],
               li_program_t *li_programs[],
               ex_program_t *ex_programs[],
               launch_t *launch,
               FILE *op) {

    for (int i = 0; i < DC_CHANNELS; i++) {
        if (dc_programs[i] == NULL) continue;
        dc_program_t *p = dc_programs[i];
        unsigned int n = p->len;

        fprintf(op, "dc%d\n", i);
        fprintf(op, "repeat %"PRIu32"\n", p->repeat);
        fprintf(op, "len %u\n", n);
        fprintf(op, "dvsr %"PRId32"\n",         p->ctrl.dvsr);
        fprintf(op, "delay_cycles %"PRId32"\n", p->ctrl.delay_cycles);
        fprintf(op, "cs_up_cycles %"PRId32"\n", p->ctrl.cs_up_cycles);
        fprintf(op, "ldac_cycles %"PRId32"\n",  p->ctrl.ldac_cycles);
        fprintf(op, "imem\n");
        for (unsigned int k = 0; k < n * DC_REG_PER_INSN; k++)
            fprintf(op, "0x%08"PRIX32"\n", p->insn_mem[k]);
        fprintf(op, "pcmem\n");
        for (unsigned int k = 0; k < n; k++)
            fprintf(op, "0x%08"PRIX32"\n", p->pc_mem[k]);
        fprintf(op, "\n");
    }

    for (int i = 0; i < RF_CHANNELS; i++) {
        if (rf_programs[i] == NULL) continue;
        rf_program_t *p = rf_programs[i];
        unsigned int n = p->len;

        fprintf(op, "rf%d\n", i);
        fprintf(op, "repeat %"PRIu32"\n", p->repeat);
        fprintf(op, "len %u\n", n);
        fprintf(op, "nco_freq 0x%016"PRIX64"\n", (uint64_t)p->nco_freq);
        fprintf(op, "default_I %"PRId32"\n", p->ctrl.default_I);
        fprintf(op, "default_Q %"PRId32"\n", p->ctrl.default_Q);
        fprintf(op, "imem\n");
        for (unsigned int k = 0; k < n * RF_REG_PER_INSN; k++)
            fprintf(op, "0x%08"PRIX32"\n", p->insn_mem[k]);
        fprintf(op, "pcmem\n");
        for (unsigned int k = 0; k < n; k++)
            fprintf(op, "0x%08"PRIX32"\n", p->pc_mem[k]);
        fprintf(op, "\n");
    }

    for (int i = 0; i < LI_CHANNELS; i++) {
        if (li_programs[i] == NULL) continue;
        li_program_t *p = li_programs[i];
        unsigned int n = p->len;

        fprintf(op, "li%d\n", i);
        fprintf(op, "repeat %"PRIu32"\n", p->repeat);
        fprintf(op, "len %u\n", n);
        fprintf(op, "nco_freq 0x%016"PRIX64"\n", (uint64_t)p->ctrl.nco_freq);
        fprintf(op, "nco_phase %"PRId32"\n",      p->ctrl.nco_phase);
        fprintf(op, "default_I %"PRId32"\n",      p->ctrl.default_I);
        fprintf(op, "default_Q %"PRId32"\n",      p->ctrl.default_Q);
        fprintf(op, "max_burst %"PRId32"\n",      p->ctrl.max_burst);
        fprintf(op, "base_addr 0x%016"PRIX64"\n", (uint64_t)p->ctrl.base_addr);
        fprintf(op, "imem\n");
        for (unsigned int k = 0; k < n * LI_REG_PER_INSN; k++)
            fprintf(op, "0x%08"PRIX32"\n", p->insn_mem[k]);
        fprintf(op, "pcmem\n");
        for (unsigned int k = 0; k < n; k++)
            fprintf(op, "0x%08"PRIX32"\n", p->pc_mem[k]);
        fprintf(op, "\n");
    }

    for (int i = 0; i < EX_CHANNELS; i++) {
        if (ex_programs[i] == NULL) continue;
        ex_program_t *p = ex_programs[i];
        unsigned int n = p->len;

        fprintf(op, "ex%d\n", i);
        fprintf(op, "repeat %"PRIu32"\n", p->repeat);
        fprintf(op, "len %u\n", n);
        fprintf(op, "imem\n");
        for (unsigned int k = 0; k < n * EX_REG_PER_INSN; k++)
            fprintf(op, "0x%08"PRIX32"\n", p->insn_mem[k]);
        fprintf(op, "pcmem\n");
        for (unsigned int k = 0; k < n; k++)
            fprintf(op, "0x%08"PRIX32"\n", p->pc_mem[k]);
        fprintf(op, "\n");
    }

    if (launch != NULL) {
        fprintf(op, "launch\n");
        fprintf(op, "0x%08"PRIX32"\n", launch->dc_chmask);
        fprintf(op, "0x%08"PRIX32"\n", launch->rf_chmask);
        fprintf(op, "0x%08"PRIX32"\n", launch->li_chmask);
        fprintf(op, "0x%08"PRIX32"\n", launch->ex_chmask);
        fprintf(op, "0x%08"PRIX32"\n", launch->use_trigger);
        fprintf(op, "0x%08"PRIX32"\n", launch->iters);
        fprintf(op, "\n");
    }
}
