`ifndef LI_DEFINES
`define LI_DEFINES

parameter LI_NUM_SAMPLE_WIDTH=20;
parameter LI_STRIDE_WIDTH=18;
parameter LI_INSN_WIDTH=LI_NUM_SAMPLE_WIDTH*2+LI_STRIDE_WIDTH+2;
parameter LI_DEPTH=16;
parameter LI_ADC_WIDTH=16;

parameter LI_IQ_WIDTH=14;

parameter LI_REG_PER_INSN=(LI_INSN_WIDTH+31)/32;
parameter LI_SEQ_REGS=LI_DEPTH*LI_REG_PER_INSN+2;
parameter LI_CTRL_REGS=3;

typedef struct packed {
    logic w_arm;
    logic w_idle;
    logic [LI_NUM_SAMPLE_WIDTH-1:0] w_samples;
    logic [LI_NUM_SAMPLE_WIDTH-1:0] w_dsamples;
    logic [LI_STRIDE_WIDTH-1:0] w_stride;
} li_insn_t;

typedef struct {
    logic [$clog2(LI_DEPTH)-1:0] w_addr;
    logic w_arm;
    logic w_idle;
    logic [LI_NUM_SAMPLE_WIDTH-1:0] w_samples;
    logic [LI_NUM_SAMPLE_WIDTH-1:0] w_dsamples;
    logic [LI_STRIDE_WIDTH-1:0] w_stride;
} li_decode_stg_t;

typedef struct {
    logic [$clog2(LI_DEPTH)-1:0] r_addr;
    logic [LI_NUM_SAMPLE_WIDTH-1:0] r_samples;
    logic [LI_NUM_SAMPLE_WIDTH-1:0] r_samples_left;
    logic [LI_NUM_SAMPLE_WIDTH-1:0] w_samples_next;
    logic [LI_STRIDE_WIDTH-1:0] r_stride;
    logic [LI_STRIDE_WIDTH-1:0] r_stride_left;
    logic [LI_STRIDE_WIDTH-1:0] w_stride_next;
    logic [7:0] w_validx8;
    logic w_done;
    logic r_arm;
    logic r_idle;
} li_sample_stg_t;

typedef struct {
    logic [$clog2(LI_DEPTH)-1:0] r_addr;
    logic [LI_ADC_WIDTH*8-1:0] r_Ix8;
    logic [LI_ADC_WIDTH*8-1:0] r_Qx8;
    logic [7:0] r_validx8;
    logic r_last;
} li_output_stg_t;

// eop = end of pipeline
typedef struct packed {
    logic [$clog2(LI_DEPTH)-1:0] w_addr;
    logic [LI_ADC_WIDTH*8-1:0] w_Ix8;
    logic [LI_ADC_WIDTH*8-1:0] w_Qx8;
    logic [7:0] w_validx8;
    logic w_last;
} li_eop_t;

`endif
