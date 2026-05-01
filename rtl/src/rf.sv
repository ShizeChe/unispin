// `default_nettype none
`timescale 1ns / 1ps
`include "rf.svh"

module rf
   #(parameter KBC_WIDTH=RF_KBC_WIDTH,
     parameter ITER_WIDTH=RF_ITER_WIDTH,
     parameter NUM_SAMPLE_WIDTH=RF_NUM_SAMPLE_WIDTH,
     parameter INSN_WIDTH=RF_INSN_WIDTH,
     parameter IQ_WIDTH=RF_IQ_WIDTH,
     parameter DAC_WIDTH=RF_DAC_WIDTH,
     parameter PHASE_WIDTH=RF_PHASE_WIDTH,
     parameter CORDIC_STAGES=RF_CORDIC_STAGES,
     parameter CORDIC_PAD_ZEROS=RF_CORDIC_PAD_ZEROS,
     parameter DEPTH=RF_DEPTH,
     parameter PC_ADDR_WIDTH=RF_PC_ADDR_WIDTH,
     parameter SEQ_REGS=RF_SEQ_REGS,
     parameter CTRL_REGS=RF_CTRL_REGS)
    (input  logic i_clk, i_rst,

     input  logic [0:SEQ_REGS-1][31:0] i_seq_regs,
     input  logic [0:CTRL_REGS-1][31:0] i_ctrl_regs,

     output logic [INSN_WIDTH-1:0] o_insn_rd,
     output logic [ITER_WIDTH-1:0] o_iters,
     output logic [PC_ADDR_WIDTH-1:0] o_pcmem_depth,
     output logic [$clog2(DEPTH)-1:0] o_pc_rd,

     output logic [DAC_WIDTH*16-1:0] o_QIx8,

     input  logic i_start,
     output logic o_armed,

     output logic o_empty,

     output logic o_marker,

     // eop for verification
     output rf_eop_t o_eop);

    logic w_next, w_empty;
    logic [$clog2(DEPTH)-1:0] w_addr;
    rf_insn_t w_insn, w_insn_modified;

    bram_sequencer #(
        .PC_ADDR_WIDTH(PC_ADDR_WIDTH),
        .PC_WIDTH($clog2(DEPTH)),
        .INSN_WIDTH(INSN_WIDTH),
        .ITER_WIDTH(ITER_WIDTH)
    ) SEQ (
        .i_clk(i_clk),
        .i_rst(i_rst),

        .i_regs(i_seq_regs),
        .o_active(),
        .o_iters(o_iters),
        .o_pcmem_depth(o_pcmem_depth),
        .o_pc_rd(o_pc_rd),
        .o_insn_rd(o_insn_rd),

        .o_pc_addr(),
        .o_pc(w_addr),
        .o_insn(w_insn),
        .i_next(w_next),
        .o_empty(w_empty),
        .i_insn_modified(w_insn_modified)
    );

    rf_ctrl_t w_ctrl;

    rf_core #(
    	.KBC_WIDTH(KBC_WIDTH),
    	.NUM_SAMPLE_WIDTH(NUM_SAMPLE_WIDTH),
    	.INSN_WIDTH(RF_INSN_WIDTH),
        .IQ_WIDTH(IQ_WIDTH),
    	.DAC_WIDTH(DAC_WIDTH),
    	.PHASE_WIDTH(PHASE_WIDTH),
    	.CORDIC_STAGES(CORDIC_STAGES),
    	.CORDIC_PAD_ZEROS(CORDIC_PAD_ZEROS),
        .DEPTH(DEPTH)
    ) CORE (
        .i_clk(i_clk),
        .i_rst(i_rst),

        .i_addr(w_addr),
        .i_insn(w_insn),
        .o_next(w_next),
        .i_empty(w_empty),
        .o_insn_modified(w_insn_modified),

        .i_ctrl(w_ctrl),

        .o_QIx8(o_QIx8),

        .i_start(i_start),
        .o_armed(o_armed),

        .o_empty(o_empty),

        .o_marker(o_marker),

        .o_eop(o_eop)
    );

    rf_ctrl #(
        .CTRL_REGS(CTRL_REGS),
        .IQ_WIDTH(IQ_WIDTH)
    ) CTRL (
        .i_clk(i_clk),
        .i_rst(i_rst),

        .i_regs(i_ctrl_regs),

        .o_ctrl(w_ctrl)
    );

endmodule
