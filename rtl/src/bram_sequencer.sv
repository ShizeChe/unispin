// `default_nettype none
`timescale 1ns / 1ps

module bram_sequencer
   #(parameter PC_ADDR_WIDTH=12,
     parameter PC_WIDTH=9,
     parameter INSN_WIDTH=115,
     parameter REG_PER_INSN=(INSN_WIDTH+31)/32,
     parameter ITER_WIDTH=16,
     parameter DEPTH_WIDTH=PC_ADDR_WIDTH,
     parameter SEQ_REGS=REG_PER_INSN+3)
    (input  logic i_clk, i_rst,

     input  logic [0:SEQ_REGS-1][31:0] i_regs,
     output logic o_active,

     output logic [PC_ADDR_WIDTH-1:0] o_pc_addr,
     output logic [PC_WIDTH-1:0] o_pc,
     output logic [INSN_WIDTH-1:0] o_insn,
     input  logic i_next,
     output logic o_empty,
     input  logic [INSN_WIDTH-1:0] i_insn_modified);

    logic w_propagate;

    /*************
    * pcmem store
    *************/

    localparam PCST_ADDR_REG = 0;
    localparam PCST_REG = PCST_ADDR_REG + 1;
    localparam PCST_STRB_REG = PCST_REG + 1;

    logic [PC_ADDR_WIDTH-1:0] w_pcst_addr;
    logic [PC_WIDTH-1:0] w_pcst;
    logic w_pcst_strb, w_pcst_wr;

    assign w_pcst_addr = i_regs[PCST_ADDR_REG][PC_ADDR_WIDTH-1:0];
    assign w_pcst = i_regs[PCST_REG][PC_WIDTH-1:0];
    assign w_pcst_strb = i_regs[PCST_STRB_REG][0];

    edge_detector PCWR (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_signal(w_pcst_strb),
        .o_posedge(w_pcst_wr),
        .o_negedge()
    );

    /************
    * imem store
    ************/

    localparam IST_ADDR_REG = PCST_STRB_REG + 1;
    localparam IST_REG_LO = IST_ADDR_REG + 1;
    localparam IST_REG_HI = IST_REG_LO + REG_PER_INSN - 1;
    localparam IST_STRB_REG = IST_REG_HI + 1;

    logic [PC_WIDTH-1:0] w_ist_addr;
    logic [INSN_WIDTH-1:0] w_ist;
    logic w_ist_strb, w_ist_wr;

    assign w_ist_addr = i_regs[IST_ADDR_REG][PC_WIDTH-1:0];
    assign w_ist = {i_regs[IST_REG_LO:IST_REG_HI]}[INSN_WIDTH-1:0];
    assign w_ist_strb = i_regs[IST_STRB_REG][0];

    edge_detector IWR (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_signal(w_ist_strb),
        .o_posedge(w_ist_wr),
        .o_negedge()
    );

    /**********
    * pc stage
    **********/

    localparam ITERS_REG = IST_STRB_REG + 1;
    localparam DEPTH_REG = ITERS_REG + 1;
    localparam START_STRB_REG = DEPTH_REG + 1;
    localparam HALT_STRB_REG = START_STRB_REG + 1;

    logic [ITERS_WIDTH-1:0] w_iters;
    logic [DEPTH_WIDTH-1:0] w_depth;
    logic w_start_strb;
    logic w_halt_strb;

    assign w_iters = i_regs[ITERS_REG][ITERS_WIDTH-1:0];
    assign w_depth = i_regs[DEPTH_REG][DEPTH_WIDTH-1:0];
    assign w_start_strb = i_regs[START_STRB_REG][0];
    assign w_halt_strb = i_regs[HALT_STRB_REG][0];

    typedef struct {
        logic [PC_ADDR_WIDTH-1:0] r_pc_addr;
        logic [ITER_WIDTH-1:0] r_iters;
        logic [DEPTH_WIDTH-1:0] r_depth;
        logic r_active;
        logic w_start;
        logic w_halt;
    } pc_stg_t;

    pc_stg_t p;

    edge_detector STARTSEQ (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_signal(w_start_strb),
        .o_posedge(p.w_start),
        .o_negedge()
    );

    edge_detector HALTSEQ (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_signal(w_halt_strb),
        .o_posedge(p.w_halt),
        .o_negedge()
    );

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            p.r_pc_addr <= 'bx;
            p.r_iters <= 'd0;
            p.r_depth <= 'd0;
            p.r_active <= 1'b0;
        end
        else if (p.w_halt) begin
            p.r_iters <= 'd0;
            p.r_active <= 1'b0;
        end
        else if (p.w_start && !p.r_active) begin
            p.r_iters <= w_iters;
            p.r_depth <= w_depth;
            p.r_active <= 1'b1;
        end
        else if (w_propagate) begin

            if (p.r_iters > 'd0) begin
                p.r_pc_addr <= (p.r_pc_addr < p.r_depth) ? (p.r_pc_addr + 'd1) : 'd0;
                p.r_iters <= (p.r_pc_addr < p.r_depth) ? p.r_iters : p.r_iters - 'd1;
                p.r_active <= !(p.r_iters == 'd1 && !(p.r_pc_addr < p.r_depth));
            end
            
        end
    end

    assign o_active = p.r_active;

    /************
    * insn stage
    ************/

    typedef struct {
        logic [PC_ADDR_WIDTH-1:0] r_pc_addr;
        logic [PC_WIDTH-1:0] w_pc;
        logic [PC_WIDTH-1:0] r_pc;
        logic r_pc_buffered;
        logic r_pc_valid;
    } insn_stg_t;

    insn_stg_t i;

    logic w_pcmem_wr;

    bram #(
        .DATA_WIDTH(PC_WIDTH),
        .ADDR_WIDTH(PC_ADDR_WIDTH),
    ) PCMEM (
        .i_clk_a(i_clk),
        .i_wr_a(w_pcmem_wr),
        .i_addr_a(w_pcmem_wr_addr),
        .i_din_a(w_pcmem_wr_data),
        .o_dout_a(),

        .i_clk_b(i_clk),
        .i_wr_b(1'b0),
        .i_addr_b(p.r_pc_addr),
        .i_din_b('h0),
        .o_dout_b(i.w_pc)
    );

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            i.r_pc_addr <= 'hx;
            i.r_pc <= 'hx
            i.r_pc_buffered <= 1'b0;
            i.r_pc_valid <= 1'b0;
        end
        else if (w_propagate) begin
            i.r_pc_addr <= p.r_pc_addr;
            i.r_pc <= 'h0;
            i.r_pc_buffered <= 1'b0;
            i.r_pc_valid <= p.r_active;
        end
        else begin
            if (i.r_pc_valid) begin
                i.r_pc <= i.w_pc;
                i.r_pc_buffered <= 1'b1;
            end
        end
    end

    /***********
    * out stage
    ***********/

    typedef struct {
        logic [PC_ADDR_WIDTH-1:0] r_pc_addr;
        logic [PC_WIDTH-1:0] r_pc;
        logic [INSN_WIDTH-1:0] w_insn;
        logic [INSN_WIDTH-1:0] r_insn;
        logic r_insn_buffered;
    };

    bram #(
        .DATA_WIDTH(INSN_WIDTH),
        .ADDR_WIDTH(PC_WIDTH),
    ) IMEM (
        .i_clk_a(i_clk),
        .i_wr_a(w_imem_wr),
        .i_addr_a(w_imem_wr_addr),
        .i_din_a(w_imem_wr_data),
        .o_dout_a(),

        .i_clk_b(i_clk),
        .i_wr_b(),
        .i_addr_b(),
        .i_din_b(),
        .o_dout_b()
    );

endmodule
