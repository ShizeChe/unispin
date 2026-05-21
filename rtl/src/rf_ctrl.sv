// `default_nettype none
`timescale 1ns / 1ps
`include "rf.svh"

module rf_ctrl
   #(parameter CTRL_REGS=RF_CTRL_REGS,
     parameter IQ_WIDTH=RF_IQ_WIDTH)
    (input  logic i_clk, i_rst,

     input  logic [0:CTRL_REGS-1][31:0] i_regs,

     output rf_ctrl_t o_ctrl);

    logic w_new_ctrl;

    edge_detector CTRLWR (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_signal(i_regs[CTRL_REGS-1][0]),
        .o_posedge(w_new_ctrl),
        .o_negedge()
    );

    logic [IQ_WIDTH-1:0] r_default_I;
    logic [IQ_WIDTH-1:0] r_default_Q;

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            r_default_I <= 'h0;
            r_default_Q <= 'h0;
        end
        else if (w_new_ctrl) begin
            r_default_I <= i_regs[0][IQ_WIDTH-1:0];
            r_default_Q <= i_regs[1][IQ_WIDTH-1:0];
        end
    end

    assign o_ctrl = '{
        w_default_I: r_default_I,
        w_default_Q: r_default_Q
    };

endmodule
