#ifndef DC_H
#define DC_H

#include <stdint.h>

#define NUM_DC_CHANNEL 24
#define INSN_PER_DC_CHANNEL 10
#define REG_PER_DC_CHANNEL 32

#define DC_DAC_BITS 20
#define DC_CYCLE_BITS 30
#define DC_MAX_HOLD_CYCLES ((1u << DC_CYCLE_BITS) - 1u)
#define DC_CORE_ITER_BITS 10
#define DC_MAX_CORE_ITERS ((1u << DC_CORE_ITER_BITS) - 1u)
#define DC_SPI_DVSR 4
#define DC_REG_PER_INSN 3

#define VMAX 10.0
#define VMIN -10.0
#define NS_PER_CYCLE 4
#define DC_MAX_HOLD_NS (DC_MAX_HOLD_CYCLES * NS_PER_CYCLE)
#define MAX_DT (NS_PER_CYCLE * DC_MAX_HOLD_CYCLES)

#define DC_DEPTH 10
#define DC_SEQ_REGS ((DC_DEPTH * DC_REG_PER_INSN) + 2)
#define DC_CTRL_REGS 4

typedef struct {
    uint32_t iters;
    uint32_t spi_din;
    uint32_t dspi_din;
    uint32_t spi_rd;
    uint32_t strb_ldac;
    uint32_t hold_cycles;
    uint32_t modify;
    uint32_t arm;
} dc_insn_t;

typedef struct {
    int32_t dvsr;
    int32_t cs_up_cycles;
    int32_t ldac_cycles;
} dc_ctrl_t;

typedef struct {
    dc_ctrl_t ctrl;
    uint32_t repeat;
    uint32_t len;
    dc_insn_t insns[DC_DEPTH];
    uint32_t seq_regs[DC_SEQ_REGS];
    int32_t ctrl_regs[DC_CTRL_REGS];
} dc_program_t;

typedef struct {
    uint32_t arm;
    uint32_t rd;
    uint32_t has_vplus;
    uint32_t vplus;
    uint32_t ldc;
} dc_opt_t;

typedef struct {
    uint32_t its;
    uint32_t din;
    uint32_t cyc;
    dc_opt_t opt;
} dc_ful_t;

typedef struct {
    double v1;
    double v2;
    uint32_t n;
    uint32_t dt_ns;
    dc_opt_t opt;
} dc_swp_t;

typedef struct {
    double v;
    uint32_t t_ns;
    dc_opt_t opt;
} dc_lvl_t;

typedef struct {
    uint32_t r;
    uint32_t din;
    dc_opt_t opt;
} dc_set_t;

typedef struct {
    uint32_t r;
    dc_opt_t opt;
} dc_get_t;

typedef struct {
    dc_opt_t opt;
} dc_nop_t;

int dc_parse_insn(char *line, dc_insn_t *insn);
void dc_assemble(dc_program_t *prog);
int dc_load_insns(int dc_channel, dc_program_t *dc_program);

#endif
