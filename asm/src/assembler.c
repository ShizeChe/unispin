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
                    li_programs[channel]->ctrl.nco_freq = -1;
                    li_programs[channel]->ctrl.nco_phase = -1;

                    state = LI_CTRL;
                    success = fgets(line, sizeof(line), fp);

                } else if (sscanf(line, ".program ex%u ", &channel)) {

                    ex_programs[channel] = (ex_program_t *)calloc(1, sizeof(ex_program_t));

                    state = EX_REPEAT;
                    success = fgets(line, sizeof(line), fp);

                } else if (strncmp(line, ".launch", 7) == 0) {

                    *launch = (launch_t *)calloc(1, sizeof(launch_t));

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

            sim_sendf("0x%08X 0x%08X\n", base + (DC_SEQ_REGS - 1) * 4, 0);
            
            for (unsigned int j = 0; j < DC_SEQ_REGS; j++) {
                sim_sendf("0x%08X 0x%08X\n", base + j * 4, (dc_programs[i]->seq_regs)[j]);
            }

            sim_sendf("0x%08X 0x%08X\n", base + (DC_SEQ_REGS + DC_CTRL_REGS - 1) * 4, 0);
            
            for (unsigned int j = 0; j < DC_CTRL_REGS; j++) {
                if (dc_programs[i]->ctrl_regs[j] != -1)
                    sim_sendf("0x%08X 0x%08X\n", base + (DC_SEQ_REGS + j) * 4, 
                        (dc_programs[i]->ctrl_regs)[j]);
            }

        }

    }

    for (int i = 0; i < RF_CHANNELS; i++) {

        if (rf_programs[i] != NULL) {

            uint32_t base = (DC_CHANNELS + i) * page_size;

            sim_sendf("0x%08X 0x%08X\n", base + (RF_SEQ_REGS - 1) * 4, 0);
            
            for (unsigned int j = 0; j < RF_SEQ_REGS; j++) {
                sim_sendf("0x%08X 0x%08X\n", base + j * 4, (rf_programs[i]->seq_regs)[j]);
            }

            sim_sendf("0x%08X 0x%08X\n", base + (RF_SEQ_REGS + RF_CTRL_REGS - 1) * 4, 0);
            
            for (unsigned int j = 0; j < RF_CTRL_REGS; j++) {
                if (rf_programs[i]->ctrl_regs[j] != -1)
                    sim_sendf("0x%08X 0x%08X\n", base + (RF_SEQ_REGS + j) * 4, 
                        (rf_programs[i]->ctrl_regs)[j]);
            }

        }

    }

    for (int i = 0; i < LI_CHANNELS; i++) {

        if (li_programs[i] != NULL) {

            uint32_t base = (DC_CHANNELS + RF_CHANNELS + i) * page_size;

            sim_sendf("0x%08X 0x%08X\n", base + (LI_SEQ_REGS - 1) * 4, 0);
            
            for (unsigned int j = 0; j < LI_SEQ_REGS; j++) {
                sim_sendf("0x%08X 0x%08X\n", base + j * 4, (li_programs[i]->seq_regs)[j]);
            }

            sim_sendf("0x%08X 0x%08X\n", base + (LI_SEQ_REGS + LI_CTRL_REGS - 1) * 4, 0);
            
            for (unsigned int j = 0; j < LI_CTRL_REGS; j++) {
                if (li_programs[i]->ctrl_regs[j] != -1)
                    sim_sendf("0x%08X 0x%08X\n", base + (LI_SEQ_REGS + j) * 4, 
                        (li_programs[i]->ctrl_regs)[j]);
            }

        }

    }

    for (int i = 0; i < EX_CHANNELS; i++) {

        if (ex_programs[i] != NULL) {

            uint32_t base = (DC_CHANNELS + RF_CHANNELS + LI_CHANNELS + i) * page_size;

            sim_sendf("0x%08X 0x%08X\n", base + (EX_SEQ_REGS - 1) * 4, 0);
            
            for (unsigned int j = 0; j < EX_SEQ_REGS; j++) {
                sim_sendf("0x%08X 0x%08X\n", base + j * 4, (ex_programs[i]->seq_regs)[j]);
            }

        }

    }

    if (launch != NULL) {

        uint32_t base = (DC_CHANNELS + RF_CHANNELS + LI_CHANNELS + EX_CHANNELS) * page_size;

        sim_sendf("0x%08X 0x%08X\n", base + (LAUNCH_TOTAL_REGS - 1) * 4, 0);
        
        sim_sendf("0x%08X 0x%08X\n", base, launch->dc_chmask);
        sim_sendf("0x%08X 0x%08X\n", base + 4, launch->rf_chmask);
        sim_sendf("0x%08X 0x%08X\n", base + 8, launch->li_chmask);
        sim_sendf("0x%08X 0x%08X\n", base + 12, launch->ex_chmask);
        sim_sendf("0x%08X 0x%08X\n", base + (LAUNCH_TOTAL_REGS - 1) * 4, 1);

    }

    if (launch != NULL) 
        sim_sendf("launch %lu\n", program_t(dc_programs, rf_programs, li_programs, ex_programs) + 1000);
    else
        sim_sendf("run %lu\n", program_t(dc_programs, rf_programs, li_programs, ex_programs) + 1000);

    sim_close();

    return 0;
}

