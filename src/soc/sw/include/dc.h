#ifndef DC_H
#define DC_H

#include <stdint.h>

#define NUM_DC_CHANNEL 16
#define INSN_PER_DC_CHANNEL 20
#define REG_PER_DC_CHANNEL 62

#define DC_DAC_BITS 16
#define DC_CYCLE_BITS 30
#define DC_ITER_BITS 10

#define VMAX 10.0
#define VMIN -10.0
#define NS_PER_CYCLE 4

typedef struct {
    uint32_t dv;
    uint32_t iters;
    uint32_t dac_code;
    uint32_t cycles;
} dc_insn_t;

typedef struct {
    double vstart;
    double vend;
    uint32_t num_points;
    uint32_t dt_ns;
} dc_sweep_t;

typedef struct {
    double v;
    uint32_t t_ns;
} dc_level_t;

dc_insn_t dc_sweep2insn(dc_sweep_t dc_sweep);
dc_insn_t dc_level2insn(dc_level_t dc_level);

void dc_pack_stream(int stream_iters, int stream_len, dc_insn_t *dc_stream, 
                    uint32_t *dc_regs);

int dc_program_stream(int dc_channel, int stream_iters, int stream_len, 
                      dc_insn_t *dc_stream);

#endif
