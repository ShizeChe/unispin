`timescale 1ns / 1ps

module async_fifo
   #(parameter DATA_WIDTH=8,
     parameter ADDR_WIDTH=4,
     parameter AF_WINDOW=4,
     parameter AE_WINDOW=4)
    (input  logic                  i_wr_clk, i_wr_rst,
     input  logic [DATA_WIDTH-1:0] i_data,
     input  logic                  i_wr_en,
     output logic                  o_full,
     output logic                  o_almost_full,

     input  logic                  i_rd_clk, i_rd_rst,
     output logic [DATA_WIDTH-1:0] o_data,
     input  logic                  i_rd_en,
     output logic                  o_empty,
     output logic                  o_almost_empty);

    localparam DEPTH=2**ADDR_WIDTH;

    logic [DATA_WIDTH-1:0] r_data [DEPTH];

    // write clock domain address signals
    logic [ADDR_WIDTH-1:0] r_wr_addr;
    logic [ADDR_WIDTH-1:0] w_rd_addr_gray, r_rd_addr_gray_ff1, r_rd_addr_gray_ff2;
    logic [ADDR_WIDTH-1:0] w_rd_addr_sync;

    // read clock domain address signals
    logic [ADDR_WIDTH-1:0] r_rd_addr;
    logic [ADDR_WIDTH-1:0] w_wr_addr_gray, r_wr_addr_gray_ff1, r_wr_addr_gray_ff2;
    logic [ADDR_WIDTH-1:0] w_wr_addr_sync;

    // write clock domain
    always_ff @(posedge i_wr_clk) begin
        if (i_wr_rst) begin
            r_wr_addr <= 'h0;
        end
        else if (i_wr_en && !o_full) begin
            r_data[r_wr_addr] <= i_data;
            r_wr_addr <= r_wr_addr + 'd1;
        end
    end

    // synchronize w_rd_addr_gray from read clock domain
    always_ff @(posedge i_wr_clk) begin
        if (i_wr_rst) begin
            r_rd_addr_gray_ff1 <= 'h0;
            r_rd_addr_gray_ff2 <= 'h0;
        end
        else begin
            r_rd_addr_gray_ff1 <= w_rd_addr_gray;
            r_rd_addr_gray_ff2 <= r_rd_addr_gray_ff1;
        end
    end

    gray2bin #(
        .WIDTH(ADDR_WIDTH)
    ) RD_ADDR_G2B (
        .i_gray(r_rd_addr_gray_ff2),
        .o_bin(w_rd_addr_sync)
    );

    // infer o_full and o_almost_full from w_rd_addr_sync
    assign o_full = (r_wr_addr - w_rd_addr_sync) > DEPTH - 2; 
    assign o_almost_full = (r_wr_addr - w_rd_addr_sync) > DEPTH - 2 - AF_WINDOW; 

    // convert r_wr_addr to gray code for read domain synchronization
    bin2gray #(
        .WIDTH(ADDR_WIDTH)
    ) WR_ADDR_B2G (
        .i_bin(r_wr_addr),
        .o_gray(w_wr_addr_gray)
    );

    // read clock domain
    always_ff @(posedge i_rd_clk) begin
        if (i_rd_rst) begin
            o_data <= 'h0;
            r_rd_addr <= 'h0;
        end
        else if (i_rd_en && !o_empty) begin
            o_data <= r_data[r_rd_addr];
            r_rd_addr <= r_rd_addr + 'd1;
        end
    end

    // synchronize w_wr_addr_gray from write clock domain
    always_ff @(posedge i_rd_clk) begin
        if (i_rd_rst) begin
            r_wr_addr_gray_ff1 <= 'h0;
            r_wr_addr_gray_ff2 <= 'h0;
        end
        else begin
            r_wr_addr_gray_ff1 <= w_wr_addr_gray;
            r_wr_addr_gray_ff2 <= r_wr_addr_gray_ff1;
        end
    end

    gray2bin #(
        .WIDTH(ADDR_WIDTH)
    ) WR_ADDR_G2B (
        .i_gray(r_wr_addr_gray_ff2),
        .o_bin(w_wr_addr_sync)
    );

    // infer o_empty and o_almost_empty from w_wr_addr_sync
    assign o_empty = (w_wr_addr_sync - r_rd_addr) < 1;
    assign o_almost_empty = (w_wr_addr_sync - r_rd_addr) < 1 + AE_WINDOW;

    // conver r_rd_addr to gray code for write domain synchronization
    bin2gray #(
        .WIDTH(ADDR_WIDTH)
    ) RD_ADDR_B2G (
        .i_bin(r_rd_addr),
        .o_gray(w_rd_addr_gray)
    );
    
endmodule
