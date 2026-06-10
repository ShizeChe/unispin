#include "common.h"
#include "dc.h"
#include "rf.h"
#include "li.h"
#include "ex.h"
#include "launch.h"
#include "simcli.h"
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>
#include <math.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>
#include <termios.h>
#include <inttypes.h>
#include <sys/mman.h>

static int line_empty(char *s) {
    while (isspace((unsigned char)*s))
        s++;
    return *s == '\0' || *s == ';';
}

static int assemble(FILE *fp, 
                    dc_program_t *dc_programs[],
                    rf_program_t *rf_programs[],
                    li_program_t *li_programs[],
                    ex_program_t *ex_programs[],
                    launch_t **launch) {

    char line[256] = {0};

    typedef enum {
        PROGRAM,
        DC_CTRL,
        DC_REPEAT,
        DC_INSN,
        RF_CTRL,
        RF_REPEAT,
        RF_INSN,
        LI_CTRL,
        LI_REPEAT,
        LI_INSN,
        EX_REPEAT,
        EX_INSN,
        LAUNCH
    } state_t;

    state_t state = PROGRAM;

    char tmp[10];
    char *success = tmp;

    int i;

    while (success != NULL) {

        if (line_empty(line)) {
            success = fgets(line, sizeof(line), fp);
            continue;
        }

        switch (state) {

            case PROGRAM:

                uint32_t channel;

                if (sscanf(line, ".program dc%u ", &channel)){

                    dc_programs[channel] = (dc_program_t *)calloc(1, sizeof(dc_program_t));
                    dc_programs[channel]->ctrl.dvsr = -1;
                    dc_programs[channel]->ctrl.delay_cycles = -1;
                    dc_programs[channel]->ctrl.cs_up_cycles = -1;
                    dc_programs[channel]->ctrl.ldac_cycles = -1;

                    state = DC_CTRL;
                    success = fgets(line, sizeof(line), fp);

                } else if (sscanf(line, ".program rf%u ", &channel)) {

                    rf_programs[channel] = (rf_program_t *)calloc(1, sizeof(rf_program_t));
                    rf_programs[channel]->nco_freq = -1;
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

            case DC_CTRL:

                int dc_dvsr;
                int dc_delay_cycles;
                int dc_cs_up_cycles;
                int dc_ldac_cycles;

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

            case DC_REPEAT:

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

            case DC_INSN:

                dc_insn_t dc_insn;
                i = 0;

                while (success != NULL) {

                    if (dc_parse_insn(line, &dc_insn) == 0) {

                        if (i >= DC_DEPTH) {
                            printf("Exceeding maximum number of dc instructions:\n");
                            printf("%s\n", line);
                            return -1;
                        } else {
                            dc_programs[channel]->insns[i] = dc_insn;
                            success = fgets(line, sizeof(line), fp);
                            i++;
                        }

                    } else {
                        dc_programs[channel]->len = i;
                        dc_assemble(dc_programs[channel]);
                        i = 0;
                        state = PROGRAM;
                        break;
                    }

                }

                break;

            case RF_CTRL:

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

                    } else {
                        return -1;
                    }

                } else if (sscanf(line, ".defI %31s ", rf_ctrl_tok)) {

                    if (sscanf(rf_ctrl_tok, "0x%x", &rf_default_I_hex)) {

                        rf_programs[channel]->ctrl.default_I = (int32_t)rf_default_I_hex;

                        success = fgets(line, sizeof(line), fp);

                    } else if (sscanf(rf_ctrl_tok, "%lf", &rf_default_I)) {

                        rf_programs[channel]->ctrl.default_I = real2twos(-1, 
                            1, RF_IQ_BITS, rf_default_I, 1);

                        success = fgets(line, sizeof(line), fp);

                    } else {
                        return -1;
                    }

                } else if (sscanf(line, ".defQ %31s ", rf_ctrl_tok)) {

                    if (sscanf(rf_ctrl_tok, "0x%x", &rf_default_Q_hex)) {

                        rf_programs[channel]->ctrl.default_Q = (int32_t)rf_default_Q_hex;

                        success = fgets(line, sizeof(line), fp);

                    } else if (sscanf(rf_ctrl_tok, "%lf", &rf_default_Q)) {

                        rf_programs[channel]->ctrl.default_Q = real2twos(-1, 
                            1, RF_IQ_BITS, rf_default_I, 1);

                        success = fgets(line, sizeof(line), fp);

                    } else {
                        return -1;
                    }

                } else {
                    state = RF_REPEAT;
                }
                
                break;

            case RF_REPEAT:

                uint32_t rf_repeat;

                if (sscanf(line, ".repeat %u ", &rf_repeat)) {

                    rf_programs[channel]->repeat = rf_repeat;
                    assert(rf_repeat > 0);

                    state = RF_INSN;
                    success = fgets(line, sizeof(line), fp);

                } else {
                    return -1;
                }

                break;

            case RF_INSN:

                assert(rf_programs[channel]->nco_freq != -1);

                rf_insn_t rf_insn;
                i = 0;
                long double rf_fnco_hz = twos2real(RF_FNCO_MIN, RF_FNCO_MAX,
                    RF_FNCO_BITS, rf_programs[channel]->nco_freq);

                while (success != NULL) {

                    if (rf_parse_insn(line, &rf_insn, rf_fnco_hz) == 0) {

                        if (i >= RF_DEPTH) {
                            printf("Exceeding maximum number of rf instructions:\n");
                            printf("%s\n", line);
                            return -1;
                        } else {
                            rf_programs[channel]->insns[i] = rf_insn;
                            success = fgets(line, sizeof(line), fp);
                            i++;
                        }

                    } else {
                        rf_programs[channel]->len = i;
                        rf_assemble(rf_programs[channel]);
                        i = 0;
                        state = PROGRAM;
                        break;
                    }

                }

                break;

            case LI_CTRL:

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

                    } else {
                        return -1;
                    }

                } else if (sscanf(line, ".pnco %31s ", li_ctrl_tok)) {

                    if (sscanf(li_ctrl_tok, "0x%x", &li_nco_phase_hex)) {

                        li_programs[channel]->ctrl.nco_phase = (int32_t)li_nco_phase_hex;

                        success = fgets(line, sizeof(line), fp);

                    } else if (sscanf(li_ctrl_tok, "%lf", &li_nco_phase)) {

                        li_programs[channel]->ctrl.nco_phase = real2twos(LI_PNCO_MIN,
                            LI_PNCO_MAX, LI_PNCO_BITS, li_nco_phase, 1);

                        success = fgets(line, sizeof(line), fp);

                    } else {
                        return -1;
                    }

                } else if (sscanf(line, ".defI %31s ", li_ctrl_tok)) {

                    if (sscanf(li_ctrl_tok, "0x%x", &li_default_I_hex)) {

                        li_programs[channel]->ctrl.default_I = (int32_t)li_default_I_hex;

                        success = fgets(line, sizeof(line), fp);

                    } else if (sscanf(li_ctrl_tok, "%lf", &li_default_I)) {

                        li_programs[channel]->ctrl.default_I = real2twos(-1,
                            1, LI_IQ_BITS, li_default_I, 1);

                        success = fgets(line, sizeof(line), fp);

                    } else {
                        return -1;
                    }

                } else if (sscanf(line, ".defQ %31s ", li_ctrl_tok)) {

                    if (sscanf(li_ctrl_tok, "0x%x", &li_default_Q_hex)) {

                        li_programs[channel]->ctrl.default_Q = (int32_t)li_default_Q_hex;

                        success = fgets(line, sizeof(line), fp);

                    } else if (sscanf(li_ctrl_tok, "%lf", &li_default_Q)) {

                        li_programs[channel]->ctrl.default_Q = real2twos(-1,
                            1, LI_IQ_BITS, li_default_Q, 1);

                        success = fgets(line, sizeof(line), fp);

                    } else {
                        return -1;
                    }

                } else if (sscanf(line, ".maxb %31s ", li_ctrl_tok)) {

                    if (sscanf(li_ctrl_tok, "0x%x", &li_max_burst_val) ||
                        sscanf(li_ctrl_tok, "%u",   &li_max_burst_val)) {

                        li_programs[channel]->ctrl.max_burst = (int32_t)li_max_burst_val;

                        success = fgets(line, sizeof(line), fp);

                    } else {
                        return -1;
                    }

                } else if (sscanf(line, ".addr %31s ", li_ctrl_tok)) {

                    if (sscanf(li_ctrl_tok, "0x%lx", &li_base_addr_hex)) {

                        li_programs[channel]->ctrl.base_addr = (int64_t)li_base_addr_hex;

                        success = fgets(line, sizeof(line), fp);

                    } else {
                        return -1;
                    }

                } else {
                    state = LI_REPEAT;
                }

                break;

            case LI_REPEAT:

                uint32_t li_repeat;

                if (sscanf(line, ".repeat %u ", &li_repeat)) {

                    li_programs[channel]->repeat = li_repeat;
                    assert(li_repeat > 0);

                    state = LI_INSN;
                    success = fgets(line, sizeof(line), fp);

                } else {
                    return -1;
                }

                break;

            case LI_INSN:

                li_insn_t li_insn;
                i = 0;

                while (success != NULL) {

                    if (li_parse_insn(line, &li_insn) == 0) {

                        if (i >= LI_DEPTH) {
                            printf("Exceeding maximum number of li instructions:\n");
                            printf("%s\n", line);
                            return -1;
                        } else {
                            li_programs[channel]->insns[i] = li_insn;
                            success = fgets(line, sizeof(line), fp);
                            i++;
                        }

                    } else {
                        li_programs[channel]->len = i;
                        li_assemble(li_programs[channel]);
                        i = 0;
                        state = PROGRAM;
                        break;
                    }

                }

                break;

            case EX_REPEAT:

                uint32_t ex_repeat;

                if (sscanf(line, ".repeat %u ", &ex_repeat)) {

                    ex_programs[channel]->repeat = ex_repeat;
                    assert(ex_repeat > 0);
                    state = EX_INSN;

                    success = fgets(line, sizeof(line), fp);

                } else {
                    return -1;
                }

                break;

            case EX_INSN:

                ex_insn_t ex_insn;
                i = 0;

                while (success != NULL) {

                    if (ex_parse_insn(line, &ex_insn) == 0) {

                        if (i >= EX_DEPTH) {
                            printf("Exceeding maximum number of ex instructions:\n");
                            printf("%s\n", line);
                            return -1;
                        } else {
                            ex_programs[channel]->insns[i] = ex_insn;
                            success = fgets(line, sizeof(line), fp);
                            i++;
                        }

                    } else {
                        ex_programs[channel]->len = i;
                        ex_assemble(ex_programs[channel]);
                        i = 0;
                        state = PROGRAM;
                        break;
                    }

                }

                break;

            case LAUNCH:

                launch_parse(line, *launch);
                state = PROGRAM;
                success = fgets(line, sizeof(line), fp);
                break;

        }
    }

    return 0;

}

