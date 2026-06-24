`timescale 1ns / 1ps

// Asymmetric FIFO: enqueue writes DATA_WIDTH_A (wide), dequeue reads DATA_WIDTH_B (narrow).
// DATA_WIDTH_A must be exactly 2*DATA_WIDTH_B.
// ADDR_WIDTH_A is the wide port address width; capacity = 2^(ADDR_WIDTH_A+1) narrow entries
// = 2^ADDR_WIDTH_A wide entries.
// o_num_data counts narrow (DATA_WIDTH_B) entries in the FIFO.

module bram_fifo_2to1
   #(parameter DATA_WIDTH_A = 256,
     parameter DATA_WIDTH_B = DATA_WIDTH_A / 2,
     parameter ADDR_WIDTH_A = 7)
    (input  logic i_clk, i_rst,
     input  logic [DATA_WIDTH_A-1:0] i_data,
     input  logic i_enq,
     input  logic i_deq,
     output logic [DATA_WIDTH_B-1:0] o_data,
     output logic o_full, o_empty,
     output logic [ADDR_WIDTH_A+1:0] o_num_data);

    localparam [ADDR_WIDTH_A+1:0] CAPACITY = 1 << (ADDR_WIDTH_A + 1);

    logic [ADDR_WIDTH_A-1:0]  r_wr_addr;  // wide (port A) write pointer
    logic [ADDR_WIDTH_A:0]    r_rd_addr;  // narrow (port B) read pointer
    logic [ADDR_WIDTH_A+1:0]  r_num_data; // count of narrow entries

    logic [DATA_WIDTH_B-1:0] w_rd_data;

    bram_2to1 #(
        .DATA_WIDTH_A(DATA_WIDTH_A),
        .DATA_WIDTH_B(DATA_WIDTH_B),
        .ADDR_WIDTH_A(ADDR_WIDTH_A)
    ) BRAM (
        .i_clk_a(i_clk),
        .i_wr_a(i_enq && !o_full),
        .i_addr_a(r_wr_addr),
        .i_din_a(i_data),
        .o_dout_a(),

        .i_clk_b(i_clk),
        .i_wr_b(1'b0),
        .i_addr_b(r_rd_addr),
        .i_din_b({DATA_WIDTH_B{1'b0}}),
        .o_dout_b(w_rd_data)
    );

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            r_wr_addr  <= 'h0;
            r_rd_addr  <= 'h0;
            r_num_data <= 'd0;
        end
        else if (i_enq && !o_full && i_deq && !o_empty) begin
            r_wr_addr  <= r_wr_addr + 'd1;
            r_rd_addr  <= r_rd_addr + 'd1;
            r_num_data <= r_num_data + 'd1;  // net: +2 enq, -1 deq
        end
        else if (i_enq && !o_full) begin
            r_wr_addr  <= r_wr_addr + 'd1;
            r_num_data <= r_num_data + 'd2;
        end
        else if (i_deq && !o_empty) begin
            r_rd_addr  <= r_rd_addr + 'd1;
            r_num_data <= r_num_data - 'd1;
        end
    end

    // full when fewer than 2 narrow slots remain (can't fit a wide entry)
    assign o_full     = (r_num_data >= CAPACITY - 'd1);
    assign o_empty    = (r_num_data == 'd0);
    assign o_data     = w_rd_data;
    assign o_num_data = r_num_data;

endmodule
