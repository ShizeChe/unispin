`timescale 1ns / 1ps

module bram
   #(parameter DATA_WIDTH=72,
     parameter ADDR_WIDTH=10)
    (input  logic i_clk_a,
     input  logic i_wr_a,
     input  logic [ADDR_WIDTH-1:0] i_addr_a,
     input  logic [DATA_WIDTH-1:0] i_din_a,
     output logic [DATA_WIDTH-1:0] o_dout_a,

     input  logic i_clk_b,
     input  logic i_wr_b,
     input  logic [ADDR_WIDTH-1:0] i_addr_b,
     input  logic [DATA_WIDTH-1:0] i_din_b,
     output logic [DATA_WIDTH-1:0] o_dout_b);

    logic [DATA_WIDTH-1:0] mem [(2**ADDR_WIDTH)-1];

    always_ff @(posedge i_clk_a) begin
        o_dout_a <= mem[i_addr_a];
        if (i_wr_a) begin
            o_dout_a <= i_din_a;
            mem[i_addr_a] <= i_din_a;
        end
    end

    always_ff @(posedge i_clk_b) begin
        o_dout_b <= mem[i_addr_b];
        if (i_wr_b) begin
            o_dout_b <= i_din_b;
            mem[i_addr_b] <= i_din_b;
        end
    end

endmodule
