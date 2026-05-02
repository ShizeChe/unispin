#ifndef EX_H
#define EX_H

#include <stdint.h>
#include <math.h>
#include "common.h"

#define EX_CHANNELS 2

#define EX_DEPTH 16

#define EX_REAL_BITS 14
#define EX_SAMPLE_BITS 20

#define EX_REG_PER_INSN 2
#define EX_SEQ_REGS (EX_DEPTH * EX_REG_PER_INSN)
#define EX_BRAM_SEQ_REGS BRAM_SEQ_TOTAL(EX_REG_PER_INSN)

#define EX_NS_PER_SAMPLE 0.25

#define EX_VMAX 1
#define EX_VMIN -1

#define EX_MAX_SAMPLES ((1u << EX_SAMPLE_BITS) - 1u)

static const int ex_uio_map[EX_CHANNELS] = {28, 29};

typedef struct {
    uint32_t arm;
    uint32_t sticky_arm;
    uint32_t real;
    uint32_t samples;
    uint32_t dsamples;
    uint32_t marker;
} ex_insn_t;

typedef struct {
    uint32_t repeat;
    uint32_t len;
    ex_insn_t insns[EX_DEPTH];
    uint32_t seq_regs[EX_SEQ_REGS];
} ex_program_t;

typedef struct {
    uint32_t arm;
    double tplus_ns;
} ex_opt_t;

typedef struct {
    double v;
    double t_ns;
    ex_opt_t opt;
} ex_lvl_t;

typedef struct {
    double t_ns;
    ex_opt_t opt;
} ex_idl_t;

int ex_parse_insn(char *line, ex_insn_t *insn);
void ex_assemble(ex_program_t *prog);
int ex_load_insns(int ex_channel, ex_program_t *ex_program);
int ex_read_regs(int ex_channel, uint32_t *seq_regs);
int ex_write_regs(int ex_channel, ex_program_t *ex_program, int uartfd);

#endif