static uint64_t program_t(dc_program_t *dc_programs[],
                          rf_program_t *rf_programs[],
                          li_program_t *li_programs[],
                          ex_program_t *ex_programs[]) {

    uint64_t max_ns = 0;
    uint64_t cycle_ns = NS_PER_CYCLE;

    for (int i = 0; i < DC_CHANNELS; i++) {

        if (dc_programs[i] != NULL) {

            uint64_t t_ns = 0;

            for (unsigned int j = 0; j < dc_programs[i]->len; j++) {

                dc_insn_t *insn = &(dc_programs[i]->insns[j]);
                uint64_t iters = (uint64_t)insn->iters;
                uint64_t hold_cycles = (uint64_t)insn->hold_cycles;

                t_ns += iters * hold_cycles * cycle_ns;

            }

            uint64_t repeat = dc_programs[i]->repeat;
            t_ns *= repeat;

            if (t_ns > max_ns)
                max_ns = t_ns;

        }

    }

    double sample_ns = RF_NS_PER_SAMPLE;

    for (int i = 0; i < RF_CHANNELS; i++) {

        if (rf_programs[i] != NULL) {

            double t_ns = 0.0;
            double dt_ns = 0.0;

            for (unsigned int j = 0; j < rf_programs[i]->len; j++) {

                rf_insn_t *insn = &(rf_programs[i]->insns[j]);
                uint64_t samples = (uint64_t)insn->samples;
                uint64_t dsamples = (uint64_t)insn->dsamples;

                t_ns += ((double)samples) * sample_ns;
                dt_ns += ((double)dsamples) * sample_ns;

            }

            uint64_t repeat = rf_programs[i]->repeat;
            t_ns *= (double)repeat;
            dt_ns = ((double)(repeat - 1)) * dt_ns * ((double)repeat) / 2.0;
            t_ns += dt_ns;

            if (((uint64_t)llround(t_ns)) > max_ns)
                max_ns = ((uint64_t)llround(t_ns));

        }

    }

    sample_ns = LI_NS_PER_SAMPLE;

    for (int i = 0; i < LI_CHANNELS; i++) {

        if (li_programs[i] != NULL) {

            double t_ns = 0.0;
            double dt_ns = 0.0;

            for (unsigned int j = 0; j < li_programs[i]->len; j++) {

                li_insn_t *insn = &(li_programs[i]->insns[j]);
                uint64_t samples = ((uint64_t)insn->samples) * ((uint64_t)insn->stride);
                uint64_t dsamples = ((uint64_t)insn->dsamples) * ((uint64_t)insn->stride);

                t_ns += ((double)samples) * sample_ns;
                dt_ns += ((double)dsamples) * sample_ns;

            }

            uint64_t repeat = li_programs[i]->repeat;
            t_ns *= (double)repeat;
            dt_ns = ((double)(repeat - 1)) * dt_ns * ((double)repeat) / 2.0;
            t_ns += dt_ns;

            if (((uint64_t)llround(t_ns)) > max_ns)
                max_ns = ((uint64_t)llround(t_ns));

        }

    }

    sample_ns = EX_NS_PER_SAMPLE;

    for (int i = 0; i < EX_CHANNELS; i++) {

        if (ex_programs[i] != NULL) {

            double t_ns = 0.0;
            double dt_ns = 0.0;

            for (unsigned int j = 0; j < ex_programs[i]->len; j++) {

                ex_insn_t *insn = &(ex_programs[i]->insns[j]);
                uint64_t samples = (uint64_t)insn->samples;
                uint64_t dsamples = (uint64_t)insn->dsamples;

                t_ns += ((double)samples) * sample_ns;
                dt_ns += ((double)dsamples) * sample_ns;

            }

            uint64_t repeat = li_programs[i]->repeat;
            t_ns *= (double)repeat;
            dt_ns = ((double)(repeat - 1)) * dt_ns * ((double)repeat) / 2.0;
            t_ns += dt_ns;

            if (((uint64_t)llround(t_ns)) > max_ns)
                max_ns = ((uint64_t)llround(t_ns));

        }

    }

    return max_ns;

}

