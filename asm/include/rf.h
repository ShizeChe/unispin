#ifndef RF_H
#define RF_H

#include <stdint.h>
#include <math.h>
#include "common.h"

static inline int clog2_u32(uint32_t n) {
    int r = 0;
    n--;
    while (n > 0) {
        n >>= 1;
        r++;
    }
    return r;
}

#define RF_CHANNELS 6

#define RF_DEPTH 16

#define RF_KBC_BITS 36
#define RF_SAMPLE_BITS 20
#define RF_FNCO_BITS 48

#define RF_FSAMPLING_HZ 4000000000ULL
#define RF_FNCO_MIN (-((long double)RF_FSAMPLING_HZ / 2.0L))
#define RF_FNCO_MAX ((RF_FSAMPLING_HZ / 2) - (RF_FSAMPLING_HZ / ldexpl(1.0L, RF_FNCO_BITS)))
#define RF_DAC_HZ 2000000000ULL
#define RF_DAC_GHZ 2.0
#define RF_NS_PER_SAMPLE 0.5
#define RF_MAX_SAMPLES ((1u << RF_SAMPLE_BITS) - 1u)

#define RF_KBC_MAX  ((int64_t)((1ULL << (RF_KBC_BITS - 1)) - 1ULL))
#define RF_KBC_MIN  (-(int64_t)(1ULL << (RF_KBC_BITS - 1)))
#define RF_KBC_MASK ((uint64_t)((1ULL << (RF_KBC_BITS)) - 1ULL))

#define RF_PNCO_BITS 18
#define RF_PNCO_MIN -180
#define RF_PNCO_MAX (180 - (360 / ldexpl(1.0L, 18)))

#define RF_IQ_BITS 14

#define RF_DEPTH 16
#define RF_REG_PER_INSN 4
#define RF_SEQ_REGS (RF_DEPTH * RF_REG_PER_INSN)
#define RF_BRAM_SEQ_REGS BRAM_SEQ_TOTAL(RF_REG_PER_INSN)
#define RF_CTRL_REGS 3
#define RF_STATUS_REGS (RF_REG_PER_INSN + 4)

static const int rf_uio_map[RF_CHANNELS] = {38, 39, 40, 41, 42, 43};

typedef struct {
    uint32_t arm;
    uint32_t sticky_arm;
    uint32_t kbc_mode;
    uint64_t kbc1;
    uint64_t kbc2;
    uint32_t samples;
    uint32_t dsamples;
    uint32_t marker;
} rf_insn_t;

typedef struct {
    int32_t default_I;
    int32_t default_Q;
} rf_ctrl_t;

typedef struct {
    rf_ctrl_t ctrl;
    int64_t nco_freq;
    uint32_t repeat;
    uint32_t len;
    rf_insn_t insns[RF_DEPTH];
    uint32_t seq_regs[RF_SEQ_REGS];
    int32_t ctrl_regs[RF_CTRL_REGS];
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
int rf_read_regs(int rf_channel, uint32_t *seq_regs, uint32_t *ctrl_regs);
int rf_write_regs(int rf_channel, rf_program_t *rf_program, int uartfd);

#endif