static void write_reg_sim(uint8_t idx, uint32_t data) {
    sim_sendf("0x%02X\n", (uint8_t)(idx & 0x7f));
    sim_sendf("0x%02X\n", (uint8_t)(data >> 24));
    sim_sendf("0x%02X\n", (uint8_t)(data >> 16));
    sim_sendf("0x%02X\n", (uint8_t)(data >> 8));
    sim_sendf("0x%02X\n", (uint8_t)(data));
}

static int write_sim_uart(dc_program_t *dc_programs[], 
                          rf_program_t *rf_programs[],
                          li_program_t *li_programs[],
                          ex_program_t *ex_programs[],
                          launch_t *launch) {

    if (sim_connect(SOCKET) != 0) {
        printf("Connection unseccessful\n");
        return -1;
    }

    for (int i = 0; i < DC_CHANNELS; i++) {

        if (dc_programs[i] != NULL) {

            write_reg_sim(DC_SEQ_REGS + DC_CTRL_REGS - 1, 0);
            
            for (unsigned int j = 0; j < DC_CTRL_REGS - 1; j++) {
                if (dc_programs[i]->ctrl_regs[j] != -1)
                    write_reg_sim(DC_SEQ_REGS + j, dc_programs[i]->ctrl_regs[j]);
            }

            write_reg_sim(DC_SEQ_REGS + DC_CTRL_REGS - 1, (1U << i));

            write_reg_sim(DC_SEQ_REGS - 1, 0);
            
            for (unsigned int j = 0; j < DC_SEQ_REGS - 1; j++) {
                write_reg_sim(j, dc_programs[i]->seq_regs[j]);
            }

            write_reg_sim(DC_SEQ_REGS - 1, (1U << i));

        }

    }

    for (int i = 0; i < RF_CHANNELS; i++) {

        uint32_t base = DC_SEQ_REGS + DC_CTRL_REGS;

        if (rf_programs[i] != NULL) {

            write_reg_sim(base + RF_SEQ_REGS + RF_CTRL_REGS - 1, 0);
            
            for (unsigned int j = 0; j < RF_CTRL_REGS - 1; j++) {
                if (rf_programs[i]->ctrl_regs[j] != -1)
                    write_reg_sim(base + RF_SEQ_REGS + j, rf_programs[i]->ctrl_regs[j]);
            }

            write_reg_sim(base + RF_SEQ_REGS + RF_CTRL_REGS - 1, (1U << i));

            write_reg_sim(base + RF_SEQ_REGS - 1, 0);
            
            for (unsigned int j = 0; j < RF_SEQ_REGS - 1; j++) {
                write_reg_sim(base + j, rf_programs[i]->seq_regs[j]);
            }

            write_reg_sim(base + RF_SEQ_REGS - 1, (1U << i));

        }

    }

    for (int i = 0; i < LI_CHANNELS; i++) {

        uint32_t base = DC_SEQ_REGS + DC_CTRL_REGS + RF_SEQ_REGS + RF_CTRL_REGS;

        if (li_programs[i] != NULL) {

            write_reg_sim(base + LI_SEQ_REGS + LI_CTRL_REGS - 1, 0);
            
            for (unsigned int j = 0; j < LI_CTRL_REGS - 1; j++) {
                if (li_programs[i]->ctrl_regs[j] != -1)
                    write_reg_sim(base + LI_SEQ_REGS + j, li_programs[i]->ctrl_regs[j]);
            }

            write_reg_sim(base + LI_SEQ_REGS + LI_CTRL_REGS - 1, (1U << i));

            write_reg_sim(base + LI_SEQ_REGS - 1, 0);
            
            for (unsigned int j = 0; j < LI_SEQ_REGS - 1; j++) {
                write_reg_sim(base + j, li_programs[i]->seq_regs[j]);
            }

            write_reg_sim(base + LI_SEQ_REGS - 1, (1U << i));

        }

    }

    for (int i = 0; i < EX_CHANNELS; i++) {

        uint32_t base = DC_SEQ_REGS + DC_CTRL_REGS + RF_SEQ_REGS + RF_CTRL_REGS + LI_SEQ_REGS + LI_CTRL_REGS;

        if (ex_programs[i] != NULL) {
            
            write_reg_sim(base + EX_SEQ_REGS - 1, 0);
            
            for (unsigned int j = 0; j < EX_SEQ_REGS - 1; j++) {
                write_reg_sim(base + j, ex_programs[i]->seq_regs[j]);
            }

            write_reg_sim(base + EX_SEQ_REGS - 1, (1U << i));

        }

    }

    if (launch != NULL) {

        uint32_t base = DC_SEQ_REGS + DC_CTRL_REGS +
                        RF_SEQ_REGS + RF_CTRL_REGS +
                        LI_SEQ_REGS + LI_CTRL_REGS;

        write_reg_sim(base + LAUNCH_TOTAL_REGS - 1, 0);
        
        write_reg_sim(base, launch->dc_chmask);
        write_reg_sim(base + 1, launch->rf_chmask);
        write_reg_sim(base + 2, launch->li_chmask);
        write_reg_sim(base + 2, launch->ex_chmask);
        write_reg_sim(base + LAUNCH_TOTAL_REGS - 1, 1);

    }

    sim_sendf("run %lu\n", program_t(dc_programs, rf_programs, li_programs, ex_programs) + 1000);

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
        fprintf(op, "0x%08X\n", 1);

        fprintf(op, "\n");

    }
}

