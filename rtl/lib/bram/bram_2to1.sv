`timescale 1ns / 1ps

// True dual-port BRAM with 2:1 data width ratio, implemented as two symmetric
// bram instances so Vivado infers actual BRAMs.
// Port A (wide):   DATA_WIDTH_A bits, ADDR_WIDTH_A address bits   (2^ADDR_WIDTH_A wide entries)
// Port B (narrow): DATA_WIDTH_B bits, ADDR_WIDTH_A+1 address bits (2^(ADDR_WIDTH_A+1) narrow entries)
// addr_b[0] selects low (0) or high (1) half; addr_b[ADDR_WIDTH_A:1] indexes the BRAM row.

module bram_2to1
   #(parameter DATA_WIDTH_A = 256,
     parameter DATA_WIDTH_B = DATA_WIDTH_A / 2,
     parameter ADDR_WIDTH_A = 9)
    (input  logic i_clk_a,
     input  logic i_wr_a,
     input  logic [ADDR_WIDTH_A-1:0] i_addr_a,
     input  logic [DATA_WIDTH_A-1:0] i_din_a,
     output logic [DATA_WIDTH_A-1:0] o_dout_a,

     input  logic i_clk_b,
     input  logic i_wr_b,
     input  logic [ADDR_WIDTH_A:0] i_addr_b,
     input  logic [DATA_WIDTH_B-1:0] i_din_b,
     output logic [DATA_WIDTH_B-1:0] o_dout_b);

    logic [DATA_WIDTH_B-1:0] w_dout_a_lo, w_dout_a_hi;
    logic [DATA_WIDTH_B-1:0] w_dout_b_lo, w_dout_b_hi;

    // BRAM_LO: low half of port A; port B even addresses (addr_b[0]==0)
    bram #(
        .DATA_WIDTH(DATA_WIDTH_B),
        .ADDR_WIDTH(ADDR_WIDTH_A)
    ) BRAM_LO (
        .i_clk_a(i_clk_a),
        .i_wr_a(i_wr_a),
        .i_addr_a(i_addr_a),
        .i_din_a(i_din_a[DATA_WIDTH_B-1:0]),
        .o_dout_a(w_dout_a_lo),

        .i_clk_b(i_clk_b),
        .i_wr_b(i_wr_b && !i_addr_b[0]),
        .i_addr_b(i_addr_b[ADDR_WIDTH_A:1]),
        .i_din_b(i_din_b),
        .o_dout_b(w_dout_b_lo)
    );

    // BRAM_HI: high half of port A; port B odd addresses (addr_b[0]==1)
    bram #(
        .DATA_WIDTH(DATA_WIDTH_B),
        .ADDR_WIDTH(ADDR_WIDTH_A)
    ) BRAM_HI (
        .i_clk_a(i_clk_a),
        .i_wr_a(i_wr_a),
        .i_addr_a(i_addr_a),
        .i_din_a(i_din_a[DATA_WIDTH_A-1:DATA_WIDTH_B]),
        .o_dout_a(w_dout_a_hi),

        .i_clk_b(i_clk_b),
        .i_wr_b(i_wr_b && i_addr_b[0]),
        .i_addr_b(i_addr_b[ADDR_WIDTH_A:1]),
        .i_din_b(i_din_b),
        .o_dout_b(w_dout_b_hi)
    );

    assign o_dout_a = {w_dout_a_hi, w_dout_a_lo};

    // Register addr_b[0] to align with the one-cycle BRAM read latency
    logic r_sel_b;
    always_ff @(posedge i_clk_b)
        r_sel_b <= i_addr_b[0];

    assign o_dout_b = r_sel_b ? w_dout_b_hi : w_dout_b_lo;

endmodule
