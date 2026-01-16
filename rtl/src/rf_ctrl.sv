// `default_nettype none
`timescale 1ns / 1ps
`include "rf.svh"

module rf_ctrl
   #(parameter CTRL_REGS=RF_CTRL_REGS,
     parameter NCO_FREQ_WIDTH=RF_NCO_FREQ_WIDTH,
     parameter NCO_PHASE_WIDTH=RF_NCO_PHASE_WIDTH,
     parameter NCO_EN_WIDTH=RF_NCO_EN_WIDTH,
     parameter IQ_WIDTH=RF_IQ_WIDTH)
    (input  logic i_clk, i_rst,

     input  logic [0:CTRL_REGS-1][31:0] i_regs,

     output rf_ctrl_t o_ctrl,

     input  logic i_seq_running,
     input  logic i_nco_wait,
     output logic o_nco_wait,

     output logic o_nco_req,
     input  logic i_nco_busy,
     output logic [NCO_FREQ_WIDTH-1:0] o_nco_freq,
     output logic [NCO_PHASE_WIDTH-1:0] o_nco_phase,
     output logic [NCO_EN_WIDTH-1:0] o_nco_en);

    logic w_last0, w_last0_ff1, w_last0_ff2;

    assign w_last0 = (i_regs[CTRL_REGS-1] == 'h0);

    always_ff @(posedge i_clk) begin
        w_last0_ff1 <= w_last0;
        w_last0_ff2 <= w_last0_ff1;
    end

    logic w_new_ctrl;
    assign w_new_ctrl = (w_last0_ff2 && !w_last0_ff1);

    logic [NCO_FREQ_WIDTH-1:0] r_nco_freq;
    logic [NCO_PHASE_WIDTH-1:0] r_nco_phase;
    logic [NCO_EN_WIDTH-1:0] r_nco_en;
    logic [IQ_WIDTH-1:0] r_default_I;
    logic [IQ_WIDTH-1:0] r_default_Q;

    logic r_start;

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            r_start <= 1'b0;
            r_nco_freq <= 'hA3D70A3D71;
            r_nco_phase <= 'h0;
            r_default_I <= 'h0;
            r_default_Q <= 'h0;
        end
        else if (w_new_ctrl && !i_seq_running) begin
            r_start <= 1'b1;
            r_nco_freq <= {i_regs[0], i_regs[1]}[NCO_FREQ_WIDTH-1:0];
            r_nco_phase <= i_regs[2][NCO_PHASE_WIDTH-1:0];
            r_default_I <= i_regs[3][IQ_WIDTH-1:0];
            r_default_Q <= i_regs[4][IQ_WIDTH-1:0];
        end
        else begin
            r_start <= 1'b0;
        end
    end

    assign o_nco_freq = r_nco_freq;
    assign o_nco_phase = r_nco_phase;
    assign o_nco_en = r_nco_en;

    rf_nco_update #(
        .NCO_FREQ_WIDTH(NCO_FREQ_WIDTH),
        .NCO_PHASE_WIDTH(NCO_PHASE_WIDTH),
        .NCO_EN_WIDTH(NCO_EN_WIDTH)
    ) NUPDT (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_wait(i_nco_wait),
        .o_wait(o_nco_wait),
        .i_start(r_start),
        .o_req(o_nco_req),
        .i_busy(i_nco_busy)
    );

    assign o_ctrl = '{
        w_nco_ready: !i_nco_wait && !o_nco_wait,
        w_default_I: r_default_I,
        w_default_Q: r_default_Q
    };

endmodule
