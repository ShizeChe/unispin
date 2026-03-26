// `default_nettype none
`timescale 1ns / 1ps

module edge_detector
    (input  logic i_clk, i_rst,
     input  logic i_signal,
     output logic o_posedge,
     output logic o_negedge);

    logic r_signal_ff1, r_signal_ff2;

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            r_signal_ff1 <= 1'b0;
            r_signal_ff2 <= 1'b0;
        end
        else begin
            r_signal_ff1 <= i_signal;
            r_signal_ff2 <= r_signal_ff1;
        end

        if (i_rst) begin
            o_posedge <= 1'b0;
            o_negedge <= 1'b0;
        end
        else begin
            o_posedge <= !r_signal_ff2 && r_signal_ff1;
            o_negedge <= r_signal_ff2 && !r_signal_ff1;
        end
    end

endmodule
