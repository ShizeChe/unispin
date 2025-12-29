#include "common.h"
#include "dc.h"
#include "rf.h"
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

static int line_empty(char *s) {
    while (isspace((unsigned char)*s))
        s++;
    return *s == '\0' || *s == ';';
}

static int assemble(FILE *fp, dc_program_t *dc_programs[]) {

    char line[256] = {0};

    typedef enum {
        PROGRAM,
        DC_REPEAT,
        DC_INSN,
        RF_REPEAT,
        RF_FNCO,
        RF_INSN
    } state_t;

    state_t state = PROGRAM;

    char tmp[10];
    char *success = tmp;

    int i = 0;

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
                    state = DC_REPEAT;
                    success = fgets(line, sizeof(line), fp);
                } else if (sscanf(line, ".program rf%u ", &channel)) {
                    state = RF_REPEAT;
                    success = fgets(line, sizeof(line), fp);
                } else {
                    return -1;
                }

                break;

            case DC_REPEAT:

                uint32_t dc_repeat;

                if (sscanf(line, ".repeat %u ", &dc_repeat)) {
                    dc_programs[channel]->repeat = dc_repeat;
                    state = DC_INSN;
                    success = fgets(line, sizeof(line), fp);
                } else {
                    return -1;
                }

                break;

            case DC_INSN:

                while (success != NULL) {

                    if (dc_parse_insn(line, &(dc_programs[channel]->insns[i])) == 0) {

                        if (i >= DC_DEPTH) {
                            printf("Exceeding maximum number of dc instructions:\n");
                            printf("%s\n", line);
                            return -1;
                        } else {
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

            case RF_REPEAT:

                uint32_t rf_repeat;

                if (sscanf(line, ".repeat %u ", &rf_repeat)) {
                    rf_programs[channel]->repeat = rf_repeat;
                    state = RF_FNCO;
                    success = fgets(line, sizeof(line), fp);
                } else {
                    return -1;
                }

                break;

            case RF_FNCO:

                long double rf_fnco_hz;
                char fnco_tok[32];

                if (sscanf(line, ".fnco %31s ", fnco_tok)) {
                    if (parse_freq(fnco_tok, &rf_fnco_hz) == 0) {
                        rf_programs[channel]->fnco = real2twos(RF_FNCO_MIN, 
                            RF_FNCO_MAX, RF_FNCO_BITS, rf_fnco_hz);
                        state = RF_INSN;
                        success = fgets(line, sizeof(line), fp);
                    } else {
                        return -1;
                    }
                } else {
                    return -1;
                }
                
                break;

            case RF_INSN:

                while (success != NULL) {

                    if (rf_parse_insn(line, &(rf_programs[channel]->insns[i])) == 0) {

                        if (i >= RF_DEPTH) {
                            printf("Exceeding maximum number of rf instructions:\n");
                            printf("%s\n", line);
                            return -1;
                        } else {
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

        }
    }

    return 0;

}

static uint64_t program_t(dc_program_t *dc_programs[]) {

    uint64_t max_ns = 0;
    uint64_t cycle_ns = NS_PER_CYCLE;

    for (int i = 0; i < DC_CHANNELS; i++) {

        if (dc_programs[i] != NULL) {

            uint64_t t_ns = 0;

            for (unsigned int j = 0; j < dc_programs[i]->len; j++) {

                dc_insn_t *insn = &(dc_programs[i]->insns[i]);
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

    return max_ns;

}

static void write_pipe(dc_program_t *dc_programs[], FILE *pipe) {

    for (int i = 0; i < DC_CHANNELS; i++) {

        if (dc_programs[i] != NULL) {

            uint32_t base = i * DC_TOTAL_REGS * 4;

            fprintf(pipe, "0x%08X 0x%08X\n", base + (DC_TOTAL_REGS - 1) * 4, 0);
            
            for (unsigned int j = 0; j < DC_TOTAL_REGS; j++) {
                fprintf(pipe, "0x%08X 0x%08X\n", base + j * 4, (dc_programs[i]->regs)[j]);
            }

        }

    }
}

static void write_bin(dc_program_t *dc_programs[], FILE *op) {

    for (int i = 0; i < DC_CHANNELS; i++) {

        if (dc_programs[i] != NULL) {

            fprintf(op, "dc%d\n", i);

            for (int j = 0; j < DC_TOTAL_REGS; j++) {
                fprintf(op, "0x%08X\n", (dc_programs[i]->regs)[j]);
            }

            fprintf(op, "\n");

        }
    }
}

int main(int argc, char *argv[]) {

    int opt;
    char *file = NULL;
    char *out = NULL;
    char *sim = NULL;
    int exe = 0;

    while ((opt = getopt(argc, argv, "f:o:s:x")) != -1) {
        switch (opt) {
            case 'f':
                file = optarg;
                break;
            case 'o':
                out = optarg;
                break;
            case 's':
                sim = optarg;
                break;
            case 'x':
                exe = 1;
                break;
            default:
                fprintf(stderr, "Usage: %s [-f file] [-o out] [-s mkfifo] [-x]\n", argv[0]);
                return 1;
        }
    }

    if (file == NULL) {
        fprintf(stderr, "Usage: %s [-f file] [-o out] [-s mkfifo] [-x]\n", argv[0]);
        return 1;
    }

    if (out == NULL) {
        out = "out";
    }

    FILE *fp = fopen(file, "r");
    dc_program_t *dc_programs[DC_CHANNELS] = {NULL};
    assemble(fp, dc_programs);

    FILE *op = fopen(out, "w");
    write_bin(dc_programs, op);

    if (sim != NULL) {
        FILE *pipe = fopen(sim, "w");
        write_pipe(dc_programs, pipe);
        fprintf(pipe, "run %lu", program_t(dc_programs) + 1000);
    }

    if (exe) {
        for (int ch = 0; ch < DC_CHANNELS; ch++) {
            if (dc_programs[ch] != NULL)
                dc_load_insns(ch, dc_programs[ch]);
        }
    }

    for (int i = 0; i < DC_CHANNELS; i++) {
        if (dc_programs[i] != NULL)
            free(dc_programs[i]);
    }

    return 0;

}

