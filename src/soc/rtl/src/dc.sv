`timescale 1ns / 1ps

module dc
   #(parameter DAC_WIDTH=16,
     parameter CYCLE_WIDTH=30,
     parameter STREAM_ITER_WIDTH=10,
     parameter CORE_ITER_WIDTH=10,
     parameter DEPTH=20,
     parameter INSN_WIDTH=DAC_WIDTH*2+CORE_ITER_WIDTH+CYCLE_WIDTH,
     parameter TOTAL_REGS=DEPTH*3+2)
    (input  logic i_clk, i_rst,
     
     input  logic [TOTAL_REGS-1:0][31:0] i_regs,

     output logic o_sclk,
     output logic o_mosi,
     output logic o_cs_n,
     output logic o_ldac_n,

     input  logic i_start,
     output logic o_armed);

    logic w_next, w_empty;
    logic [INSN_WIDTH-1:0] w_insn;

    dc_stream #(
        .INSN_WIDTH(INSN_WIDTH),
        .ITER_WIDTH(STREAM_ITER_WIDTH),
        .DEPTH(DEPTH)
    ) stream (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_regs(i_regs),
        .i_next(w_next),
        .o_empty(w_empty),
        .o_insn(w_insn)
    );

    dc_core #(
        .DAC_WIDTH(DAC_WIDTH),
        .CYCLE_WIDTH(CYCLE_WIDTH),
        .ITER_WIDTH(CORE_ITER_WIDTH)
    ) core (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_insn(w_insn),
        .o_next(w_next),
        .i_empty(w_empty),
        .o_sclk(o_sclk),
        .o_mosi(o_mosi),
        .o_cs_n(o_cs_n),
        .o_ldac_n(o_ldac_n),
        .i_start(i_start),
        .o_armed(o_armed)
    );

endmodule
