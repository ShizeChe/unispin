`ifndef LI_DEFINES
`define LI_DEFINES

parameter LI_NUM_SAMPLE_WIDTH=20;
parameter LI_STRIDE_WIDTH=18;
parameter LI_INSN_WIDTH=LI_NUM_SAMPLE_WIDTH*2+LI_STRIDE_WIDTH+4;
parameter LI_ITER_WIDTH=20;
parameter LI_DEPTH=512;
parameter LI_PC_ADDR_WIDTH=12;
parameter LI_ADC_WIDTH=16;

parameter LI_IQ_WIDTH=14;

parameter LI_REG_PER_INSN=(LI_INSN_WIDTH+31)/32;
parameter LI_SEQ_REGS=LI_REG_PER_INSN+11;
parameter LI_CTRL_REGS=4;
parameter LI_STATUS_REGS=LI_REG_PER_INSN+6;

parameter LI_AXIBUF_ADDR_WIDTH=8;

typedef struct packed {
    logic [LI_IQ_WIDTH-1:0] w_default_I;
    logic [LI_IQ_WIDTH-1:0] w_default_Q;
    logic [7:0] w_max_burst;
    logic [48:0] w_base_addr;
    logic w_clear_lost;
} li_ctrl_t;

typedef struct packed {
    logic w_arm;
    logic w_sticky_arm;
    logic w_idle;
    logic w_marker;
    logic [LI_NUM_SAMPLE_WIDTH-1:0] w_samples;
    logic [LI_NUM_SAMPLE_WIDTH-1:0] w_dsamples;
    logic [LI_STRIDE_WIDTH-1:0] w_stride;
} li_insn_t;

typedef struct {
    logic [$clog2(LI_DEPTH)-1:0] w_addr;
    logic w_arm;
    logic w_idle;
    logic w_marker;
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
    logic [3:0] w_validx4;
    logic w_done;
    logic r_done;
    logic r_idle;
    logic r_marker;
    logic [LI_ADC_WIDTH*8-1:0] w_QIx4;
    logic w_last;
} li_sample_stg_t;

typedef struct {
    logic [$clog2(LI_DEPTH)-1:0] r_addr;
    logic [LI_ADC_WIDTH*8-1:0] r_QIx4;
    logic [3:0] r_validx4;
    logic r_last;
    logic [3:0][1:0] w_validx4_scan;
    logic [3:0][1:0] w_validx4_shftamt;
    logic [3:0][6:0] w_QIx4_shftamt;
    logic [3:0][3:0] w_validx4_shift;
    logic [3:0][LI_ADC_WIDTH*8-1:0] w_QIx4_shift;
    logic [3:0] w_validx4_packed;
    logic [LI_ADC_WIDTH*8-1:0] w_QIx4_packed;
    logic [2:0] w_samples;
} li_pack_stg_t;

typedef struct {
    logic [$clog2(LI_DEPTH)-1:0] r_addr;
    logic [LI_ADC_WIDTH*8-1:0] r_QIx4;
    logic [3:0] r_validx4;
    logic r_last;
    logic [2:0] r_samples;
    logic [15:0] w_validx8_aligned;
    logic [LI_ADC_WIDTH*16-1:0] w_QIx8_aligned;
    logic w_forward_last;
} li_align_stg_t;

typedef struct {
    logic [$clog2(LI_DEPTH)-1:0] r_addr;
    logic [LI_ADC_WIDTH*8-1:0] r_QIx4;
    logic [3:0] r_validx4;
    logic r_last;
    logic [2:0] r_samples;
    logic [3:0] w_total_samples;
    logic w_full;
    logic [3:0] w_validx4_inbuf;
    logic [LI_ADC_WIDTH*8-1:0] w_QIx4_inbuf;
    logic [3:0] w_validx4_overflow;
    logic [LI_ADC_WIDTH*8-1:0] w_QIx4_overflow;
} li_buffer_stg_t;

typedef struct {
    logic [$clog2(LI_DEPTH)-1:0] r_addr;
    logic [LI_ADC_WIDTH*8-1:0] r_QIx4;
    logic [3:0] r_validx4;
    logic r_last;
} li_output_stg_t;

// eop = end of pipeline
typedef struct packed {
    logic [$clog2(LI_DEPTH)-1:0] w_addr;
    logic [LI_ADC_WIDTH*8-1:0] w_QIx4;
    logic [3:0] w_validx4;
    logic w_last;
} li_eop_t;

typedef struct {
    logic [48:0] r_addr;
    logic [5:0] r_id;
    logic w_dispatch;
    logic [LI_AXIBUF_ADDR_WIDTH:0] r_num_inbuf_post_txn; 
    logic [7:0] w_burst_len;
    logic [12:0] w_bytes2page;
    logic r_flush_buf;
} li_axi_dispatch_stg_t;

typedef struct {
    logic r_valid;
    logic [5:0] r_id;
    logic [48:0] r_addr;
    logic [7:0] r_len;
    logic r_bubble;
    logic w_handshake;
    logic w_done;
    logic r_done;
} li_axi_aw_stg_t;

typedef struct {
    logic r_valid;
    logic [5:0] r_id;
    logic [127:0] w_data;
    logic [7:0] r_len;
    logic r_last;
    logic r_bubble;
    logic w_handshake;
    logic r_hold;
    logic [127:0] r_hold_buf;
    logic w_done;
    logic r_done;
} li_axi_w_stg_t;

typedef struct {
    logic r_ready;
    logic [5:0] r_id;
    logic r_bubble;
    logic w_handshake;
    logic w_ackb;
    logic r_ackb;
    logic w_ackw;
    logic r_ackw;
    logic w_done;
} li_axi_b_stg_t;

`endif