static int write_sim(dc_program_t *dc_programs[], 
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

        if (dc_programs[i] != NULL) {

            uint32_t base = i * page_size;
            unsigned int n = dc_programs[i]->len;

            for (unsigned int k = 0; k < n; k++) {
                sim_sendf("0x%08X 0x%08X\n", base + BRAM_IST_ADDR * 4, k);
                for (unsigned int r = 0; r < DC_REG_PER_INSN; r++)
                    sim_sendf("0x%08X 0x%08X\n", base + (BRAM_IST_LO + r) * 4,
                              dc_programs[i]->seq_regs[k * DC_REG_PER_INSN + r]);
                sim_sendf("0x%08X 0x%08X\n", base + BRAM_IST_STRB(DC_REG_PER_INSN) * 4, 0);
                sim_sendf("0x%08X 0x%08X\n", base + BRAM_IST_STRB(DC_REG_PER_INSN) * 4, 1);
            }

            for (unsigned int j = 0; j < n; j++) {
                sim_sendf("0x%08X 0x%08X\n", base + BRAM_PCST_ADDR * 4, j);
                sim_sendf("0x%08X 0x%08X\n", base + BRAM_PCST * 4, j);
                sim_sendf("0x%08X 0x%08X\n", base + BRAM_PCST_STRB * 4, 0);
                sim_sendf("0x%08X 0x%08X\n", base + BRAM_PCST_STRB * 4, 1);
            }

            sim_sendf("0x%08X 0x%08X\n", base + BRAM_ITERS(DC_REG_PER_INSN) * 4, dc_programs[i]->repeat);
            sim_sendf("0x%08X 0x%08X\n", base + BRAM_DEPTH(DC_REG_PER_INSN) * 4, n - 1);
            sim_sendf("0x%08X 0x%08X\n", base + BRAM_START(DC_REG_PER_INSN) * 4, 0);
            sim_sendf("0x%08X 0x%08X\n", base + BRAM_START(DC_REG_PER_INSN) * 4, 1);

            sim_sendf("0x%08X 0x%08X\n", base + (DC_BRAM_SEQ_REGS + DC_CTRL_REGS - 1) * 4, 0);
            for (unsigned int j = 0; j < DC_CTRL_REGS; j++) {
                if (dc_programs[i]->ctrl_regs[j] != -1)
                    sim_sendf("0x%08X 0x%08X\n", base + (DC_BRAM_SEQ_REGS + j) * 4,
                              dc_programs[i]->ctrl_regs[j]);
            }

        }

    }

    for (int i = 0; i < RF_CHANNELS; i++) {

        if (rf_programs[i] != NULL) {

            uint32_t base = (DC_CHANNELS + i) * page_size;
            unsigned int n = rf_programs[i]->len;

            for (unsigned int k = 0; k < n; k++) {
                sim_sendf("0x%08X 0x%08X\n", base + BRAM_IST_ADDR * 4, k);
                for (unsigned int r = 0; r < RF_REG_PER_INSN; r++)
                    sim_sendf("0x%08X 0x%08X\n", base + (BRAM_IST_LO + r) * 4,
                              rf_programs[i]->seq_regs[k * RF_REG_PER_INSN + r]);
                sim_sendf("0x%08X 0x%08X\n", base + BRAM_IST_STRB(RF_REG_PER_INSN) * 4, 0);
                sim_sendf("0x%08X 0x%08X\n", base + BRAM_IST_STRB(RF_REG_PER_INSN) * 4, 1);
            }

            for (unsigned int j = 0; j < n; j++) {
                sim_sendf("0x%08X 0x%08X\n", base + BRAM_PCST_ADDR * 4, j);
                sim_sendf("0x%08X 0x%08X\n", base + BRAM_PCST * 4, j);
                sim_sendf("0x%08X 0x%08X\n", base + BRAM_PCST_STRB * 4, 0);
                sim_sendf("0x%08X 0x%08X\n", base + BRAM_PCST_STRB * 4, 1);
            }

            sim_sendf("0x%08X 0x%08X\n", base + BRAM_ITERS(RF_REG_PER_INSN) * 4, rf_programs[i]->repeat);
            sim_sendf("0x%08X 0x%08X\n", base + BRAM_DEPTH(RF_REG_PER_INSN) * 4, n - 1);
            sim_sendf("0x%08X 0x%08X\n", base + BRAM_START(RF_REG_PER_INSN) * 4, 0);
            sim_sendf("0x%08X 0x%08X\n", base + BRAM_START(RF_REG_PER_INSN) * 4, 1);

            sim_sendf("0x%08X 0x%08X\n", base + (RF_BRAM_SEQ_REGS + RF_CTRL_REGS - 1) * 4, 0);
            for (unsigned int j = 0; j < RF_CTRL_REGS; j++) {
                if (rf_programs[i]->ctrl_regs[j] != -1)
                    sim_sendf("0x%08X 0x%08X\n", base + (RF_BRAM_SEQ_REGS + j) * 4,
                              rf_programs[i]->ctrl_regs[j]);
            }

        }

    }

    for (int i = 0; i < LI_CHANNELS; i++) {

        if (li_programs[i] != NULL) {

            uint32_t base = (DC_CHANNELS + RF_CHANNELS + i) * page_size;
            unsigned int n = li_programs[i]->len;

            for (unsigned int k = 0; k < n; k++) {
                sim_sendf("0x%08X 0x%08X\n", base + BRAM_IST_ADDR * 4, k);
                for (unsigned int r = 0; r < LI_REG_PER_INSN; r++)
                    sim_sendf("0x%08X 0x%08X\n", base + (BRAM_IST_LO + r) * 4,
                              li_programs[i]->seq_regs[k * LI_REG_PER_INSN + r]);
                sim_sendf("0x%08X 0x%08X\n", base + BRAM_IST_STRB(LI_REG_PER_INSN) * 4, 0);
                sim_sendf("0x%08X 0x%08X\n", base + BRAM_IST_STRB(LI_REG_PER_INSN) * 4, 1);
            }

            for (unsigned int j = 0; j < n; j++) {
                sim_sendf("0x%08X 0x%08X\n", base + BRAM_PCST_ADDR * 4, j);
                sim_sendf("0x%08X 0x%08X\n", base + BRAM_PCST * 4, j);
                sim_sendf("0x%08X 0x%08X\n", base + BRAM_PCST_STRB * 4, 0);
                sim_sendf("0x%08X 0x%08X\n", base + BRAM_PCST_STRB * 4, 1);
            }

            sim_sendf("0x%08X 0x%08X\n", base + BRAM_ITERS(LI_REG_PER_INSN) * 4, li_programs[i]->repeat);
            sim_sendf("0x%08X 0x%08X\n", base + BRAM_DEPTH(LI_REG_PER_INSN) * 4, n - 1);
            sim_sendf("0x%08X 0x%08X\n", base + BRAM_START(LI_REG_PER_INSN) * 4, 0);
            sim_sendf("0x%08X 0x%08X\n", base + BRAM_START(LI_REG_PER_INSN) * 4, 1);

            sim_sendf("0x%08X 0x%08X\n", base + (LI_BRAM_SEQ_REGS + LI_CTRL_REGS - 1) * 4, 0);
            for (unsigned int j = 0; j < LI_CTRL_REGS; j++) {
                if (li_programs[i]->ctrl_regs[j] != -1)
                    sim_sendf("0x%08X 0x%08X\n", base + (LI_BRAM_SEQ_REGS + j) * 4,
                              li_programs[i]->ctrl_regs[j]);
            }

        }

    }

    for (int i = 0; i < EX_CHANNELS; i++) {

        if (ex_programs[i] != NULL) {

            uint32_t base = (DC_CHANNELS + RF_CHANNELS + LI_CHANNELS + i) * page_size;
            unsigned int n = ex_programs[i]->len;

            for (unsigned int k = 0; k < n; k++) {
                sim_sendf("0x%08X 0x%08X\n", base + BRAM_IST_ADDR * 4, k);
                for (unsigned int r = 0; r < EX_REG_PER_INSN; r++)
                    sim_sendf("0x%08X 0x%08X\n", base + (BRAM_IST_LO + r) * 4,
                              ex_programs[i]->seq_regs[k * EX_REG_PER_INSN + r]);
                sim_sendf("0x%08X 0x%08X\n", base + BRAM_IST_STRB(EX_REG_PER_INSN) * 4, 0);
                sim_sendf("0x%08X 0x%08X\n", base + BRAM_IST_STRB(EX_REG_PER_INSN) * 4, 1);
            }

            for (unsigned int j = 0; j < n; j++) {
                sim_sendf("0x%08X 0x%08X\n", base + BRAM_PCST_ADDR * 4, j);
                sim_sendf("0x%08X 0x%08X\n", base + BRAM_PCST * 4, j);
                sim_sendf("0x%08X 0x%08X\n", base + BRAM_PCST_STRB * 4, 0);
                sim_sendf("0x%08X 0x%08X\n", base + BRAM_PCST_STRB * 4, 1);
            }

            sim_sendf("0x%08X 0x%08X\n", base + BRAM_ITERS(EX_REG_PER_INSN) * 4, ex_programs[i]->repeat);
            sim_sendf("0x%08X 0x%08X\n", base + BRAM_DEPTH(EX_REG_PER_INSN) * 4, n - 1);
            sim_sendf("0x%08X 0x%08X\n", base + BRAM_START(EX_REG_PER_INSN) * 4, 0);
            sim_sendf("0x%08X 0x%08X\n", base + BRAM_START(EX_REG_PER_INSN) * 4, 1);

        }

    }

    if (launch != NULL) {

        uint32_t base = (DC_CHANNELS + RF_CHANNELS + LI_CHANNELS + EX_CHANNELS) * page_size;

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
        sim_sendf("launch %lu\n", program_t(dc_programs, rf_programs, li_programs, ex_programs) + 1000);
    else
        sim_sendf("run %lu\n", program_t(dc_programs, rf_programs, li_programs, ex_programs) + 1000);

    sim_close();

    return 0;
}

