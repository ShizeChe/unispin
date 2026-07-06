`ifndef LI_DEFINES
`define LI_DEFINES

parameter LI_NUM_SAMPLE_WIDTH=20;
parameter LI_STRIDE_WIDTH=18;
parameter LI_INSN_WIDTH=LI_NUM_SAMPLE_WIDTH*2+LI_STRIDE_WIDTH+4;
parameter LI_ITER_WIDTH=20;
parameter LI_DEPTH=512;
parameter LI_PC_ADDR_WIDTH=12;
parameter LI_ADC_WIDTH=16;
parameter LI_SAMPLE_TAG_WIDTH=LI_PC_ADDR_WIDTH+LI_NUM_SAMPLE_WIDTH;

parameter LI_IQ_WIDTH=14;

parameter LI_REG_PER_INSN=(LI_INSN_WIDTH+31)/32;
parameter LI_SEQ_REGS=LI_REG_PER_INSN+11;
parameter LI_CTRL_REGS=6;
parameter LI_STATUS_REGS=LI_REG_PER_INSN+6;

parameter LI_AXIBUF_ADDR_WIDTH=8;

// li_ctrl's i_regs map
parameter LI_DEFAULT_I_REG   = 0;                   // default I sample
parameter LI_DEFAULT_Q_REG   = LI_DEFAULT_I_REG + 1; // default Q sample
parameter LI_MAX_BURST_REG   = LI_DEFAULT_Q_REG + 1; // max AXI burst length
parameter LI_BASE_ADDR_HI_REG = LI_MAX_BURST_REG + 1;  // base_addr[48:32]
parameter LI_BASE_ADDR_LO_REG = LI_BASE_ADDR_HI_REG + 1; // base_addr[31:0]
parameter LI_CTRL_STRB_REG   = LI_CTRL_REGS - 1;    // pulse to latch DEFAULT_I/Q, MAX_BURST, BASE_ADDR above (also clears samples-lost)

// processor's o_li_status_regs map (one bus per li channel)
parameter LI_INSN_RD_REG        = 0;                 // LI_REG_PER_INSN words: last instruction read via ILD_STRB_REG
parameter LI_PC_RD_REG          = LI_REG_PER_INSN;   // PC value read via PCLD_STRB_REG
parameter LI_ITERS_REG          = LI_REG_PER_INSN+1; // iterations remaining in the running program
parameter LI_PCMEM_DEPTH_REG    = LI_REG_PER_INSN+2; // depth (inclusive last address) of the running program
parameter LI_FLAGS_REG          = LI_REG_PER_INSN+3; // {armed, empty}
parameter LI_SAMPLES_LOST_REG   = LI_REG_PER_INSN+4; // count of samples dropped due to AXI buffer overflow
parameter LI_SAMPLES_INBUF_REG  = LI_REG_PER_INSN+5; // samples currently buffered awaiting AXI write

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
    logic [LI_PC_ADDR_WIDTH-1:0] w_pc_addr;
    logic [$clog2(LI_DEPTH)-1:0] w_pc;

    logic w_arm;
    logic w_idle;
    logic w_marker;
    logic [LI_NUM_SAMPLE_WIDTH-1:0] w_samples;
    logic [LI_NUM_SAMPLE_WIDTH-1:0] w_dsamples;
    logic [LI_STRIDE_WIDTH-1:0] w_stride;
} li_decode_stg_t;


typedef struct {
    logic [LI_PC_ADDR_WIDTH-1:0] r_pc_addr;
    logic [$clog2(LI_DEPTH)-1:0] r_pc;

    logic [LI_NUM_SAMPLE_WIDTH-1:0] r_samples;
    logic [LI_NUM_SAMPLE_WIDTH-1:0] r_samples_left;
    logic [LI_NUM_SAMPLE_WIDTH-1:0] w_samples_next;

    logic [LI_STRIDE_WIDTH-1:0] r_stride;
    logic [LI_STRIDE_WIDTH-1:0] r_stride_left;
    logic [LI_STRIDE_WIDTH-1:0] w_stride_next;

    logic [LI_NUM_SAMPLE_WIDTH-1:0] r_index;
    logic [LI_NUM_SAMPLE_WIDTH-1:0] w_index_next;

    logic [3:0] w_validx4;

    logic w_done;
    logic r_done;

    logic r_idle;
    logic r_marker;

    logic [LI_ADC_WIDTH*8-1:0] w_QIx4;
    logic [LI_NUM_SAMPLE_WIDTH*4-1:0] w_indexx4;
    logic [LI_SAMPLE_TAG_WIDTH*4-1:0] w_tagx4;
    logic w_last;
} li_sample_stg_t;


