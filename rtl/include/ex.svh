`ifndef EX_DEFINES
`define EX_DEFINES

parameter EX_REAL_WIDTH=14;
parameter EX_DAC_WIDTH=16;
parameter EX_NUM_SAMPLE_WIDTH=20;

parameter EX_INSN_WIDTH=EX_NUM_SAMPLE_WIDTH*2+EX_REAL_WIDTH+3;

parameter EX_ITER_WIDTH=20;
parameter EX_DEPTH=16;
parameter EX_PC_ADDR_WIDTH=4;
parameter EX_REG_PER_INSN=(EX_INSN_WIDTH+31)/32;
parameter EX_SEQ_REGS=EX_REG_PER_INSN+11;
parameter EX_STATUS_REGS=EX_REG_PER_INSN+4;

typedef struct packed {
    logic w_arm;
    logic w_sticky_arm;
    logic [EX_REAL_WIDTH-1:0] w_real;
    logic [EX_NUM_SAMPLE_WIDTH-1:0] w_samples;
    logic [EX_NUM_SAMPLE_WIDTH-1:0] w_dsamples;
    logic w_marker;
} ex_insn_t;

typedef struct {
    logic [$clog2(EX_DEPTH)-1:0] w_addr;
    logic w_arm;
    logic w_marker;
    logic [EX_REAL_WIDTH-1:0] w_real;
    logic [EX_NUM_SAMPLE_WIDTH-1:0] w_samples;
} ex_decode_stg_t;

typedef struct {
    logic [$clog2(EX_DEPTH)-1:0] r_addr;
    logic r_arm;
    logic r_marker;
    logic [EX_REAL_WIDTH-1:0] r_real;
    logic [EX_NUM_SAMPLE_WIDTH-1:0] r_samples;
    logic [EX_NUM_SAMPLE_WIDTH-1:0] r_samples_left;
    logic [EX_DAC_WIDTH*16-1:0] w_realx16;
} ex_count_stg_t;

typedef struct {
    logic [$clog2(EX_DEPTH)-1:0] r_addr;
    logic [EX_DAC_WIDTH*16-1:0] r_realx16;
    logic r_marker;
} ex_output_stg_t;

// eop = end of pipeline
typedef struct packed {
    logic [$clog2(EX_DEPTH)-1:0] w_addr;
    logic [EX_DAC_WIDTH*16-1:0] w_realx16;
    logic w_marker;
} ex_eop_t;

`endif
