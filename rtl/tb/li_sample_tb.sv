`default_nettype none
`timescale 1ns / 1ps
`include "include/li.svh"

module li_sample_tb;

    logic w_clk, w_rst;

    logic [LI_NUM_SAMPLE_WIDTH-1:0] r_samples_left, w_samples_next;
    logic [LI_NUM_SAMPLE_WIDTH-1:0] samples;

    logic [LI_STRIDE_WIDTH-1:0] r_stride, r_stride_left, w_stride_next;
    logic [LI_STRIDE_WIDTH-1:0] stride;

    always_ff @(posedge w_clk) begin
        if (w_rst) begin
            r_samples_left <= samples;
            r_stride <= stride;
            r_stride_left <= 'd0;
        end
        else begin
            r_samples_left <= w_samples_next;
            r_stride_left <= w_stride_next;
        end

    end

    logic [7:0] w_validx8;
    logic w_done;

    li_sample DUT (
        .i_samples_left(r_samples_left),
        .o_samples_next(w_samples_next),

        .i_stride(r_stride),
        .i_stride_left(r_stride_left),
        .o_stride_next(w_stride_next),

        .i_idle(1'b0),

        .o_validx8(w_validx8),
        .o_done(w_done)
    );

    initial begin
        w_clk = 1'b0;
        forever #2 w_clk = !w_clk;
    end

    initial begin

        w_rst = 1'b1;
        samples = 'd1024;
        stride = 'd50;
        @(negedge w_clk);
        w_rst = 1'b0;

        wait(w_done);
        $finish;

    end

endmodule
