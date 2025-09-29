#ifndef RF_H
#define RF_H

#include <stdint.h>

#define RF_KBC_BITS 36
#define RF_SAMPLE_BITS 30
#define RF_ITER_BITS 10

#define RF_DAC_HZ 2000000000ULL
#define RF_DAC_GHZ 2.0

#define RF_KBC_MAX  ((int64_t)((1ULL << (RF_KBC_BITS - 1)) - 1ULL))
#define RF_KBC_MIN  (-(int64_t)(1ULL << (RF_KBC_BITS - 1)))
#define RF_KBC_MASK ((uint64_t)((1ULL << (RF_KBC_BITS)) - 1ULL))

typedef struct {
    int64_t  k;
    int64_t  b;
    int64_t  c;
    uint32_t iters;
    uint32_t dkbc_samples;
    uint32_t kbc_samples;
    uint32_t dzero_samples;
    uint32_t zero_samples;
} rf_insn_t;

typedef struct {
    uint32_t f_span_hz;
    uint32_t f_nco_hz;
    uint32_t t_ns;
} rf_chirp_t;

typedef struct {
    double   phase_deg;
    uint32_t iters;
    uint32_t t_drive_ns;
    uint32_t dt_drive_ns;
    uint32_t t_idle_ns;
    uint32_t dt_idle_ns;
} rf_drive_t;

int rf_program_stream(int rf_channel, int stream_len, rf_insn_t *rf_stream);
rf_insn_t rf_chirp2insn(rf_chirp_t rf_chirp);
rf_insn_t rf_drive2insn(rf_drive_t rf_drive);

#endif
