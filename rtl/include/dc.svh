`ifndef DC_DEFINES
`define DC_DEFINES

//dc parameters
parameter DC_DAC_WIDTH=20;
parameter DC_SPI_DATA_WIDTH=24;
parameter DC_CYCLE_WIDTH=30;
parameter DC_SEQ_ITER_WIDTH=10;
parameter DC_CORE_ITER_WIDTH=10;
parameter DC_SPI_DVSR_WIDTH=16;
parameter DC_SPI_CS_UP_WIDTH=16;
parameter DC_SPI_LDAC_WIDTH=16;
parameter DC_DEPTH=10;
parameter DC_INSN_WIDTH=DC_CORE_ITER_WIDTH+DC_SPI_DATA_WIDTH+DC_DAC_WIDTH+DC_CYCLE_WIDTH+4;
parameter DC_REG_PER_INSN=(DC_INSN_WIDTH+31)/32;
parameter DC_SEQ_REGS=DC_DEPTH*DC_REG_PER_INSN+2;
parameter DC_CTRL_REGS=3+1;

typedef struct packed {
    logic [DC_SPI_DVSR_WIDTH-1:0] w_dvsr; // inclusive countdown
    logic [DC_SPI_CS_UP_WIDTH-1:0] w_cs_up_cycles; // inclusive countdown
    logic [DC_SPI_LDAC_WIDTH-1:0] w_ldac_cycles; // inclusive countdown
} dc_ctrl_t;

typedef struct packed {
    logic [DC_CORE_ITER_WIDTH-1:0] w_iters;
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
    logic [DC_SPI_DATA_WIDTH-1:0] r_spi_din;
    logic r_spi_rd;
    logic [DC_SPI_DATA_WIDTH-1:0] r_spi_dout;
    logic r_strb_ldac;
    logic [DC_CYCLE_WIDTH-1:0] r_hold_cycles;
    logic r_arm;
    logic [DC_SPI_CS_UP_WIDTH-1:0] r_cs_up_cycles;
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
    logic [DC_SPI_LDAC_WIDTH-1:0] r_ldac_cycles;
    logic r_ldac_n;
    logic [DC_CYCLE_WIDTH-1:0] r_cycles_left;
} dc_hold_stg_t;

// eop = end of pipeline
typedef struct packed {
    logic [$clog2(DC_DEPTH)-1:0] w_addr;
    logic [DC_CORE_ITER_WIDTH-1:0] w_iter;
    logic [DC_SPI_DATA_WIDTH-1:0] w_spi_din;
    logic w_spi_rd;
    logic [DC_SPI_DATA_WIDTH-1:0] w_spi_dout;
    logic [DC_SPI_LDAC_WIDTH-1:0] w_ldac_cycles;
    logic [DC_CYCLE_WIDTH-1:0] w_cycles_left;
} dc_eop_t;

`endif
