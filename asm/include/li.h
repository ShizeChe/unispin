#ifndef LI_H
#define LI_H

#include <stdint.h>
#include <math.h>

#define LI_CHANNELS 2
#define LI_DEPTH 16

#define LI_SAMPLE_BITS 20
#define LI_FNCO_BITS 48

#define LI_FSAMPLING_HZ 2000000000ULL
#define LI_FNCO_MIN (-((long double)RF_FSAMPLING_HZ / 2.0L))
#define LI_FNCO_MAX ((LI_FSAMPLING_HZ / 2) - (LI_FSAMPLING_HZ / ldexpl(1.0L, LI_FNCO_BITS)))
#define LI_ADC_HZ 1000000000ULL // x2 decimation
#define LI_ADC_GHZ 1.0 // x2 decimation
#define LI_NS_PER_SAMPLE 1.0
#define LI_MAX_SAMPLES ((1u << LI_SAMPLE_BITS) - 1u)

#define LI_PNCO_BITS 18
#define LI_PNCO_MIN -180
#define LI_PNCO_MAX (180 - (360 / ldexpl(1.0L, 18)))

#define LI_IQ_BITS 14

#define LI_DEPTH 16
#define LI_REG_PER_INSN 2
#define LI_SEQ_REGS ((LI_DEPTH * LI_REG_PER_INSN) + 2)
#define LI_CTRL_REGS 4

static const int li_uio_map[LI_CHANNELS] = {31, 32};

typedef struct {
    uint32_t arm;
    uint32_t idle;
    uint32_t samples;
    uint32_t dsamples;
    uint32_t stride;
} li_insn_t;

typedef struct {
    int64_t nco_freq;
    int32_t nco_phase;
} li_ctrl_t;

typedef struct {
    li_ctrl_t ctrl;
    uint32_t repeat;
    uint32_t len;
    li_insn_t insns[LI_DEPTH];
    uint32_t seq_regs[LI_SEQ_REGS];
    int32_t ctrl_regs[LI_CTRL_REGS];
} li_program_t;

typedef struct {
    uint32_t arm;
    double tplus_ns;
} li_opt_t;

typedef struct {
    uint32_t samples;
    double t_ns;
    li_opt_t opt;
} li_sam_t;

typedef struct {
    double t_ns;
    li_opt_t opt;
} li_idl_t;

int li_parse_insn(char *line, li_insn_t *insn);
void li_assemble(li_program_t *prog);
int li_load_insns(int li_channel, li_program_t *li_program);
int li_read_regs(int li_channel, uint32_t *seq_regs, uint32_t *ctrl_regs);
int li_write_regs(int li_channel, li_program_t *li_program, int uartfd);

#endif
