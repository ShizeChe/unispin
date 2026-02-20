`default_nettype none
`timescale 1ns / 1ps
`include "include/li.svh"

module li_tb;

    logic w_clk, w_rst;

    logic [0:LI_SEQ_REGS-1][31:0] w_seq_regs;
    logic [0:LI_CTRL_REGS-1][31:0] w_ctrl_regs;

    logic [LI_ADC_WIDTH*8-1:0] w_Ix8_in;
    logic [LI_ADC_WIDTH*8-1:0] w_Qx8_in;

    logic [LI_ADC_WIDTH*8-1:0] w_Ix8_out;
    logic [LI_ADC_WIDTH*8-1:0] w_Qx8_out;
    logic [7:0] w_validx8;
    logic w_last;

    logic w_start;
    logic w_armed;
     
    logic w_empty;

    li_eop_t w_eop;

    li #(
        .NUM_SAMPLE_WIDTH(LI_NUM_SAMPLE_WIDTH),
        .STRIDE_WIDTH(LI_STRIDE_WIDTH),
        .INSN_WIDTH(LI_INSN_WIDTH),
        .DEPTH(LI_DEPTH),
        .ADC_WIDTH(LI_ADC_WIDTH),
        .SEQ_REGS(LI_SEQ_REGS),
        .CTRL_REGS(LI_CTRL_REGS)
    ) LI (
        .i_clk(w_clk),
        .i_rst(w_rst),

        .i_seq_regs(w_seq_regs),
        .i_ctrl_regs(w_ctrl_regs),

        .i_seq_uregs({(LI_SEQ_REGS*32){1'b0}}),
        .i_ctrl_uregs({(LI_CTRL_REGS*32){1'b0}}),

        .i_Ix8(w_Ix8_in),
        .i_Qx8(w_Qx8_in),

        .o_Ix8(w_Ix8_out),
        .o_Qx8(w_Qx8_out),
        .o_validx8(w_validx8),
        .o_last(w_last),

        .i_start(w_start),
        .o_armed(w_armed),

        .o_empty(w_empty),
        
        .o_eop(w_eop)
    );

    initial begin
        w_clk = 1'b0;
        forever #2 w_clk = !w_clk;
    end

    initial begin
        w_rst = 1'b1;
        w_seq_regs = 'h0;
        w_Ix8_in = 'h0;
        w_Qx8_in = 'h0;
        w_start = 1'b0;
        @(negedge w_clk);
        w_rst = 1'b0;
    end

endmodule