static int write_single(int uartfd, uint8_t addr, uint32_t tval) {

    uint8_t tx[6] = {0, 0, 0, 0, 0, 0};

    ssize_t n;

    tx[0] = (uint8_t)(addr);
    tx[1] = (uint8_t)(tval >> 24);
    tx[2] = (uint8_t)(tval >> 16);
    tx[3] = (uint8_t)(tval >> 8);
    tx[4] = (uint8_t)(tval);

    n = write(uartfd, tx, sizeof(tx) - 1);
    if (n < 0) {
        perror("write error");
        return -1;
    }

    return 0;

}

static int read_uart_regs(int uartfd) {

    uint8_t tx[2] = {0, 0};
    uint8_t rx[5] = {0, 0, 0, 0, 0};

    uint32_t regval = 0;

    int total_regs = DC_SEQ_REGS + DC_CTRL_REGS +
                     RF_SEQ_REGS + RF_CTRL_REGS +
                     LAUNCH_TOTAL_REGS;

    for (int i = 0; i < total_regs; i++) {

        tx[0] = ((uint8_t)i) | (0b10000000);
        ssize_t n = write(uartfd, tx, sizeof(tx) - 1);
        if (n < 0) {
            perror("write error");
            return -1;
        }

        ssize_t r = read(uartfd, rx, sizeof(rx) - 1);
        if (r < 0) {
            perror("read error");
            return -1;
        } else if (r == 0) {
            printf("read timeout (no data)\n");
            return -1;
        } else {
            regval |= ((uint32_t)rx[0]) << 24;
            regval |= ((uint32_t)rx[1]) << 16;
            regval |= ((uint32_t)rx[2]) << 8;
            regval |= ((uint32_t)rx[3]);
            printf("0x%08" PRIX32 "\n", regval);
            regval = 0;
        }

    }

    return 0;

}

