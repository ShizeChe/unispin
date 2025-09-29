`timescale 1ns / 1ps

module fifo
    #(parameter WIDTH=8,
      parameter DEPTH=8,
      parameter AF_DEPTH=6,
      parameter AE_DEPTH=2)
    (input  logic             i_clk, i_rst,
     input  logic [WIDTH-1:0] i_data,
     input  logic             i_enq,
     input  logic             i_deq,
     output logic [WIDTH-1:0] o_data,
     output logic             o_full, o_empty,
     output logic             o_almost_full,
     output logic             o_almost_empty);

    logic [WIDTH-1:0] q_data [DEPTH];

    logic [$clog2(DEPTH)-1:0] q_enq_ptr, q_deq_ptr;
    logic [$clog2(DEPTH)-1:0] d_enq_ptr, d_deq_ptr;
    logic [$clog2(DEPTH):0] q_num_data;
    logic [$clog2(DEPTH):0] d_num_data;

    assign o_full = (q_enq_ptr == q_deq_ptr) && (q_num_data == DEPTH);
    assign o_empty = (q_enq_ptr == q_deq_ptr) && (q_num_data == 'd0);

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            q_enq_ptr <= 'd0;
            q_deq_ptr <= 'd0;
            q_num_data <= 'd0;
        end
        else begin
            q_enq_ptr <= d_enq_ptr;
            q_deq_ptr <= d_deq_ptr;
            q_num_data <= d_num_data;
        end
    end

    logic w_en_enq;

    always_comb begin
        if (!o_full && i_enq && !o_empty && i_deq) begin
            d_enq_ptr = (q_enq_ptr == DEPTH - 1) ? 'd0 : q_enq_ptr + 'd1;
            d_deq_ptr = (q_deq_ptr == DEPTH - 1) ? 'd0 : q_deq_ptr + 'd1;
            d_num_data = q_num_data;
            w_en_enq = 1'b1;
        end
        else if (!o_full && i_enq) begin
            d_enq_ptr = (q_enq_ptr == DEPTH - 1) ? 'd0 : q_enq_ptr + 'd1;
            d_deq_ptr = q_deq_ptr;
            d_num_data = q_num_data + 'd1;
            w_en_enq = 1'b1;
        end
        else if (!o_empty && i_deq) begin
            d_enq_ptr = q_enq_ptr;
            d_deq_ptr = (q_deq_ptr == DEPTH - 1) ? 'd0 : q_deq_ptr + 'd1;
            d_num_data = q_num_data - 'd1;
            w_en_enq = 1'b0;
        end
        else begin
            d_enq_ptr = q_enq_ptr;
            d_deq_ptr = q_deq_ptr;
            d_num_data = q_num_data;
            w_en_enq = 1'b0;
        end
    end

    always_ff @(posedge i_clk) begin
        if (w_en_enq) begin
            q_data[q_enq_ptr] <= i_data;
        end
    end

    assign o_data = q_data[q_deq_ptr];
    assign o_almost_full = q_num_data >= AF_DEPTH;
    assign o_almost_empty = q_num_data <= AE_DEPTH;

endmodule
