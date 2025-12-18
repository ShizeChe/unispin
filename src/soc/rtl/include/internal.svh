`ifndef INTERNAL_DEFINES
`define INTERNAL_DEFINES

//dc parameters
parameter DC_DAC_WIDTH=20;
parameter DC_SPI_DATA_WIDTH=24;
parameter DC_CYCLE_WIDTH=30;
parameter DC_SEQ_ITER_WIDTH=10;
parameter DC_CORE_ITER_WIDTH=10;
parameter DC_SPI_DVSR_WIDTH=4;
parameter DC_DEPTH=10;
parameter DC_INSN_WIDTH=DC_CORE_ITER_WIDTH+DC_SPI_DVSR_WIDTH+DC_SPI_DATA_WIDTH+DC_DAC_WIDTH+DC_CYCLE_WIDTH+4;
parameter DC_REG_PER_INSN=(DC_INSN_WIDTH+31)/32;
parameter DC_TOTAL_REGS=DC_DEPTH*DC_REG_PER_INSN+2;

typedef struct packed {
    logic [DC_CORE_ITER_WIDTH-1:0] w_iters;
    logic [DC_SPI_DVSR_WIDTH-1:0] w_spi_dvsr;
    logic [DC_SPI_DATA_WIDTH-1:0] w_spi_din;
    logic [DC_DAC_WIDTH-1:0] w_dspi_din;
    logic w_spi_rd;
    logic w_strb_ldac;
    logic [DC_CYCLE_WIDTH-1:0] w_hold_cycles;
    logic w_modify;
    logic w_arm;
} dc_insn_t;

typedef struct {
    logic [$clog2(DC_DEPTH)-1:0] w_addr;
    logic [DC_CORE_ITER_WIDTH-1:0] w_iters;
    logic [DC_SPI_DVSR_WIDTH-1:0] w_spi_dvsr;
    logic [DC_SPI_DATA_WIDTH-1:0] w_spi_din;
    logic [DC_DAC_WIDTH-1:0] w_dspi_din;
    logic w_spi_rd;
    logic w_strb_ldac;
    logic [DC_CYCLE_WIDTH-1:0] w_hold_cycles;
    logic w_modify;
    logic w_arm;
} dc_decode_stg_t;

typedef struct {
    logic [$clog2(DC_DEPTH)-1:0] r_addr;
    logic [DC_CORE_ITER_WIDTH-1:0] r_iters;
    logic [DC_SPI_DVSR_WIDTH-1:0] r_spi_dvsr;
    logic [DC_SPI_DATA_WIDTH-1:0] r_spi_din;
    logic [DC_DAC_WIDTH-1:0] r_dspi_din;
    logic r_spi_rd;
    logic r_strb_ldac;
    logic [DC_CYCLE_WIDTH-1:0] r_hold_cycles;
    logic r_arm;
    logic r_bubble;
} dc_iterate_stg_t;

typedef struct {
    logic [$clog2(DC_DEPTH)-1:0] r_addr;
    logic [DC_CORE_ITER_WIDTH-1:0] r_iter;
    logic [DC_SPI_DVSR_WIDTH-1:0] r_spi_dvsr;
    logic [DC_SPI_DATA_WIDTH-1:0] r_spi_din;
    logic r_spi_rd;
    logic [DC_SPI_DATA_WIDTH-1:0] r_spi_dout;
    logic r_strb_ldac;
    logic [DC_CYCLE_WIDTH-1:0] r_hold_cycles;
    logic r_arm;
    logic r_cs_n;
    logic r_spi_start;
    logic r_spi_done;
} dc_spi_stg_t;

typedef struct {
    logic [$clog2(DC_DEPTH)-1:0] r_addr;
    logic [DC_CORE_ITER_WIDTH-1:0] r_iter;
    logic [DC_SPI_DATA_WIDTH-1:0] r_spi_din;
    logic r_spi_rd;
    logic [DC_DAC_WIDTH-1:0] r_spi_dout;
    logic [DC_DAC_WIDTH-1:0] r_ldac_n;
    logic [DC_CYCLE_WIDTH-1:0] r_cycles_left;
} dc_hold_stg_t;

//rf parameters
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