static void write_bin(dc_program_t *dc_programs[], 
                      rf_program_t *rf_programs[],
                      li_program_t *li_programs[],
                      ex_program_t *ex_programs[],
                      launch_t *launch,
                      FILE *op) {

    for (int i = 0; i < DC_CHANNELS; i++) {

        if (dc_programs[i] != NULL) {

            fprintf(op, "dc%d\n", i);

            for (int j = 0; j < DC_SEQ_REGS; j++) {
                fprintf(op, "0x%08X\n", (dc_programs[i]->seq_regs)[j]);
            }

            for (int j = 0; j < DC_CTRL_REGS; j++) {
                fprintf(op, "0x%08X\n", (dc_programs[i]->ctrl_regs)[j]);
            }

            fprintf(op, "\n");

        }
    }

    for (int i = 0; i < RF_CHANNELS; i++) {

        if (rf_programs[i] != NULL) {

            fprintf(op, "rf%d\n", i);

            for (int j = 0; j < RF_SEQ_REGS; j++) {
                fprintf(op, "0x%08X\n", (rf_programs[i]->seq_regs)[j]);
            }

            for (int j = 0; j < RF_CTRL_REGS; j++) {
                fprintf(op, "0x%08X\n", (rf_programs[i]->ctrl_regs)[j]);
            }

            fprintf(op, "\n");

        }
    }

    for (int i = 0; i < LI_CHANNELS; i++) {

        if (li_programs[i] != NULL) {

            fprintf(op, "li%d\n", i);

            for (int j = 0; j < LI_SEQ_REGS; j++) {
                fprintf(op, "0x%08X\n", (li_programs[i]->seq_regs)[j]);
            }

            for (int j = 0; j < LI_CTRL_REGS; j++) {
                fprintf(op, "0x%08X\n", (li_programs[i]->ctrl_regs)[j]);
            }

            fprintf(op, "\n");

        }
    }

    for (int i = 0; i < EX_CHANNELS; i++) {

        if (ex_programs[i] != NULL) {

            fprintf(op, "ex%d\n", i);

            for (int j = 0; j < EX_SEQ_REGS; j++) {
                fprintf(op, "0x%08X\n", (ex_programs[i]->seq_regs)[j]);
            }

            fprintf(op, "\n");

        }
    }


    if (launch != NULL) {

        fprintf(op, "launch\n");

        fprintf(op, "0x%08X\n", launch->dc_chmask);
        fprintf(op, "0x%08X\n", launch->rf_chmask);
        fprintf(op, "0x%08X\n", launch->li_chmask);
        fprintf(op, "0x%08X\n", launch->ex_chmask);
        fprintf(op, "0x%08X\n", launch->use_trigger);
        fprintf(op, "0x%08X\n", launch->iters);
        fprintf(op, "0x%08X\n", 1);

        fprintf(op, "\n");

    }
}

