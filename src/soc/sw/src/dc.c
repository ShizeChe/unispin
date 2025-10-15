#include "dc.h"
#include "def.h"
#include <stdio.h>
#include <math.h>
#include <string.h>
#include <assert.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <sys/mman.h>


static inline uint32_t dc_v2dac_code(double v) {
    const double span = (VMAX - VMIN);
    const double fullscale   = (double)((1u << DC_DAC_BITS) - 1u);
    if (span <= 0.0) return 0;

    double norm   = (v - VMIN) / span;   // ideal 0..1
    double scaled = norm * fullscale;           // ideal 0..(2^N-1)

    if (scaled < 0.0)       scaled = 0.0;
    if (scaled > fullscale) scaled = fullscale;
    return (uint32_t)llround(scaled);
}

static inline uint32_t dc_t2cycles(uint32_t t_ns) {
    const uint64_t max_cycles = (1ull << DC_CYCLE_BITS) - 1ull;
    uint64_t cycles = ( (uint64_t)t_ns + (NS_PER_CYCLE/2) ) / (uint64_t)NS_PER_CYCLE;
    if (cycles == 0) cycles = 1;
    if (cycles > max_cycles) cycles = max_cycles;
    return (uint32_t)cycles;
}

static inline void print_binary(FILE *f, uint32_t value) {
    for (int i = 31; i >= 0; --i) {
        fprintf(f, "%d", (value >> i) & 1);
    }
    fprintf(f, "\n");
}


dc_insn_t dc_sweep2insn(dc_sweep_t s) {
    if (s.num_points < 1) s.num_points = 1;

    const uint32_t start_code = dc_v2dac_code(s.vstart);
    const uint32_t end_code   = dc_v2dac_code(s.vend);
    const uint32_t cycles     = dc_t2cycles(s.dt_ns);

    if (s.num_points == 1) {
        return (dc_insn_t){ .dv = 0, .iters = 1, 
                            .dac_code = start_code, .cycles = cycles };
    }

    const uint32_t steps = s.num_points - 1;               // number of deltas
    const int32_t  delta = (int32_t)end_code - (int32_t)start_code;
    // Integer division truncates toward zero in C. This guarantees:
    // last_code = start_code + steps*dv  <= end_code   if delta >= 0
    // last_code = start_code + steps*dv  >= end_code   if delta <  0
    const int32_t  dv = delta / (int32_t)steps;

    // Clamp iterations to field width
    const uint32_t max_iters = (1u << DC_ITER_BITS) - 1u;
    const uint32_t iters = (s.num_points > max_iters) ? max_iters : s.num_points;

    return (dc_insn_t){
        .dv       = dv,
        .iters    = iters,
        .dac_code = start_code,
        .cycles   = cycles,
    };
}

dc_insn_t dc_level2insn(dc_level_t lvl) {
    const uint32_t code   = dc_v2dac_code(lvl.v);
    const uint32_t cycles = dc_t2cycles(lvl.t_ns);
    return (dc_insn_t){ .dv = 0, .iters = 1, .dac_code = code, .cycles = cycles };
}

void dc_pack_stream(int stream_iters, int stream_len, dc_insn_t *dc_stream, 
                    uint32_t *dc_regs) {

    assert(stream_len <= INSN_PER_DC_CHANNEL);

    for (int i = 0; i < stream_len; i++) {
        dc_regs[i * 3 + 2] = dc_stream[i].dv >> 8;
        dc_regs[i * 3 + 1] = (dc_stream[i].dv << 24) | (dc_stream[i].iters << 14) |
                             (dc_stream[i].dac_code >> 2);
        dc_regs[i * 3] = (dc_stream[i].dac_code << 30) | dc_stream[i].cycles;
    }
    for (int i = stream_len * 3; i < REG_PER_DC_CHANNEL - 4; i++) {
        dc_regs[i] = 0;
    }

    dc_regs[REG_PER_DC_CHANNEL - 2] = stream_iters;
    dc_regs[REG_PER_DC_CHANNEL - 1] = 1;
}

int dc_program_stream(int dc_channel, int stream_iters, int stream_len, 
                      dc_insn_t *dc_stream) {

    assert(0 <= dc_channel && dc_channel <= RF_UIO_BASE - DC_UIO_BASE - 1);

    uint32_t dc_regs[REG_PER_DC_CHANNEL];
    dc_pack_stream(stream_iters, stream_len, dc_stream, dc_regs);
    
#if TEST

    char fp[32];
    snprintf(fp, sizeof(fp), "dump/dc%d.txt", dc_channel);

    FILE *f = fopen(fp, "w");
    if (f == NULL) {
        fprintf(stderr, "fopen(\"%s\") failed: %s\n", fp, strerror(errno));
        return 1;
    }

    for (int i = 0; i < REG_PER_DC_CHANNEL; i++) {
        print_binary(f, dc_regs[i]);
    }

    fclose(f);

#else

    char uio_path[32];
    snprintf(uio_path, sizeof(uio_path), "/dev/uio%d", DC_UIO_BASE + dc_channel);

    int dc_fd = open(uio_path, O_RDWR);
    if (dc_fd < 0) {
        fprintf(stderr, "open(\"%s\") failed: %s\n", uio_path, strerror(errno));
        return 1;
    }

    void *dc_va = mmap(NULL, 0x1000, PROT_READ | PROT_WRITE, MAP_SHARED, dc_fd, 0);
    if (dc_va == MAP_FAILED) {
        fprintf(stderr, "mmap() %s failed: %s\n", uio_path, strerror(errno));
        close(dc_fd);
        return 1;
    }

    volatile uint32_t *dc_base = (volatile uint32_t *)((char *)dc_va);
    for (int i = 0; i < REG_PER_DC_CHANNEL; i++) {
        *(dc_base + i) = dc_regs[i];
    }

    __asm__ __volatile__("dsb oshst" ::: "memory");

#endif

    return 0;
}

