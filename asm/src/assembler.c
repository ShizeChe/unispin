#include "common.h"
#include "dc.h"
#include "rf.h"
#include "launch.h"
#include "simcli.h"
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>
#include <math.h>
#include <string.h>

static int line_empty(char *s) {
    while (isspace((unsigned char)*s))
        s++;
    return *s == '\0' || *s == ';';
}

static int assemble(FILE *fp, 
                    dc_program_t *dc_programs[],
                    rf_program_t *rf_programs[],
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
                    dc_programs[channel]->ctrl.cs_up_cycles = -1;
                    dc_programs[channel]->ctrl.ldac_cycles = -1;

                    state = DC_CTRL;
                    success = fgets(line, sizeof(line), fp);

                } else if (sscanf(line, ".program rf%u ", &channel)) {

                    rf_programs[channel] = (rf_program_t *)calloc(1, sizeof(rf_program_t));
                    rf_programs[channel]->ctrl.nco_freq = -1;
                    rf_programs[channel]->ctrl.nco_phase = -1;
                    rf_programs[channel]->ctrl.default_I = -1;
                    rf_programs[channel]->ctrl.default_Q = -1;

                    state = RF_CTRL;
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
                int dc_cs_up_cycles;
                int dc_ldac_cycles;

                if (sscanf(line, ".dvsr %d ", &dc_dvsr)) {

                    dc_programs[channel]->ctrl.dvsr = dc_dvsr;
                    assert(dc_dvsr > 0);

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

                char tok[32];

                uint64_t rf_nco_freq_hex;
                long double rf_nco_freq;

                uint32_t rf_nco_phase_hex;
                double rf_nco_phase;

                uint32_t rf_default_I_hex;
                double rf_default_I;

                uint32_t rf_default_Q_hex;
                double rf_default_Q;

                if (sscanf(line, ".fnco %31s ", tok)) {

                    if (sscanf(tok, "0x%lx", &rf_nco_freq_hex)) {

                        rf_programs[channel]->ctrl.nco_freq = (int64_t)rf_nco_freq_hex;

                        success = fgets(line, sizeof(line), fp);

                    } else if (parse_freq(tok, &rf_nco_freq) == 0) {

                        rf_programs[channel]->ctrl.nco_freq = real2twos(RF_FNCO_MIN, 
                            RF_FNCO_MAX, RF_FNCO_BITS, rf_nco_freq, 1);

                        success = fgets(line, sizeof(line), fp);

                    } else {
                        return -1;
                    }

                } else if (sscanf(line, ".pnco %31s ", tok)) {

                    if (sscanf(tok, "0x%x", &rf_nco_phase_hex)) {

                        rf_programs[channel]->ctrl.nco_phase = (int32_t)rf_nco_phase_hex;

                        success = fgets(line, sizeof(line), fp);

                    } else if (sscanf(tok, "%lf", &rf_nco_phase)) {

                        rf_programs[channel]->ctrl.nco_phase = real2twos(RF_PNCO_MIN, 
                            RF_PNCO_MAX, RF_PNCO_BITS, rf_nco_phase, 1);

                        success = fgets(line, sizeof(line), fp);

                    } else {
                        return -1;
                    }

                } else if (sscanf(line, ".defI %31s ", tok)) {

                    if (sscanf(tok, "0x%x", &rf_default_I_hex)) {

                        rf_programs[channel]->ctrl.default_I = (int32_t)rf_default_I_hex;

                        success = fgets(line, sizeof(line), fp);

                    } else if (sscanf(tok, "%lf", &rf_default_I)) {

                        rf_programs[channel]->ctrl.default_I = real2twos(-1, 
                            1, RF_IQ_BITS, rf_default_I, 1);

                        success = fgets(line, sizeof(line), fp);

                    } else {
                        return -1;
                    }

                } else if (sscanf(line, ".defQ %31s ", tok)) {

                    if (sscanf(tok, "0x%x", &rf_default_Q_hex)) {

                        rf_programs[channel]->ctrl.default_Q = (int32_t)rf_default_Q_hex;

                        success = fgets(line, sizeof(line), fp);

                    } else if (sscanf(tok, "%lf", &rf_default_Q)) {

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

                assert(rf_programs[channel]->ctrl.nco_freq != -1);

                rf_insn_t rf_insn;
                i = 0;
                long double rf_fnco_hz = twos2real(RF_FNCO_MIN, RF_FNCO_MAX,
                    RF_FNCO_BITS, rf_programs[channel]->ctrl.nco_freq);

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
                          rf_program_t *rf_programs[]) {

    uint64_t max_ns = 0;
    uint64_t cycle_ns = NS_PER_CYCLE;
    double sample_ns = NS_PER_SAMPLE;

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

    return max_ns;

}

static int write_sim(dc_program_t *dc_programs[], 
                     rf_program_t *rf_programs[],
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

    if (launch != NULL) {

        uint32_t base = (DC_CHANNELS + RF_CHANNELS) * page_size;

        sim_sendf("0x%08X 0x%08X\n", base + (LAUNCH_TOTAL_REGS - 1) * 4, 0);
        
        sim_sendf("0x%08X 0x%08X\n", base, launch->dc_chmask);
        sim_sendf("0x%08X 0x%08X\n", base + 4, launch->rf_chmask);
        sim_sendf("0x%08X 0x%08X\n", base + 8, launch->li_chmask);
        sim_sendf("0x%08X 0x%08X\n", base + (LAUNCH_TOTAL_REGS - 1) * 4, 1);

    }

    sim_sendf("run %lu\n", program_t(dc_programs, rf_programs) + 1000);

    return 0;
}

static void write_bin(dc_program_t *dc_programs[], 
                      rf_program_t *rf_programs[],
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


    if (launch != NULL) {

        fprintf(op, "launch\n");

        fprintf(op, "0x%08X\n", launch->dc_chmask);
        fprintf(op, "0x%08X\n", launch->rf_chmask);
        fprintf(op, "0x%08X\n", launch->li_chmask);
        fprintf(op, "0x%08X\n", 1);

        fprintf(op, "\n");

    }
}

int main(int argc, char *argv[]) {

    int opt;
    char *file = NULL;
    char *out = NULL;
    int sim = 0;
    int exe = 0;

    while ((opt = getopt(argc, argv, "f:o:sx")) != -1) {
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
            default:
                fprintf(stderr, "Usage: %s [-f file] [-o out] [-s] [-x]\n", argv[0]);
                return 1;
        }
    }

    if (file == NULL) {
        fprintf(stderr, "Usage: %s [-f file] [-o out] [-s] [-x]\n", argv[0]);
        return 1;
    }

    if (out == NULL) {
        out = "out";
    }

    FILE *fp = fopen(file, "r");
    dc_program_t *dc_programs[DC_CHANNELS] = {NULL};
    rf_program_t *rf_programs[RF_CHANNELS] = {NULL};
    launch_t *launch = NULL;
    assemble(fp, dc_programs, rf_programs, &launch);

    FILE *op = fopen(out, "w");
    write_bin(dc_programs, rf_programs, launch, op);
    printf("program t: %ld ns\n", program_t(dc_programs, rf_programs));

    if (sim) {
        printf("simulate\n");
        write_sim(dc_programs, rf_programs, launch);
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

    for (int i = 0; i < DC_CHANNELS; i++) {
        if (dc_programs[i] != NULL)
            free(dc_programs[i]);
    }
    for (int i = 0; i < RF_CHANNELS; i++) {
        if (rf_programs[i] != NULL)
            free(rf_programs[i]);
    }
    if (launch != NULL)
        free(launch);

    return 0;

}

