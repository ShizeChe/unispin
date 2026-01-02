#ifndef RF_H
#define RF_H

#include <stdint.h>
#include <math.h>

static inline int clog2_u32(uint32_t n) {
    int r = 0;
    n--;
    while (n > 0) {
        n >>= 1;
        r++;
    }
    return r;
}

#define RF_DEPTH 16

#define RF_KBC_BITS 36
#define RF_SAMPLE_BITS 20
#define RF_FNCO_BITS 48

#define RF_FSAMPLING_HZ 4000000000ULL
#define RF_FNCO_MIN (-(RF_FSAMPLING_HZ / 2))
#define RF_FNCO_MAX ((RF_FSAMPLING_HZ / 2) - (RF_FSAMPLING_HZ / ldexpl(1.0L, RF_FNCO_BITS)))
#define RF_DAC_HZ 2000000000ULL
#define RF_DAC_GHZ 2.0
#define NS_PER_SAMPLE 0.5
#define RF_MAX_SAMPLES ((1u << RF_SAMPLE_BITS) - 1u)

#define RF_KBC_MAX  ((int64_t)((1ULL << (RF_KBC_BITS - 1)) - 1ULL))
#define RF_KBC_MIN  (-(int64_t)(1ULL << (RF_KBC_BITS - 1)))
#define RF_KBC_MASK ((uint64_t)((1ULL << (RF_KBC_BITS)) - 1ULL))

#define RF_DEPTH 16
#define RF_REG_PER_INSN 4
#define RF_TOTAL_REGS ((RF_DEPTH * RF_REG_PER_INSN) + 2)

typedef struct {
    uint32_t arm;
    uint32_t kbc_mode;
    uint64_t kbc1;
    uint64_t kbc2;
    uint32_t samples;
    uint32_t dsamples;
} rf_insn_t;

typedef struct {
    uint32_t repeat;
    uint64_t fnco;
    uint32_t len;
    rf_insn_t insns[RF_DEPTH];
    uint32_t regs[RF_TOTAL_REGS];
} rf_program_t;

typedef struct {
    uint32_t arm;
    double tplus_ns;
} rf_opt_t;

typedef struct {
    long double f1;
    long double f2;
    double t_ns;
    rf_opt_t opt;
} rf_chp_t;

typedef struct {
    long double phs;
    double t_ns;
    rf_opt_t opt;
} rf_ply_t;

typedef struct {
    double t_ns;
    rf_opt_t opt;
} rf_idl_t;

typedef struct {
    uint32_t kbc_mode;
    uint64_t kbc1;
    uint64_t kbc2;
    double t_ns;
    rf_opt_t opt;
} rf_ful_t;

int rf_parse_insn(char *line, rf_insn_t *insn, long double fnco_hz);
void rf_assemble(rf_program_t *prog);
int rf_load_insns(int rf_channel, rf_program_t *rf_program);

#endif