typedef struct {
    logic [LI_PC_ADDR_WIDTH-1:0] r_pc_addr;
    logic [$clog2(LI_DEPTH)-1:0] r_pc;

    logic [LI_ADC_WIDTH*8-1:0] r_QIx4;
    logic [LI_SAMPLE_TAG_WIDTH*4-1:0] r_tagx4;
    logic [3:0] r_validx4;
    logic r_last;

    logic [3:0][1:0] w_validx4_scan;

    logic [3:0][1:0] w_validx4_shftamt;
    logic [3:0][6:0] w_QIx4_shftamt;
    logic [LI_SAMPLE_TAG_WIDTH*4-1:0] w_tagx4_shftamt;

    logic [3:0][3:0] w_validx4_shift;
    logic [3:0][LI_ADC_WIDTH*8-1:0] w_QIx4_shift;
    logic [3:0][LI_SAMPLE_TAG_WIDTH*4-1:0] w_tagx4_shift;

    logic [3:0] w_validx4_packed;
    logic [LI_ADC_WIDTH*8-1:0] w_QIx4_packed;
    logic [LI_SAMPLE_TAG_WIDTH*4-1:0] w_tagx4_packed;

    logic [2:0] w_samples;
} li_pack_stg_t;


typedef struct {
    logic [LI_PC_ADDR_WIDTH-1:0] r_pc_addr;
    logic [$clog2(LI_DEPTH)-1:0] r_pc;

    logic [LI_ADC_WIDTH*8-1:0] r_QIx4;
    logic [LI_SAMPLE_TAG_WIDTH*4-1:0] r_tagx4;
    logic [3:0] r_validx4;
    logic r_last;

    logic [2:0] r_samples;

    logic [7:0] w_validx8_aligned;
    logic [LI_ADC_WIDTH*16-1:0] w_QIx8_aligned;
    logic [LI_SAMPLE_TAG_WIDTH*8-1:0] w_tagx8_aligned;

    logic w_forward_last;
} li_align_stg_t;


typedef struct {
    logic [LI_PC_ADDR_WIDTH-1:0] r_pc_addr;
    logic [$clog2(LI_DEPTH)-1:0] r_pc;

    logic [LI_ADC_WIDTH*8-1:0] r_QIx4;
    logic [LI_SAMPLE_TAG_WIDTH*4-1:0] r_tagx4;
    logic [3:0] r_validx4;
    logic r_last;

    logic [2:0] r_samples;

    logic [3:0] w_total_samples;

    logic w_full;

    logic [3:0] w_validx4_inbuf;
    logic [LI_ADC_WIDTH*8-1:0] w_QIx4_inbuf;
    logic [LI_SAMPLE_TAG_WIDTH*4-1:0] w_tagx4_inbuf;

    logic [3:0] w_validx4_overflow;
    logic [LI_ADC_WIDTH*8-1:0] w_QIx4_overflow;
    logic [LI_SAMPLE_TAG_WIDTH*4-1:0] w_tagx4_overflow;
} li_buffer_stg_t;


typedef struct {
    logic [LI_PC_ADDR_WIDTH-1:0] r_pc_addr;
    logic [$clog2(LI_DEPTH)-1:0] r_pc;

    logic [LI_ADC_WIDTH*8-1:0] r_QIx4;
    logic [LI_SAMPLE_TAG_WIDTH*4-1:0] r_tagx4;
    logic [3:0] r_validx4;
    logic r_last;
} li_output_stg_t;


// eop = end of pipeline
typedef struct packed {
    logic [LI_PC_ADDR_WIDTH-1:0] r_pc_addr;
    logic [$clog2(LI_DEPTH)-1:0] r_pc;
    logic [LI_ADC_WIDTH*8-1:0] w_QIx4;
    logic [LI_SAMPLE_TAG_WIDTH*4-1:0] w_tagx4;
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