static int read_single(int uartfd, uint8_t addr) {

    uint8_t tx[2] = {0, 0};
    uint8_t rx[5] = {0, 0, 0, 0, 0};

    uint32_t regval = 0;


    tx[0] = ((uint8_t)addr) | (0b10000000);
    ssize_t n = write(uartfd, tx, sizeof(tx) - 1);
    if (n < 0) {
        perror("write error");
        return -1;
    }

    ssize_t r = read(uartfd, rx, sizeof(rx) - 1);
    if (r < 0) {
        perror("read error");
        return -1;
    } else if (r == 0) {
        printf("read timeout (no data)\n");
        return -1;
    } else {
        regval |= ((uint32_t)rx[0]) << 24;
        regval |= ((uint32_t)rx[1]) << 16;
        regval |= ((uint32_t)rx[2]) << 8;
        regval |= ((uint32_t)rx[3]);
        printf("0x%08" PRIX32 "\n", regval);
        regval = 0;
    }

    return 0;

}

static int setup_uart(int fd, speed_t speed) {

    struct termios tty;

    if (tcgetattr(fd, &tty) != 0) {
        perror("tcgetattr");
        return -1;
    }

    // Set baud rate
    cfsetispeed(&tty, speed);
    cfsetospeed(&tty, speed);

    // 8N1, no flow control
    tty.c_cflag = (tty.c_cflag & ~CSIZE) | CS8; // 8-bit chars
    tty.c_iflag &= ~(IGNBRK | BRKINT | PARMRK | ISTRIP
                   | INLCR | IGNCR | ICRNL | IXON | IXOFF | IXANY);
    tty.c_lflag &= ~(ECHO | ECHONL | ICANON | ISIG | IEXTEN);
    tty.c_oflag &= ~OPOST;

    tty.c_cflag |= (CLOCAL | CREAD);            // ignore modem controls, enable reading
    tty.c_cflag &= ~(PARENB | PARODD);          // no parity
    tty.c_cflag &= ~CSTOPB;                     // 1 stop bit
    tty.c_cflag &= ~CRTSCTS;                    // no HW flow control

    // Read timeout behavior:
    // VMIN=0, VTIME=10 => read returns immediately with what’s available,
    // or waits up to 1.0s (10 deciseconds) for at least 1 byte.
    tty.c_cc[VMIN]  = 0;
    tty.c_cc[VTIME] = 10;

    if (tcsetattr(fd, TCSANOW, &tty) != 0) {
        perror("tcsetattr");
        return -1;
    }

    // Flush any pending data
    tcflush(fd, TCIOFLUSH);
    return 0;

}

static int parse_u8_optarg(char *s, uint8_t *out)
{
    if (!s) return 0;

    // Optional: skip leading spaces
    while (isspace((unsigned char)*s)) s++;
    if (*s == '\0') return 0;

    errno = 0;
    char *end = NULL;
    unsigned long v = strtoul(s, &end, 0); // base 0: allows 123, 0x7F, 077

    // No digits parsed
    if (end == s) return 0;

    // Optional: allow trailing spaces
    while (isspace((unsigned char)*end)) end++;
    if (*end != '\0') return 0;

    if (errno == ERANGE) return 0;     // overflow from conversion
    if (v > UINT8_MAX) return 0;       // not fit in uint8_t

    *out = (uint8_t)v;
    return 1;
}

