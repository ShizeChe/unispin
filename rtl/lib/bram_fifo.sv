`timescale 1ns / 1ps

module bram_fifo
   #(parameter DATA_WIDTH=128,
     parameter ADDR_WIDTH=8)
    (input  logic i_clk, i_rst,
     input  logic [DATA_WIDTH-1:0] i_data,
     input  logic i_enq,
     input  logic i_deq,
     output logic [DATA_WIDTH-1:0] o_data,
     output logic o_full, o_empty,
     output logic [ADDR_WIDTH:0] o_num_data);

    logic [ADDR_WIDTH-1:0] r_rd_addr, r_wr_addr;
    logic [ADDR_WIDTH:0] r_num_data;
    logic w_wr_en;

    logic [DATA_WIDTH-1:0] w_wr_data;
    logic [DATA_WIDTH-1:0] w_rd_data;

    logic r_full, r_empty;

    bram #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) BRAM (
        .i_clk_a(i_clk),
        .i_wr_a(w_wr_en),
        .i_addr_a(r_wr_addr),
        .i_din_a(w_wr_data),
        .o_dout_a(),

        .i_clk_b(i_clk),
        .i_wr_b(1'b0),
        .i_addr_b(r_rd_addr),
        .i_din_b({DATA_WIDTH{1'b0}}),
        .o_dout_b(w_rd_data)
    );

    assign w_wr_data = i_data;
    assign w_wr_en = i_enq && !r_full;

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            r_rd_addr <= 'h0;
            r_wr_addr <= 'h0;
            r_num_data <= 'd0;
            r_full <= 1'b0;
            r_empty <= 1'b1;
        end
        else if (i_enq && !r_full && i_deq && !r_empty) begin
            r_wr_addr <= r_wr_addr + 'd1;
            r_rd_addr <= r_rd_addr + 'd1;
        end
        else if (i_enq && !r_full) begin
            r_wr_addr <= r_wr_addr + 'd1;
            r_num_data <= r_num_data + 'd1;
            r_full <= (r_num_data + 'd1) == {1'b1, {(ADDR_WIDTH){1'b0}}};
            r_empty <= 1'b0;
        end
        else if (i_deq && !r_empty) begin
            r_rd_addr <= r_rd_addr + 'd1;
            r_num_data <= r_num_data - 'd1;
            r_empty <= (r_num_data - 'd1) == 'd0;
            r_full <= 1'b0;
        end
    end

    assign o_full = r_full;
    assign o_empty = r_empty;
    assign o_data = w_rd_data;
    assign o_num_data = r_num_data;

endmodule
