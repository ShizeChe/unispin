`ifndef EX_DEFINES
`define EX_DEFINES

parameter EX_REAL_WIDTH=14;
parameter EX_NUM_SAMPLE_WIDTH=20;

typedef struct packed {
    logic w_arm;
    logic [EX_REAL_WIDTH-1:0] w_real;
    logic [EX_NUM_SAMPLE_WIDTH-1:0] w_samples;
    logic [EX_NUM_SAMPLE_WIDTH-1:0] w_dsamples;
} ex_insn_t;

`endif
