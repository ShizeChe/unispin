`default_nettype none
`timescale 1ns / 1ps
`include "include/rf.svh"

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
     parameter TOTAL_REGS=RF_TOTAL_REGS)
    (input  logic i_clk, i_rst,

     input  logic [0:TOTAL_REGS-1][31:0] i_regs,

     output logic [DAC_WIDTH*16-1:0] o_QIx8,

     input  logic i_start,
     output logic o_armed);

    logic w_next, w_empty;
    logic [$clog2(DEPTH)-1:0] w_addr;
    rf_insn_t w_insn, w_insn_modified;

    sequencer #(
        .INSN_WIDTH(INSN_WIDTH),
        .ITER_WIDTH(ITER_WIDTH),
        .DEPTH(DEPTH)
    ) SEQ (
        .i_clk(i_clk),
        .i_rst(i_rst),

        .i_regs(i_regs),

        .o_addr(w_addr),
        .o_insn(w_insn),
        .i_next(w_next),
        .o_empty(w_empty),
        .i_insn_modified(w_insn_modified)
    );

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

        .o_addr(),
        .o_sample_start(),
        .o_sample_end(),
        .o_QIx8(o_QIx8),

        .i_start(i_start),
        .o_armed(o_armed)
    );

endmodule
