// `default_nettype none
`timescale 1ns / 1ps
`include "li.svh"

module li_ctrl
   #(parameter CTRL_REGS=LI_CTRL_REGS,
     parameter IQ_WIDTH=LI_IQ_WIDTH,
     parameter ADC_WIDTH=LI_ADC_WIDTH)
    (input  logic i_clk, i_rst,

     input  logic [0:CTRL_REGS-1][31:0] i_regs,
     input  logic [0:CTRL_REGS-1][31:0] i_uregs,

     output li_ctrl_t o_ctrl);

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

    logic [IQ_WIDTH-1:0] r_default_I, r_default_Q;
    logic [7:0] r_max_burst;
    logic [47:0] r_base_addr;

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            r_default_I <= {1'b0, {(ADC_WIDTH-1){1'b1}}};
            r_default_Q <= {1'b0, {(ADC_WIDTH-1){1'b1}}};
            r_max_burst <= 'd15;
            r_base_addr <= 'h0;
        end
        else if (w_new_uctrl) begin
            r_default_I <= i_uregs[0][ADC_WIDTH-1:0];
            r_default_Q <= i_uregs[1][ADC_WIDTH-1:0];
            r_max_burst <= i_uregs[2][7:0];
            r_base_addr <= {i_uregs[3], i_uregs[4]}[47:0];
        end
        else if (w_new_ctrl) begin
            r_default_I <= i_regs[0][ADC_WIDTH-1:0];
            r_default_Q <= i_regs[1][ADC_WIDTH-1:0];
            r_max_burst <= i_regs[2][7:0];
            r_base_addr <= {i_regs[3], i_regs[4]}[47:0];
        end
    end

    assign o_ctrl.w_default_I = r_default_I;
    assign o_ctrl.w_default_Q = r_default_Q;
    assign o_ctrl.w_max_burst = r_max_burst;
    assign o_ctrl.w_base_addr = r_base_addr;
    assign o_ctrl.w_clear_lost = w_new_uctrl || w_new_ctrl;

endmodule