// ---- disassembler helpers ----

static void fmt_ns(double ns, char *buf, size_t sz) {
    if      (ns >= 1e9) snprintf(buf, sz, "%.3fs",  ns * 1e-9);
    else if (ns >= 1e6) snprintf(buf, sz, "%.3fms", ns * 1e-6);
    else if (ns >= 1e3) snprintf(buf, sz, "%.3fus", ns * 1e-3);
    else                snprintf(buf, sz, "%.0fns", ns);
}

// Build " (flag1 flag2 ... extra)" into buf, or "" if nothing to show.
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

typedef void (*disasm_fn_t)(const uint32_t *w, char *buf, size_t sz);

// DC: 3-word instruction
// reg[0] = iters[9:0]<<17 | spi_din[23:7]
// reg[1] = spi_din[6:0]<<25 | dspi_din<<5 | spi_rd<<4 | strb_ldac<<3 | hold_cycles[29:27]
// reg[2] = hold_cycles[26:0]<<5 | modify<<4 | arm<<3 | sticky_arm<<2 | idle<<1 | marker
static void disasm_dc(const uint32_t *r, char *buf, size_t sz) {
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

    char tbuf[32];
    fmt_ns((double)(hold_cycles + 1u) * 4.0, tbuf, sizeof(tbuf));

    char extra[32] = "";
    if (modify) snprintf(extra, sizeof(extra), "modify");
    char opts[96];
    build_opts(opts, sizeof(opts), (int)arm, (int)sticky_arm, (int)marker, extra);

    if (idle) {
        snprintf(buf, sz, "%s t=%s%s",
                 (strb_ldac || spi_rd) ? "ful" : "idl", tbuf, opts);
    } else if (iters > 0 && strb_ldac) {
        uint32_t v1_code = spi_din & 0xFFFFFu;
        int32_t  dv      = (dspi_din & (1u << 19))
                           ? (int32_t)(dspi_din | 0xFFF00000u) : (int32_t)dspi_din;
        uint32_t v2_code = (uint32_t)((int32_t)v1_code + (int32_t)iters * dv) & 0xFFFFFu;
        double v1 = (double)twos2real(VMIN, VMAX, DC_DAC_BITS, v1_code);
        double v2 = (double)twos2real(VMIN, VMAX, DC_DAC_BITS, v2_code);
        snprintf(buf, sz, "swp v1=%.4fV v2=%.4fV n=%u t=%s%s",
                 v1, v2, iters + 1u, tbuf, opts);
    } else if (strb_ldac && !((spi_din >> 23) & 1u)) {
        double v = (double)twos2real(VMIN, VMAX, DC_DAC_BITS, spi_din & 0xFFFFFu);
        snprintf(buf, sz, "lvl v=%.4fV t=%s%s", v, tbuf, opts);
    } else if ((spi_din >> 23) & 1u) {
        snprintf(buf, sz, "get r=%u t=%s%s", (spi_din >> 20) & 0x7u, tbuf, opts);
    } else if (spi_din != 0) {
        snprintf(buf, sz, "set r=%u din=0x%05X t=%s%s",
                 (spi_din >> 20) & 0x7u, spi_din & 0xFFFFFu, tbuf, opts);
    } else {
        snprintf(buf, sz, "nop t=%s%s", tbuf, opts);
    }
}

