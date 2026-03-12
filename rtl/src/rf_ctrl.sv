// `default_nettype none
`timescale 1ns / 1ps
`include "rf.svh"

module rf_ctrl
   #(parameter CTRL_REGS=RF_CTRL_REGS,
     parameter IQ_WIDTH=RF_IQ_WIDTH)
    (input  logic i_clk, i_rst,

     input  logic [0:CTRL_REGS-1][31:0] i_regs,
     input  logic [0:CTRL_REGS-1][31:0] i_uregs,

     output rf_ctrl_t o_ctrl);

    logic w_last0, w_last0_ff1, w_last0_ff2;

    assign w_last0 = (i_regs[CTRL_REGS-1] == 'h0);

    always_ff @(posedge i_clk) begin
        w_last0_ff1 <= w_last0;
        w_last0_ff2 <= w_last0_ff1;
    end

    logic w_new_ctrl;
    assign w_new_ctrl = (w_last0_ff2 && !w_last0_ff1);

    logic w_ulast0, w_ulast0_ff1, w_ulast0_ff2;

    assign w_ulast0 = (i_uregs[CTRL_REGS-1] == 'h0);

    always_ff @(posedge i_clk) begin
        w_ulast0_ff1 <= w_ulast0;
        w_ulast0_ff2 <= w_ulast0_ff1;
    end

    logic w_new_uctrl;
    assign w_new_uctrl = (w_ulast0_ff2 && !w_ulast0_ff1);

    logic [IQ_WIDTH-1:0] r_default_I;
    logic [IQ_WIDTH-1:0] r_default_Q;

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            r_default_I <= 'h0;
            r_default_Q <= 'h0;
        end
        else if (w_new_uctrl) begin
            r_default_I <= i_uregs[0][IQ_WIDTH+1:2];
            r_default_Q <= i_uregs[0][IQ_WIDTH+17:18];
        end
        else if (w_new_ctrl) begin
            r_default_I <= i_regs[0][IQ_WIDTH+1:2];
            r_default_Q <= i_regs[0][IQ_WIDTH+17:18];
        end
    end

    assign o_ctrl = '{
        w_default_I: r_default_I,
        w_default_Q: r_default_Q
    };

endmodule
