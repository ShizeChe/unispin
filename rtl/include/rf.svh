`ifndef RF_DEFINES
`define RF_DEFINES

parameter RF_KBC_WIDTH=36;
parameter RF_NUM_SAMPLE_WIDTH=20;
parameter RF_INSN_WIDTH=RF_KBC_WIDTH*2+RF_NUM_SAMPLE_WIDTH*2+3;
parameter RF_IQ_WIDTH=14;
parameter RF_DAC_WIDTH=16;
parameter RF_PHASE_WIDTH=18;
parameter RF_CORDIC_STAGES=15;
parameter RF_CORDIC_PAD_ZEROS=8;

parameter RF_ITER_WIDTH=10;
parameter RF_DEPTH=16;
parameter RF_REG_PER_INSN=(RF_INSN_WIDTH+31)/32;
#ifndef RF_H
#define RF_H

#include <stdint.h>

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

#define RF_DAC_HZ 2000000000ULL
#define RF_DAC_GHZ 2.0

#define RF_KBC_MAX  ((int64_t)((1ULL << (RF_KBC_BITS - 1)) - 1ULL))
#define RF_KBC_MIN  (-(int64_t)(1ULL << (RF_KBC_BITS - 1)))
#define RF_KBC_MASK ((uint64_t)((1ULL << (RF_KBC_BITS)) - 1ULL))

#define RF_DEPTH 16

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
    double f1;
    double f2;
    double t_ns;
    rf_opt_t opt;
} rf_chp_t;

typedef struct {
    double phs;
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

int rf_parse_insn(char *line, rf_insn_t *insn);
void rf_assemble(rf_prog_t *prog);
int rf_load_insns(int rf_channel, rf_program_t *rf_program);

#endif
parameter RF_TOTAL_REGS=RF_DEPTH*RF_REG_PER_INSN+2;

//li parameters
parameter LI_ITER_WIDTH=10;
parameter LI_NUM_SAMPLE_WIDTH=30;

// structs

typedef enum logic [1:0] {
    RF_KB = 2'b01,
    RF_BC = 2'b10,
    RF_IDLE = 2'b11
} rf_kbc_mode_t;

typedef struct packed {
    logic w_arm;
    rf_kbc_mode_t w_kbc_mode;
    logic [RF_KBC_WIDTH-1:0] w_kbc1;
    logic [RF_KBC_WIDTH-1:0] w_kbc2;
    logic [RF_NUM_SAMPLE_WIDTH-1:0] w_samples;
    logic [RF_NUM_SAMPLE_WIDTH-1:0] w_dsamples;
} rf_insn_t;

typedef struct {
    logic [$clog2(RF_DEPTH)-1:0] w_addr;
    logic [RF_KBC_WIDTH-1:0] w_k;
    logic [RF_KBC_WIDTH-1:0] w_b;
    logic [RF_KBC_WIDTH-1:0] w_c;
    logic [RF_NUM_SAMPLE_WIDTH-1:0] w_samples;
    logic w_arm;
    logic w_idle;
    logic w_set_phasor;
} rf_decode_stg_t;

typedef struct {
    logic [$clog2(RF_DEPTH)-1:0] r_addr;
    logic [RF_KBC_WIDTH-1:0] r_k;
    logic [RF_KBC_WIDTH-1:0] r_b;
    logic [RF_KBC_WIDTH-1:0] r_c;
    logic [RF_NUM_SAMPLE_WIDTH-1:0] r_samples;
    logic [RF_NUM_SAMPLE_WIDTH-1:0] r_samples_left;
    logic r_arm;
    logic r_idle;
    logic [7:0] w_zerox8;
    logic [7:0][RF_PHASE_WIDTH-1:0] w_phasex8;
} rf_phase_stg_t;

typedef struct {
    logic [$clog2(RF_DEPTH)-1:0] r_addr;
    logic [RF_NUM_SAMPLE_WIDTH-1:0] r_sample;
    logic [RF_PHASE_WIDTH-1:0] r_phase_left;
    logic signed [RF_IQ_WIDTH+RF_CORDIC_PAD_ZEROS-1:0] r_x;
    logic signed [RF_IQ_WIDTH+RF_CORDIC_PAD_ZEROS-1:0] r_y;
    logic r_bubble;
    logic r_zero;
    logic r_arm;
} rf_cordic_stg_t;

typedef struct {
    logic [$clog2(RF_DEPTH)-1:0] r_addr;
    logic [RF_NUM_SAMPLE_WIDTH-1:0] r_sample;
    logic [RF_IQ_WIDTH-1:0] r_Q;
    logic [RF_IQ_WIDTH-1:0] r_I;
    logic r_bubble;
    logic r_arm;
} rf_result_stg_t;

parameter logic [RF_DAC_WIDTH-RF_IQ_WIDTH-1:0] PAD = 'b0;

`endif
