`timescale 1ns / 1ps

module fifo
   #(parameter WIDTH=8,
     parameter DEPTH=8,
     parameter AF_DEPTH=6,
     parameter AE_DEPTH=2)
    (input  logic i_clk, i_rst,
     input  logic [WIDTH-1:0] i_data,
     input  logic i_enq,
     input  logic i_deq,
     output logic [WIDTH-1:0] o_data,
     output logic o_full, o_empty,
     output logic o_almost_full,
     output logic o_almost_empty);

    logic [WIDTH-1:0] r_data [DEPTH];

    logic [$clog2(DEPTH)-1:0] r_enq_ptr, r_deq_ptr;
    logic [$clog2(DEPTH)-1:0] w_enq_ptr, w_deq_ptr;
    logic [$clog2(DEPTH):0] r_num_data;
    logic [$clog2(DEPTH):0] w_num_data;

    assign o_full = (r_enq_ptr == r_deq_ptr) && (r_num_data == DEPTH);
    assign o_empty = (r_enq_ptr == r_deq_ptr) && (r_num_data == 'd0);

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            r_enq_ptr <= 'd0;
            r_deq_ptr <= 'd0;
            r_num_data <= 'd0;
        end
        else begin
            r_enq_ptr <= w_enq_ptr;
            r_deq_ptr <= w_deq_ptr;
            r_num_data <= w_num_data;
        end
    end

    logic w_enq_en;

    always_comb begin
        if (!o_full && i_enq && !o_empty && i_deq) begin
            w_enq_ptr = (r_enq_ptr == DEPTH - 1) ? 'd0 : r_enq_ptr + 'd1;
            w_deq_ptr = (r_deq_ptr == DEPTH - 1) ? 'd0 : r_deq_ptr + 'd1;
            w_num_data = r_num_data;
            w_enq_en = 1'b1;
        end
        else if (!o_full && i_enq) begin
            w_enq_ptr = (r_enq_ptr == DEPTH - 1) ? 'd0 : r_enq_ptr + 'd1;
            w_deq_ptr = r_deq_ptr;
            w_num_data = r_num_data + 'd1;
            w_enq_en = 1'b1;
        end
        else if (!o_empty && i_deq) begin
            w_enq_ptr = r_enq_ptr;
            w_deq_ptr = (r_deq_ptr == DEPTH - 1) ? 'd0 : r_deq_ptr + 'd1;
            w_num_data = r_num_data - 'd1;
            w_enq_en = 1'b0;
        end
        else begin
            w_enq_ptr = r_enq_ptr;
            w_deq_ptr = r_deq_ptr;
            w_num_data = r_num_data;
            w_enq_en = 1'b0;
        end
    end

    always_ff @(posedge i_clk) begin
        if (w_enq_en) begin
            r_data[r_enq_ptr] <= i_data;
        end
    end

    assign o_data = r_data[r_deq_ptr];
    assign o_almost_full = r_num_data >= AF_DEPTH;
    assign o_almost_empty = r_num_data <= AE_DEPTH;

`ifdef FORMAL

    default clocking @(posedge i_clk); endclocking
    default disable iff (i_rst);

    full: cover property (o_full);
    almost_full: cover property (o_almost_full);
    empty: cover property (o_empty);
    almost_empty: cover property (o_almost_empty);

    no_enq_when_full: assert property (
        o_full |=> $stable(r_enq_ptr)
    );

    no_deq_when_empty: assert property (
        o_empty |=> $stable(r_deq_ptr)
    );

    ring_invariant: assert property (
        r_deq_ptr + r_num_data[$clog2(DEPTH)-1:0] == r_enq_ptr 
    );

    logic [WIDTH-1:0] r_ref_data [DEPTH];
    logic [WIDTH-1:0] r_ref_cycles [DEPTH];

    generate for (genvar i = 0; i < DEPTH; i++) begin : REF_GEN
        always_ff @(posedge i_clk) begin
            if (i_rst) begin
                r_ref_data[i] <= 'h0;
                r_ref_cycles[i] <= 'h0;
            end
            else if (w_enq_en && (w_enq_ptr == i)) begin
                r_ref_data[i] <= i_data;
                r_ref_cycles[i] <= w_num_data - 'd1;
            end
            else if (!o_empty && i_deq) begin
                r_ref_cycles[i] <= r_ref_cycles[i] - 'd1;
            end
        end
    end endgenerate

    generate for (genvar i = 0; i < DEPTH; i++) begin : DATA_INTEGRITY_GEN
        data_integrity: assert property (
            (w_enq_en && (w_enq_ptr == i)) ##[1:$] (r_ref_cycles[i] == 'd0) |-> 
            (o_data == r_ref_data[i])
        );
    end endgenerate

`endif

endmodule

