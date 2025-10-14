`timescale 1ns / 1ps

module rf
   #(parameter KBC_WIDTH=36,
     parameter NUM_SAMPLE_WIDTH=30,
     parameter CORE_ITER_WIDTH=10,
     parameter INSN_WIDTH=KBC_WIDTH*3+CORE_ITER_WIDTH+NUM_SAMPLE_WIDTH*4,
     parameter IQ_WIDTH=14,
     parameter DAC_WIDTH=16,
     parameter PHASE_WIDTH=18,
     parameter CORDIC_STAGES=15,
     parameter CORDIC_PAD_ZEROS=8,

     parameter INSN_BUF_DEPTH=16,
     parameter IPTR_WIDTH=$clog2(INSN_BUF_DEPTH),
     parameter IPTR_BUF_DEPTH=1024,
     parameter INSN_REGS=(INSN_WIDTH+31)/32*INSN_BUF_DEPTH,
     parameter IPTR_REGS=(1024+32/IPTR_WIDTH-1)/(32/IPTR_WIDTH),
     parameter STREAM_ITER_WIDTH=10,
     parameter TOTAL_REGS=INSN_REGS+IPTR_REGS+2,

     parameter REG_PER_INSN = (INSN_WIDTH + 31) / 32,
     parameter IPTR_PER_REG = 32 / IPTR_WIDTH)
    (input  logic i_clk, i_rst,

     input  logic [TOTAL_REGS-1:0][31:0] i_regs,

     output logic [DAC_WIDTH*16-1:0] o_QIx8,

     input  logic i_start,
     output logic o_armed);

    logic w_next, w_empty;
    logic [INSN_WIDTH-1:0] w_insn;

    rf_stream #(
        .INSN_WIDTH(INSN_WIDTH),
        .INSN_BUF_DEPTH(INSN_BUF_DEPTH),
        .IPTR_BUF_DEPTH(IPTR_BUF_DEPTH),
        .ITER_WIDTH(STREAM_ITER_WIDTH)
    ) stream (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_regs(i_regs),
        .i_next(w_next),
        .o_empty(w_empty),
        .o_insn(w_insn)
    );

    rf_core #(
    	.KBC_WIDTH(KBC_WIDTH),
    	.NUM_SAMPLE_WIDTH(NUM_SAMPLE_WIDTH),
    	.ITER_WIDTH(CORE_ITER_WIDTH),
        .IQ_WIDTH(IQ_WIDTH),
    	.DAC_WIDTH(DAC_WIDTH),
    	.PHASE_WIDTH(PHASE_WIDTH),
    	.CORDIC_STAGES(CORDIC_STAGES),
    	.CORDIC_PAD_ZEROS(CORDIC_PAD_ZEROS)
    ) core (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_insn(w_insn),
        .o_next(w_next),
        .i_empty(w_empty),
        .o_QIx8(o_QIx8),
        .i_start(i_start),
        .o_armed(o_armed)
    );

endmodule
