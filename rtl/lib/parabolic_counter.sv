`timescale 1ns / 1ps

module parabolic_counter
   #(parameter IW=36,
     parameter OW=18)
    (input  logic i_clk, i_rst,
     input  logic i_set, 
     input  logic [IW-1:0] i_k,
     input  logic [IW-1:0] i_b,
     input  logic [IW-1:0] i_c,
     output logic [OW-1:0] o_p);

    // p[0] = c, p[n] = p[n-1] + v[n-1]
    // v[0] = b, v[n] = kn + b
    // p[n] = kn^2 + (b - k)n + c

    logic [IW-1:0] r_v, r_p;
    logic [IW-1:0] w_out;

    assign w_out = r_p + {{(OW){1'b0}}, 
                   r_p[IW-OW], 
                   {(IW-OW-1){!r_p[IW-OW]}}};

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            r_v <= 'd0;
            r_p <= 'd0;
            o_p <= 'd0;
        end
        else if (i_set) begin
            r_v <= i_b;
            r_p <= i_c;
            o_p <= w_out;
        end
        else begin
            r_v <= r_v + i_k;
            r_p <= r_p + r_v;
            o_p <= w_out;
        end
    end

endmodule