static int parse_u32_optarg(const char *s, uint32_t *out)
{
    if (!s) return 0;

    while (isspace((unsigned char)*s)) s++;
    if (*s == '\0') return 0;

    // Reject sign
    if (*s == '+' || *s == '-') return 0;

    // Allow optional 0x / 0X
    if (s[0] == '0' && (s[1] == 'x' || s[1] == 'X')) s += 2;

    // Require at least one hex digit
    if (!isxdigit((unsigned char)*s)) return 0;

    errno = 0;
    char *end = NULL;
    unsigned long v = strtoul(s, &end, 16);

    while (isspace((unsigned char)*end)) end++;
    if (*end != '\0') return 0;     // trailing junk
    if (errno == ERANGE) return 0;  // overflow in conversion

    if (v > 0xFFFFFFFFUL) return 0; // fit in 32 bits

    *out = (uint32_t)v;
    return 1;
}

static void inspect_regs() {

    uint32_t dc_seq_regs[DC_SEQ_REGS];
    uint32_t dc_ctrl_regs[DC_CTRL_REGS];

    uint32_t rf_seq_regs[RF_SEQ_REGS];
    uint32_t rf_ctrl_regs[RF_CTRL_REGS];

    uint32_t li_seq_regs[LI_SEQ_REGS];
    uint32_t li_ctrl_regs[LI_CTRL_REGS];

    uint32_t ex_seq_regs[EX_SEQ_REGS];
    uint32_t launch_regs[LAUNCH_TOTAL_REGS];

    for (int ch = 0; ch < DC_CHANNELS; ch++) {

        dc_read_regs(ch, dc_seq_regs, dc_ctrl_regs);
        printf("dc%d\n", ch);

        printf("\tseq regs:\n");
        for (int i = 0; i < DC_SEQ_REGS; i++) {
            printf("\t\t%08" PRIX32 "\n", dc_seq_regs[i]);
        }

        printf("\tctrl regs:\n");
        for (int i = 0; i < DC_CTRL_REGS; i++) {
            printf("\t\t%08" PRIX32 "\n", dc_ctrl_regs[i]);
        }
        printf("\n");

    }

    for (int ch = 0; ch < RF_CHANNELS; ch++) {

        rf_read_regs(ch, rf_seq_regs, rf_ctrl_regs);
        printf("rf%d\n", ch);

        printf("\tseq regs:\n");
        for (int i = 0; i < RF_SEQ_REGS; i++) {
            printf("\t\t%08" PRIX32 "\n", rf_seq_regs[i]);
        }

        printf("\tctrl regs:\n");
        for (int i = 0; i < RF_CTRL_REGS; i++) {
            printf("\t\t%08" PRIX32 "\n", rf_ctrl_regs[i]);
        }
        printf("\n");

    }

    for (int ch = 0; ch < LI_CHANNELS; ch++) {

        li_read_regs(ch, li_seq_regs, li_ctrl_regs);
        printf("li%d\n", ch);

        printf("\tseq regs:\n");
        for (int i = 0; i < LI_SEQ_REGS; i++) {
            printf("\t\t%08" PRIX32 "\n", li_seq_regs[i]);
        }

        printf("\tctrl regs:\n");
        for (int i = 0; i < LI_CTRL_REGS; i++) {
            printf("\t\t%08" PRIX32 "\n", li_ctrl_regs[i]);
        }
        printf("\n");

    }

    for (int ch = 0; ch < EX_CHANNELS; ch++) {

        ex_read_regs(ch, ex_seq_regs);
        printf("ex%d\n", ch);

        printf("\tseq regs:\n");
        for (int i = 0; i < EX_SEQ_REGS; i++) {
            printf("\t\t%08" PRIX32 "\n", ex_seq_regs[i]);
        }
        printf("\n");

    }

    launch_read_regs(launch_regs);
    printf("launch\n");
    printf("\tregs:\n");
    for (int i = 0; i < LAUNCH_TOTAL_REGS; i++) {
        printf("\t\t%08" PRIX32 "\n", launch_regs[i]);
    }
    printf("\n");
    
}

