// `default_nettype none
`timescale 1ns / 1ps
`include "ex.svh"

module ex
   #(parameter NUM_SAMPLE_WIDTH=EX_NUM_SAMPLE_WIDTH,
     parameter ITER_WIDTH=EX_ITER_WIDTH,
     parameter INSN_WIDTH=EX_INSN_WIDTH,
     parameter REAL_WIDTH=EX_REAL_WIDTH,
     parameter DAC_WIDTH=EX_DAC_WIDTH,
     parameter DEPTH=EX_DEPTH,
     parameter PC_ADDR_WIDTH=EX_PC_ADDR_WIDTH,
     parameter SEQ_REGS=EX_SEQ_REGS)
    (input  logic i_clk, i_rst,

     input  logic [0:SEQ_REGS-1][31:0] i_seq_regs,

     output logic [INSN_WIDTH-1:0] o_insn_rd,
     output logic [ITER_WIDTH-1:0] o_iters,
     output logic [PC_ADDR_WIDTH-1:0] o_pcmem_depth,
     output logic [$clog2(DEPTH)-1:0] o_pc_rd,

     output logic [DAC_WIDTH*16-1:0] o_realx16,

     input  logic i_start,
     output logic o_armed,

     output logic o_empty,

     output logic o_marker,

     // eop for verification
     output ex_eop_t o_eop);

    logic w_next, w_empty;
    logic [$clog2(DEPTH)-1:0] w_addr;
    ex_insn_t w_insn, w_insn_modified;

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

    ex_core #(
    	.NUM_SAMPLE_WIDTH(NUM_SAMPLE_WIDTH),
    	.INSN_WIDTH(INSN_WIDTH),
        .REAL_WIDTH(REAL_WIDTH),
    	.DAC_WIDTH(DAC_WIDTH),
        .DEPTH(DEPTH)
    ) CORE (
        .i_clk(i_clk),
        .i_rst(i_rst),

        .i_addr(w_addr),
        .i_insn(w_insn),
        .o_next(w_next),
        .i_empty(w_empty),
        .o_insn_modified(w_insn_modified),

        .o_realx16(o_realx16),

        .i_start(i_start),
        .o_armed(o_armed),

        .o_empty(o_empty),

        .o_marker(o_marker),

        .o_eop(o_eop)
    );

endmodule
