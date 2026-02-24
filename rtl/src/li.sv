// `default_nettype none
`timescale 1ns / 1ps
`include "li.svh"

module li
   #(parameter NUM_SAMPLE_WIDTH=LI_NUM_SAMPLE_WIDTH,
     parameter ITER_WIDTH=LI_ITER_WIDTH,
     parameter STRIDE_WIDTH=LI_STRIDE_WIDTH,
     parameter INSN_WIDTH=LI_INSN_WIDTH,
     parameter DEPTH=LI_DEPTH,
     parameter ADC_WIDTH=LI_ADC_WIDTH,
     parameter SEQ_REGS=LI_SEQ_REGS,
     parameter CTRL_REGS=LI_CTRL_REGS)
    (input  logic i_clk, i_rst,

     input  logic [0:SEQ_REGS-1][31:0] i_seq_regs,
     input  logic [0:CTRL_REGS-1][31:0] i_ctrl_regs,

     input  logic [0:SEQ_REGS-1][31:0] i_seq_uregs,
     input  logic [0:CTRL_REGS-1][31:0] i_ctrl_uregs,

     input  logic [ADC_WIDTH*8-1:0] i_Ix8,
     input  logic [ADC_WIDTH*8-1:0] i_Qx8,

     output logic [7:0] o_sample_mask,

     output logic [ADC_WIDTH*8-1:0] o_Ix8,
     output logic [ADC_WIDTH*8-1:0] o_Qx8,
     output logic [7:0] o_validx8,
     output logic o_last,

     input  logic i_start,
     output logic o_armed,
     
     output logic o_empty,

     // eop for verification
     output li_eop_t o_eop);

    logic w_next, w_empty;
    logic [$clog2(DEPTH)-1:0] w_addr;
    li_insn_t w_insn, w_insn_modified;

    sequencer #(
        .INSN_WIDTH(INSN_WIDTH),
        .ITER_WIDTH(ITER_WIDTH),
        .DEPTH(DEPTH)
    ) SEQ (
        .i_clk(i_clk),
        .i_rst(i_rst),

        .i_regs(i_seq_regs),
        .i_uregs(i_seq_uregs),

        .o_addr(w_addr),
        .o_insn(w_insn),
        .i_next(w_next),
        .o_empty(w_empty),
        .i_insn_modified(w_insn_modified)
    );

    li_core #(
    	.NUM_SAMPLE_WIDTH(NUM_SAMPLE_WIDTH),
        .STRIDE_WIDTH(STRIDE_WIDTH),
        .DEPTH(DEPTH),
        .ADC_WIDTH(ADC_WIDTH),
        .SEQ_REGS(SEQ_REGS),
        .CTRL_REGS(CTRL_REGS)
    ) CORE (
        .i_clk(i_clk),
        .i_rst(i_rst),

        .i_addr(w_addr),
        .i_insn(w_insn),
        .o_next(w_next),
        .i_empty(w_empty),
        .o_insn_modified(w_insn_modified),

        .i_Ix8(i_Ix8),
        .i_Qx8(i_Qx8),

        .o_sample_mask(o_sample_mask),

        .i_start(i_start),
        .o_armed(o_armed),

        .o_Ix8(o_Ix8),
        .o_Qx8(o_Qx8),
        .o_validx8(o_validx8),
        .o_last(o_last),

        .o_empty(o_empty),

        .o_eop(o_eop)
    );

endmodule
