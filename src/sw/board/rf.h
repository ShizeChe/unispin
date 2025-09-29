#include "dc.h"
#include <math.h>
#include <string.h>


static uint32_t dc_v2dac_code(double v) {
    const double span = (VMAX - VMIN);
    const double fs   = (double)((1u << DC_DAC_BITS) - 1u);
    if (span <= 0.0) return 0;

    double norm   = (v - VMIN) / span;   // ideal 0..1
    double scaled = norm * fs;           // ideal 0..(2^N-1)

    if (scaled < 0.0)       scaled = 0.0;
    if (scaled > fs)        scaled = fs;
    return (uint32_t)llround(scaled);
}

static uint32_t dc_t2cycles(uint32_t t_ns) {
    const uint64_t max_cycles = (1ull << DC_CYCLE_BITS) - 1ull;
    uint64_t cycles = ( (uint64_t)t_ns + (NS_PER_CYCLE/2) ) / (uint64_t)NS_PER_CYCLE;
    if (cycles == 0) cycles = 1;
    if (cycles > max_cycles) cycles = max_cycles;
    return (uint32_t)cycles;
}

int dc_program_stream(int dc_channel, int stream_len, dc_insn_t *dc_stream) {
    return 0;
}

dc_insn_t dc_sweep2insn(dc_sweep_t s) {
    // guard: at least one point
    if (s.num_points < 1) s.num_points = 1;

    const uint32_t start_code = dc_v2dac_code(s.vstart);
    const uint32_t cycles     = dc_t2cycles(s.dt);

    // If only one point, no delta and one iteration.
    if (s.num_points == 1) {
        return (dc_insn_t){
            .dv       = 0,
            .iters    = 1,
            .dac_code = start_code,
            .cycles   = cycles,
        };
    }

    // Compute per-step delta in *volts*, then convert to *code delta*.
    // Using endpoint difference avoids rounding bias:
    double step_v = (s.vend - s.vstart) / (double)(s.num_points - 1);
    // Convert vstart and vstart+step to codes and subtract.
    int32_t dv_code = (int32_t)dc_v2dac_code(s.vstart + step_v)
                    - (int32_t)dc_v2dac_code(s.vstart);

    // Clamp iterations to field width just in case
    uint32_t max_iters = (1u << DC_ITER_BITS) - 1u;
    uint32_t iters = s.num_points > max_iters ? max_iters : s.num_points;

    return (dc_insn_t){
        .dv       = dv_code,
        .iters    = iters,
        .dac_code = start_code,
        .cycles   = cycles,
    };
}

dc_insn_t dc_level2insn(dc_level_t lvl) {
    const uint32_t code   = dc_v2dac_code(lvl.v);
    const uint32_t cycles = dc_t2cycles(lvl.t);
    return (dc_insn_t){ .dv = 0, .iters = 1, .dac_code = code, .cycles = cycles };
}