int main(int argc, char *argv[]) {

    int opt;
    char *file = NULL;
    char *out = NULL;
    int sim = 0;
    int exe = 0;
    int read = 0;
    int write = 0;
    char *wdev = NULL;
    char *rdev = NULL;
    int uart = 0;
    int test = 0;
    uint8_t addr;
    uint32_t tval;

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
            case 'u':
                uart = 1;
                break;
            case 'x':
                exe = 1;
                break;
            case 'w':
                write = 1;
                wdev = optarg;
                break;
            case 'r':
                read = 1;
                rdev = optarg;
                break;
            case 't':
                test = 1;
                if (!parse_u8_optarg(optarg, &addr)) {
                    fprintf(stderr, "Invalid -t (uint8_t): '%s'\n", optarg);
                    return 1;
                }
                break;
            case 'v':
                if (!parse_u32_optarg(optarg, &tval)) {
                    fprintf(stderr, "Invalid -v (uint8_t): '%s'\n", optarg);
                    return 1;
                }
                break;
            default:
                fprintf(stderr, "Usage: %s [-f file] [-o out] [-s] [-x] [-w wdev] [-r rdev] [-t addr]\n", argv[0]);
                return 1;
        }
    }

    if (file == NULL && !read && !write) {
        fprintf(stderr, "Usage: %s [-f file] [-o out] [-s] [-x] [-w wdev] [-r rdev] [-t addr]\n", argv[0]);
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

    int rfd, wfd;

    if (test) {

        if ((!read && !write) || (read && write)) {
            fprintf(stderr, "must have one of [-r rdev] [-w wdev] specified when using -t");
            return 1;
        }

        if (read) {
            rfd = open(rdev, O_RDWR | O_NOCTTY | O_SYNC);
            if (rfd < 0) {
                fprintf(stderr, "open(%s) failed: %s\n", rdev, strerror(errno));
                return 1;
            }
            if (setup_uart(rfd, B921600) != 0) {
                close(rfd);
                return 1;
            }

            for (int i = 0; i < 100; i++) {
                read_single(rfd, addr);
            }
            close(rfd);
        } else if (write) {
            wfd = open(wdev, O_RDWR | O_NOCTTY | O_SYNC);
            if (wfd < 0) {
                fprintf(stderr, "open(%s) failed: %s\n", wdev, strerror(errno));
                return 1;
            }
            if (setup_uart(wfd, B921600) != 0) {
                close(wfd);
                return 1;
            }

            write_single(wfd, addr, tval);
            close(wfd);
        }

        return 0;
    }

    if (file != NULL) {
        fp = fopen(file, "r");
        assemble(fp, dc_programs, rf_programs, li_programs, ex_programs, &launch);
        op = fopen(out, "w");
        write_bin(dc_programs, rf_programs, li_programs, ex_programs, launch, op);
        printf("program t: %ld ns\n", program_t(dc_programs, rf_programs, li_programs, ex_programs));
    }

    if (sim) {
        printf("simulate\n");
        if (uart)
            write_sim_uart(dc_programs, rf_programs, li_programs, ex_programs, launch);
        else
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
        if (launch != NULL)
            launch_load(launch);
    }

    if (write) {
        wfd = open(wdev, O_RDWR | O_NOCTTY | O_SYNC);
        if (wfd < 0) {
            fprintf(stderr, "open(%s) failed: %s\n", wdev, strerror(errno));
            return 1;
        }
        if (setup_uart(wfd, B921600) != 0) {
            close(wfd);
            return 1;
        }
        for (int ch = 0; ch < DC_CHANNELS; ch++) {
            if (dc_programs[ch] != NULL)
                dc_write_regs(ch, dc_programs[ch], wfd);
        }
        for (int ch = 0; ch < RF_CHANNELS; ch++) {
            if (rf_programs[ch] != NULL)
                rf_write_regs(ch, rf_programs[ch], wfd);
        }
        if (launch != NULL)
            launch_load(launch);
        close(wfd);
    }

    if (read) {
        if (uart) {
            rfd = open(rdev, O_RDWR | O_NOCTTY | O_SYNC);
            if (rfd < 0) {
                fprintf(stderr, "open(%s) failed: %s\n", rdev, strerror(errno));
                return 1;
            }
            if (setup_uart(rfd, B921600) != 0) {
                close(rfd);
                return 1;
            }
            read_uart_regs(rfd);
            close(rfd);
        } else {
            inspect_regs();
        }
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

