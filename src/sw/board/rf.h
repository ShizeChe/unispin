#include <stdint.h>

#define RF_KBC_BITS 36
#define RF_SAMPLE_BITS 30
#define RF_ITER_BITS 10

typedef struct {
    uint64_t k;
    uint64_t b;
    uint64_t c;
    uint32_t iters;
    uint32_t dkbc_samples;
    uint32_t kbc_samples;
    uint32_t dzero_samples;
    uint32_t zero_samples;
} rf_insn_t;

typedef struct {
    uint32_t fspan;
    uint32_t t;
} rf_chirp_t;

typedef struct {
    uint32_t f;
    uint32_t iters;
    uint32_t t_drive;
    uint32_t dt_drive;
    uint32_t t_idle;
    uint32_t dt_idle;
} rf_drive_t;

int rf_program_stream(int rf_channel, int stream_len, rf_insn_t *rf_stream);
rf_insn_t rf_chirp2insn(rf_chirp_t rf_chirp);
rf_insn_t rf_drive2insn(rf_drive_t rf_drive);