// RF: 4-word instruction
// insn[116:96] in reg[0][20:0]: arm[20] sticky_arm[19] kbc_mode[18:17] kbc1[35:19][16:0]
// reg[1]: kbc1[18:0][31:13] kbc2[35:23][12:0]
// reg[2]: kbc2[22:0][31:9] samples[19:11][8:0]
// reg[3]: samples[10:0][31:21] dsamples[20:1] marker[0]
static void disasm_rf(const uint32_t *r, char *buf, size_t sz) {
    uint32_t arm        = (r[0] >> 20) & 1u;
    uint32_t sticky_arm = (r[0] >> 19) & 1u;
    uint32_t kbc_mode   = (r[0] >> 17) & 3u;
    uint64_t kbc1       = ((uint64_t)(r[0] & 0x1FFFFu) << 19) | ((uint64_t)r[1] >> 13);
    uint64_t kbc2       = ((uint64_t)(r[1] & 0x1FFFu) << 23) | ((uint64_t)r[2] >> 9);
    uint32_t samples    = ((r[2] & 0x1FFu) << 11) | (r[3] >> 21);
    uint32_t dsamples   = (r[3] >> 1) & 0xFFFFFu;
    uint32_t marker     = r[3] & 1u;

    char tbuf[32];
    fmt_ns((double)samples * RF_NS_PER_SAMPLE, tbuf, sizeof(tbuf));
    char extra[48] = "";
    if (dsamples) {
        char dtbuf[32];
        fmt_ns((double)dsamples * RF_NS_PER_SAMPLE, dtbuf, sizeof(dtbuf));
        snprintf(extra, sizeof(extra), "t+%s", dtbuf);
    }
    char opts[96];
    build_opts(opts, sizeof(opts), (int)arm, (int)sticky_arm, (int)marker, extra);

    switch (kbc_mode) {
        case 3:
            snprintf(buf, sz, "idl t=%s%s", tbuf, opts);
            break;
        case 2: {
            long double phs = twos2real(-180.0L,
                                        180.0L - ldexpl(1.0L, -RF_KBC_BITS),
                                        RF_KBC_BITS, kbc2);
            snprintf(buf, sz, "ply phs=%.2f t=%s%s", (double)phs, tbuf, opts);
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

// LI: 2-word instruction
// reg[0]: arm[29] sticky_arm[28] idle[27] marker[26] samples[25:6] dsamples[19:14][5:0]
// reg[1]: dsamples[13:0][31:18] stride[17:0]
static void disasm_li(const uint32_t *r, char *buf, size_t sz) {
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
        fmt_ns((double)dsamples * LI_NS_PER_SAMPLE, dtbuf, sizeof(dtbuf));
        snprintf(extra, sizeof(extra), "t+%s", dtbuf);
    }
    char opts[96];
    build_opts(opts, sizeof(opts), (int)arm, (int)sticky_arm, (int)marker, extra);

    if (idle) {
        char tbuf[32];
        fmt_ns((double)samples * LI_NS_PER_SAMPLE, tbuf, sizeof(tbuf));
        snprintf(buf, sz, "idl t=%s%s", tbuf, opts);
    } else {
        char tbuf[32];
        fmt_ns((double)samples * (double)stride * LI_NS_PER_SAMPLE, tbuf, sizeof(tbuf));
        snprintf(buf, sz, "sam n=%u t=%s%s", samples, tbuf, opts);
    }
}

// EX: 2-word instruction
// reg[0]: arm[24] sticky_arm[23] real[22:9] samples[19:11][8:0]
// reg[1]: samples[10:0][31:21] dsamples[20:1] marker[0]
static void disasm_ex(const uint32_t *r, char *buf, size_t sz) {
    uint32_t arm        = (r[0] >> 24) & 1u;
    uint32_t sticky_arm = (r[0] >> 23) & 1u;
    uint32_t real_u     = (r[0] >> 9) & 0x3FFFu;
    uint32_t samples    = ((r[0] & 0x1FFu) << 11) | (r[1] >> 21);
    uint32_t dsamples   = (r[1] >> 1) & 0xFFFFFu;
    uint32_t marker     = r[1] & 1u;

    char tbuf[32];
    fmt_ns((double)samples * EX_NS_PER_SAMPLE, tbuf, sizeof(tbuf));
    char extra[48] = "";
    if (dsamples) {
        char dtbuf[32];
        fmt_ns((double)dsamples * EX_NS_PER_SAMPLE, dtbuf, sizeof(dtbuf));
        snprintf(extra, sizeof(extra), "t+%s", dtbuf);
    }
    char opts[96];
    build_opts(opts, sizeof(opts), (int)arm, (int)sticky_arm, (int)marker, extra);

    double v = (double)twos2real((long double)EX_VMIN, (long double)EX_VMAX,
                                 EX_REAL_BITS, real_u);
    if (real_u == 0 && !arm && !sticky_arm && !marker && !dsamples)
        snprintf(buf, sz, "idl t=%s", tbuf);
    else
        snprintf(buf, sz, "lvl v=%.4fV t=%s%s", v, tbuf, opts);
}

// ---- channel inspector ----

// Read PCMEM and IMEM via strobe mechanism, disassemble and print program + status regs.
// n        = REG_PER_INSN for the channel type
// ctrl_cnt = number of ctrl regs (0 for EX)
// stat_cnt = number of status regs (DC_STATUS_REGS etc.)
// is_li    = 1 to print LI-specific samples_lost / samples_inbuf fields
// disasm   = per-type disassembly function
static int inspect_channel_uio(int uio_num, int n, int ctrl_cnt,
                                int stat_cnt, const char *label, int is_li,
                                disasm_fn_t disasm) {

    char path[32];
    snprintf(path, sizeof(path), "/dev/uio%d", uio_num);

    int fd = open(path, O_RDWR);
    if (fd < 0) {
        fprintf(stderr, "open(%s): %s\n", path, strerror(errno));
        return 1;
    }

    void *va = mmap(NULL, 0x1000, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (va == MAP_FAILED) {
        fprintf(stderr, "mmap(%s): %s\n", path, strerror(errno));
        close(fd);
        return 1;
    }

    volatile uint32_t *base   = (volatile uint32_t *)va;
    int                sb     = BRAM_SEQ_TOTAL(n) + ctrl_cnt; // status base offset
    volatile uint32_t *status = base + sb;

    // Status reg layout (uniform across all types):
    //   [0..n-1]  insn_rd
    //   [n]       pc_rd
    //   [n+1]     iters
    //   [n+2]     pcmem_depth
    //   [n+3]     flags  bit[1]=armed  bit[0]=empty
    // LI additionally:
    //   [n+4]     samples_lost
    //   [n+5]     samples_inbuf

    uint32_t depth  = base[BRAM_DEPTH(n)];
    uint32_t nsteps = depth + 1;
    if (nsteps > 4096) nsteps = 4096;

    uint32_t flags = status[n + 3];
    uint32_t iters = status[n + 1];

    printf("%s:\n", label);
    printf("  depth:  %u (%u steps)\n", depth, nsteps);
    printf("  iters:  %u\n",  iters);
    printf("  armed:  %u\n",  (flags >> 1) & 1u);
    printf("  empty:  %u\n",  flags & 1u);

    uint32_t *pc_seq    = NULL;
    uint32_t *insn_cache = NULL;
    uint8_t  *fetched   = NULL;
    int       ret       = 0;

    pc_seq     = malloc(nsteps * sizeof(uint32_t));
    insn_cache = calloc((size_t)512 * n, sizeof(uint32_t));
    fetched    = calloc(512, 1);

    if (!pc_seq || !insn_cache || !fetched) {
        fprintf(stderr, "malloc failed\n");
        ret = 1;
        goto done;
    }

    // Read PCMEM: for each sequential address, strobe PCLD and capture pc_rd
    for (uint32_t addr = 0; addr < nsteps; addr++) {
        base[BRAM_PCST_ADDR]    = addr;
        base[BRAM_PCLD_STRB(n)] = 0;
        base[BRAM_PCLD_STRB(n)] = 1;
        pc_seq[addr] = (uint32_t)status[n];  // PC_RD is at index n
    }

    // Fetch each unique instruction from IMEM
    for (uint32_t addr = 0; addr < nsteps; addr++) {
        uint32_t pc = pc_seq[addr] & 0x1FF;  // 9 bits, max 512
        if (!fetched[pc]) {
            base[BRAM_IST_ADDR]    = pc;
            base[BRAM_ILD_STRB(n)] = 0;
            base[BRAM_ILD_STRB(n)] = 1;
            for (int k = 0; k < n; k++)
                insn_cache[pc * n + k] = (uint32_t)status[k];  // INSN_RD at [0..n-1]
            fetched[pc] = 1;
        }
    }

    printf("  program:\n");
    for (uint32_t addr = 0; addr < nsteps; addr++) {
        uint32_t pc = pc_seq[addr] & 0x1FF;
        char asm_buf[128] = "???";
        disasm(&insn_cache[pc * n], asm_buf, sizeof(asm_buf));
        printf("    [%u] pc=%u: %s\n", addr, pc, asm_buf);
    }

    printf("  status:\n");
    for (int k = 0; k < n; k++)
        printf("    insn_rd[%d]:   %08" PRIX32 "\n", k, (uint32_t)status[k]);
    printf("    pc_rd:        %08" PRIX32 "\n", (uint32_t)status[n]);
    printf("    iters:        %08" PRIX32 "\n", (uint32_t)status[n + 1]);
    printf("    pcmem_depth:  %08" PRIX32 "\n", (uint32_t)status[n + 2]);
    printf("    flags:        %08" PRIX32 " (armed=%u empty=%u)\n",
           (uint32_t)status[n + 3], (flags >> 1) & 1u, flags & 1u);
    if (is_li && stat_cnt > n + 4) {
        printf("    samples_lost:  %08" PRIX32 "\n", (uint32_t)status[n + 4]);
        if (stat_cnt > n + 5)
            printf("    samples_inbuf: %08" PRIX32 "\n", (uint32_t)status[n + 5]);
    }

done:
    free(pc_seq);
    free(insn_cache);
    free(fetched);
    munmap(va, 0x1000);
    close(fd);
    return ret;

}

static int inspect_named_channel(const char *name) {

    if (strncmp(name, "dc", 2) == 0) {
        int ch = atoi(name + 2);
        if (ch < 0 || ch >= DC_CHANNELS) {
            fprintf(stderr, "dc channel must be 0..%d\n", DC_CHANNELS - 1);
            return 1;
        }
        char label[16];
        snprintf(label, sizeof(label), "dc%d", ch);
        return inspect_channel_uio(dc_uio_map[ch], DC_REG_PER_INSN,
                                   DC_CTRL_REGS, DC_STATUS_REGS, label, 0, disasm_dc);

    } else if (strncmp(name, "rf", 2) == 0) {
        int ch = atoi(name + 2);
        if (ch < 0 || ch >= RF_CHANNELS) {
            fprintf(stderr, "rf channel must be 0..%d\n", RF_CHANNELS - 1);
            return 1;
        }
        char label[16];
        snprintf(label, sizeof(label), "rf%d", ch);
        return inspect_channel_uio(rf_uio_map[ch], RF_REG_PER_INSN,
                                   RF_CTRL_REGS, RF_STATUS_REGS, label, 0, disasm_rf);

    } else if (strncmp(name, "li", 2) == 0) {
        int ch = atoi(name + 2);
        if (ch < 0 || ch >= LI_CHANNELS) {
            fprintf(stderr, "li channel must be 0..%d\n", LI_CHANNELS - 1);
            return 1;
        }
        char label[16];
        snprintf(label, sizeof(label), "li%d", ch);
        return inspect_channel_uio(li_uio_map[ch], LI_REG_PER_INSN,
                                   LI_CTRL_REGS, LI_STATUS_REGS, label, 1, disasm_li);

    } else if (strncmp(name, "ex", 2) == 0) {
        int ch = atoi(name + 2);
        if (ch < 0 || ch >= EX_CHANNELS) {
            fprintf(stderr, "ex channel must be 0..%d\n", EX_CHANNELS - 1);
            return 1;
        }
        char label[16];
        snprintf(label, sizeof(label), "ex%d", ch);
        return inspect_channel_uio(ex_uio_map[ch], EX_REG_PER_INSN,
                                   0, EX_STATUS_REGS, label, 0, disasm_ex);

    } else {
        fprintf(stderr, "unknown channel '%s' (use dc<n>, rf<n>, li<n>, ex<n>)\n", name);
        return 1;
    }

}

int main(int argc, char *argv[]) {

    int opt;
    char *file = NULL;
    char *out = NULL;
    int sim = 0;
    int exe = 0;
    int read = 0;
    char *rdev = NULL;

    while ((opt = getopt(argc, argv, "f:o:w:r:t:v:sxu")) != -1) {
        switch (opt) {
            case 'f':
                file = optarg;
                break;
            case 'o':
                out = optarg;
                break;
            case 's':
                sim = 1;
                break;
            case 'x':
                exe = 1;
                break;
            case 'r':
                read = 1;
                rdev = optarg;
                break;
            default:
                fprintf(stderr, "Usage: %s [-f file] [-o out] [-s] [-x] [-r ch]\n", argv[0]);
                return 1;
        }
    }

    if (file == NULL && !read) {
        fprintf(stderr, "Usage: %s [-f file] [-o out] [-s] [-x] [-r ch]\n", argv[0]);
        return 1;
    }

    if (out == NULL) {
        out = "out";
    }

    FILE *fp = NULL;
    FILE *op = NULL;
    dc_program_t *dc_programs[DC_CHANNELS] = {NULL};
    rf_program_t *rf_programs[RF_CHANNELS] = {NULL};
    li_program_t *li_programs[LI_CHANNELS] = {NULL};
    ex_program_t *ex_programs[LI_CHANNELS] = {NULL};
    launch_t *launch = NULL;

    if (file != NULL) {
        fp = fopen(file, "r");
        assemble(fp, dc_programs, rf_programs, li_programs, ex_programs, &launch);
        op = fopen(out, "w");
        write_bin(dc_programs, rf_programs, li_programs, ex_programs, launch, op);
        printf("program t: %ld ns\n", program_t(dc_programs, rf_programs, li_programs, ex_programs));
    }

    if (read) {
        inspect_named_channel(rdev);
    }

    if (sim) {
        printf("simulate\n");
        write_sim(dc_programs, rf_programs, li_programs, ex_programs, launch);
    }

    if (exe) {
        for (int ch = 0; ch < DC_CHANNELS; ch++) {
            if (dc_programs[ch] != NULL)
                dc_load_insns(ch, dc_programs[ch]);
        }
        for (int ch = 0; ch < RF_CHANNELS; ch++) {
            if (rf_programs[ch] != NULL)
                rf_load_insns(ch, rf_programs[ch]);
        }
        for (int ch = 0; ch < LI_CHANNELS; ch++) {
            if (li_programs[ch] != NULL)
                li_load_insns(ch, li_programs[ch]);
        }
        for (int ch = 0; ch < EX_CHANNELS; ch++) {
            if (ex_programs[ch] != NULL)
                ex_load_insns(ch, ex_programs[ch]);
        }
        if (launch != NULL)
            launch_load(launch);
    }

    for (int i = 0; i < DC_CHANNELS; i++) {
        if (dc_programs[i] != NULL)
            free(dc_programs[i]);
    }
    for (int i = 0; i < RF_CHANNELS; i++) {
        if (rf_programs[i] != NULL)
            free(rf_programs[i]);
    }
    for (int i = 0; i < LI_CHANNELS; i++) {
        if (li_programs[i] != NULL)
            free(li_programs[i]);
    }
    for (int i = 0; i < EX_CHANNELS; i++) {
        if (ex_programs[i] != NULL)
            free(ex_programs[i]);
    }
    if (launch != NULL)
        free(launch);

    return 0;

}

