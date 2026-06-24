// `default_nettype none
`timescale 1ns / 1ps
`include "rf.svh"

module rf_phasor
   #(parameter IW=RF_KBC_WIDTH,
     parameter OW=RF_PHASE_WIDTH)
    (input  logic i_clk, i_rst,
     input  logic i_set, 
     input  logic [IW-1:0] i_k,
     input  logic [IW-1:0] i_b,
     input  logic [IW-1:0] i_c,
     output logic [7:0][OW-1:0] o_p,
     input  logic i_stall);

    logic [7:0][IW-1:0] w_v_start;
    logic [15:0][IW-1:0] w_p_start;
    logic [7:0][IW-1:0] r_v;
    logic [7:0][IW-1:0] r_p;

    assign w_p_start[0] = i_c;
    assign w_p_start[1] = i_b + i_c;
    assign w_p_start[2] = i_k + 2*i_b + i_c;
    assign w_p_start[3] = 3*i_k + 3*i_b + i_c;
    assign w_p_start[4] = 6*i_k + 4*i_b + i_c;
    assign w_p_start[5] = 10*i_k + 5*i_b + i_c;
    assign w_p_start[6] = 15*i_k + 6*i_b + i_c;
    assign w_p_start[7] = 21*i_k + 7*i_b + i_c;
    assign w_p_start[8] = 28*i_k + 8*i_b + i_c;
    assign w_p_start[9] = 36*i_k + 9*i_b + i_c;
    assign w_p_start[10] = 45*i_k + 10*i_b + i_c;
    assign w_p_start[11] = 55*i_k + 11*i_b + i_c;
    assign w_p_start[12] = 66*i_k + 12*i_b + i_c;
    assign w_p_start[13] = 78*i_k + 13*i_b + i_c;
    assign w_p_start[14] = 91*i_k + 14*i_b + i_c;
    assign w_p_start[15] = 105*i_k + 15*i_b + i_c;

    assign w_v_start[0] = 92 * i_k + (i_b << 3);
    assign w_v_start[1] = 100 * i_k + (i_b << 3);
    assign w_v_start[2] = 108 * i_k + (i_b << 3);
    assign w_v_start[3] = 116 * i_k + (i_b << 3);
    assign w_v_start[4] = 124 * i_k + (i_b << 3);
    assign w_v_start[5] = 132 * i_k + (i_b << 3);
    assign w_v_start[6] = 140 * i_k + (i_b << 3);
    assign w_v_start[7] = 148 * i_k + (i_b << 3);

    logic [IW-1:0] r_kx64;

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            r_kx64 <= 'h0;
        end
        else if (i_set) begin
            r_kx64 <= i_k << 6;
        end
    end

    logic [7:0][IW-1:0] w_out;

    for (genvar i = 0; i < 8; i++) begin : PHASEx8

        always_comb begin
            if (i_set) begin
                w_out[i] = w_p_start[i] + {{(OW){1'b0}}, 
                           w_p_start[i][IW-OW], 
                           {(IW-OW-1){!w_p_start[i][IW-OW]}}};
            end
            else begin
                w_out[i] = r_p[i] + {{(OW){1'b0}}, 
                           r_p[i][IW-OW], 
                           {(IW-OW-1){!r_p[i][IW-OW]}}};
            end
        end

        always_ff @(posedge i_clk) begin
            if (i_rst) begin
                r_v[i] <= 'd0;
                r_p[i] <= 'd0;
                o_p[i] <= 'd0;
            end
            else if (!i_stall) begin

                if (i_set) begin
                    r_v[i] <= w_v_start[i];
                    r_p[i] <= w_p_start[i + 8];
                    o_p[i] <= w_out[i][IW-1:IW-OW];
                    end
                else begin
                    r_v[i] <= r_v[i] + r_kx64;
                    r_p[i] <= r_p[i] + r_v[i];
                    o_p[i] <= w_out[i][IW-1:IW-OW];
                end

            end
        end

    end

`ifdef FORMAL

    default clocking @(posedge i_clk); endclocking
    default disable iff (i_rst);

    logic [IW-1:0] k, b, c;
    logic [IW-1:0] n;

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            k <= 'h0;
            b <= 'h0;
            c <= 'h0;
            n <= 'h0;
        end
        else if (!i_stall && i_set) begin
            k <= i_k;
            b <= i_b;
            c <= i_c;
            n <= 'd0;
        end
        else if (!i_stall) begin
            n <= n + 'd8;
        end
    end

    generate for (genvar i = 0; i < 8; i++) begin
        parabolic: assert property (
            !i_stall |=> (r_p[i] == (k/2 * n * n + (b - k/2) * n + c))
        );
    end endgenerate

`endif

endmodule
