`timescale 1ns / 1ps

module async_fifo
   #(parameter DATA_WIDTH=8,
     parameter ADDR_WIDTH=4)
    (input  logic                  i_wr_clk, i_wr_rst,
     input  logic [DATA_WIDTH-1:0] i_data,
     input  logic                  i_wr_en,
     output logic                  o_full,

     input  logic                  i_rd_clk, i_rd_rst,
     output logic [DATA_WIDTH-1:0] o_data,
     input  logic                  i_rd_en,
     output logic                  o_empty);

    localparam DEPTH=2**ADDR_WIDTH;

    logic [DATA_WIDTH-1:0] r_data [DEPTH];

    // write clock domain address signals
    logic [ADDR_WIDTH-1:0] r_wr_addr, w_wr_addr_nxt;
    logic w_wr_full_nxt;

    // write clock domain sync chain
    logic [ADDR_WIDTH-1:0] w_rd_addr_gray, r_rd_addr_gray_ff1, r_rd_addr_gray_ff2;
    logic [ADDR_WIDTH-1:0] w_rd_addr_sync;

    // read clock domain address signals
    logic [ADDR_WIDTH-1:0] r_rd_addr, w_rd_addr_nxt;
    logic w_rd_empty_nxt;

    // read clock domain sync chain
    logic [ADDR_WIDTH-1:0] w_wr_addr_gray, r_wr_addr_gray_ff1, r_wr_addr_gray_ff2;
    logic [ADDR_WIDTH-1:0] w_wr_addr_sync;

    /*****************
    * i_wr_clk domain
    *****************/

    always_ff @(posedge i_wr_clk) begin
        if (i_wr_rst) begin
            r_wr_addr <= 'h0;
            o_full <= 1'b0;
        end
        else begin 
            if (i_wr_en && !o_full) begin
                r_data[r_wr_addr] <= i_data;
            end
            r_wr_addr <= w_wr_addr_nxt;
            o_full <= w_wr_full_nxt;
        end
    end

    assign w_wr_addr_nxt = r_wr_addr + {{(ADDR_WIDTH-1){1'b0}}, i_wr_en && !o_full};
    assign w_wr_full_nxt = (w_wr_addr_nxt == w_rd_addr_sync);

    // sync r_rd_addr to i_wr_clk domain
    // r_rd_addr -> w_rd_addr_gray -> r_rd_addr_gray_ff1 -> r_rd_addr_gray_ff1
    // -> w_rd_addr_sync
    bin2gray #(
        .WIDTH(ADDR_WIDTH)
    ) RD_ADDR_B2G (
        .i_bin(r_rd_addr),
        .o_gray(w_rd_addr_gray)
    );

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

    /*****************
    * i_rd_clk domain
    *****************/

    // read clock domain
    always_ff @(posedge i_rd_clk) begin
        if (i_rd_rst) begin
            o_data <= 'h0;
            r_rd_addr <= 'h0;
            o_empty <= 1'b1;
        end
        else begin
            if (i_rd_en && !o_empty) begin
                o_data <= r_data[r_rd_addr];
                r_rd_addr <= r_rd_addr + 'd1;
                o_empty <= ((r_rd_addr + 'd1) == w_wr_addr_sync);
            end
            r_rd_addr <= w_rd_addr_nxt;
            o_empty <= w_rd_empty_nxt;
        end
    end

    assign w_rd_addr_nxt = {{(ADDR_WIDTH-1){1'b0}}, i_rd_en && !o_empty};
    assign w_rd_empty_nxt = (w_rd_addr_nxt == w_wr_addr_sync);

    // sync r_wr_addr to i_rd_clk domain
    // r_wr_addr -> w_wr_addr_gray -> r_wr_addr_gray_ff1 -> r_wr_addr_gray_ff1
    // -> w_wr_addr_sync
    bin2gray #(
        .WIDTH(ADDR_WIDTH)
    ) WR_ADDR_B2G (
        .i_bin(r_wr_addr),
        .o_gray(w_wr_addr_gray)
    );

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

`ifdef FORMAL

    // assume property (
    //     (w_wr_addr_gray == $past(w_wr_addr_gray)) until $rose(i_wr_clk)
    // );

    wr_addr_1bit_change: assert property (
        @(posedge i_wr_clk)
        disable iff (i_wr_rst)
        (w_wr_addr_gray == $past(w_wr_addr_gray)) || $onehot(w_wr_addr_gray ^ $past(w_wr_addr_gray))
    );

    // rd_addr_1bit_change: assert property (
    //     @(posedge i_rd_clk)
    //     disable iff (i_rd_rst)
    //     (w_rd_addr_gray == $past(w_rd_addr_gray)) || $onehot(w_rd_addr_gray ^ $past(w_rd_addr_gray))
    // );

    // logic [ADDR_WIDTH:0] f_num_data;
    //
    // always @(posedge f_gclk) begin
    //     if (i_wr_rst || i_rd_rst) begin
    //         f_num_data <= 0;
    //     end
    //     else begin
    //         if (i_wr_en && !o_full && i_rd_en && !o_empty) begin
    //             f_num_data <= f_num_data;
    //         end
    //         else if (i_wr_en && !o_full) begin
    //             f_num_data = f_num_data + 'd1;
    //         end
    //         else if (i_rd_en && !o_full) begin
    //             f_num_data = f_num_data - 'd1;
    //         end
    //     end
    // end
    //
    // full: assert property (
    //     $rose(o_full) |-> (f_num_data == (2 ** ADDR_WIDTH))
    // );
    //
    // empty: assert property (
    //     $rose(o_empty) |-> (f_num_data == 0)
    // );

`endif 
    
endmodule
