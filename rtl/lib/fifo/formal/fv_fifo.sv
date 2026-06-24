module fv_fifo #(
    parameter WIDTH=8,
    parameter DEPTH=8
) (
    input logic i_clk, i_rst,
    input logic [WIDTH-1:0] i_data,
    input logic i_enq,
    input logic i_deq,
    input logic [WIDTH-1:0] o_data,
    input logic o_full, o_empty,
    input logic o_almost_full,
    input logic o_almost_empty,
    input logic w_enq_en,
    input logic [$clog2(DEPTH)-1:0] w_enq_ptr);

    default clocking @(posedge i_clk); endclocking
    default disable iff (i_rst);

    // assume

    ASM_idle_during_reset: assume property (
        disable iff (1'b0)
        (i_rst |-> (!i_enq && !i_deq))
    );

    ASM_no_enq_on_full: assume property (
        o_full |-> !i_enq
    );

    ASM_no_deq_on_empty: assume property (
        o_empty |-> !i_deq
    );

    // assert

    AST_empty_after_reset: assert property (
        $fell(i_rst) |-> o_empty && !o_full
    );

    logic [$clog2(DEPTH)-1:0] r_ref_cnt;
    
    always_ff @(posedge i_clk) begin
        if (i_rst) r_ref_cnt <= '0;
        else r_ref_cnt <= r_ref_cnt + i_enq - i_deq;
    end

    AST_empty_iff_cnt_zero: assert property (
        o_empty == (r_ref_cnt == '0)
    );

    AST_full_iff_cnt_max: assert property (
        o_full == (r_ref_cnt == DEPTH)
    );

    AST_not_empty_full: assert property (
        !(o_empty && o_full)
    );

    AST_cnt_le_depth: assert property (
        r_ref_cnt <= DEPTH
    );

    AST_cnt_inc_on_enq_only: assert property (
        (i_enq && !i_deq && !o_empty) |=> (r_ref_cnt == $past(r_ref_cnt) + '1)
    );

    AST_cnt_dec_on_deq_only: assert property (
        (!i_enq && i_deq && !o_full) |=> (r_ref_cnt == $past(r_ref_cnt) - '1)
    );

    AST_cnt_hold_on_simul: assert property (
        (i_enq && i_deq && !o_empty && !i_full) |=> (r_ref_cnt == $past(r_ref_cnt))
    );

    AST_no_overflow: assert property (
        o_full && i_enq |-> 1'b0
    );

    AST_no_underflow: assert property (
        o_empty && i_deq |-> 1'b0
    );

    AST_data_stable_no_deq: assert property (
        !i_deq |=> $stable(o_data)
    );


    // cover

    COV_enq: cover property (
        i_enq && !o_full
    );

    COV_deq: cover property (
        i_deq && !o_empty
    );

    COV_simul: cover property (
        i_enq && i_deq && !o_full && !o_empty 
    );

    COV_can_be_full: cover property (
        !o_full ##1 o_full
    );

    COV_can_be_empty: cover property (
        !o_empty ##1 o_empty
    );

    COV_fill_then_drain: cover property (
        o_empty ##[1:$] o_full ##[1:$] o_empty
    );

    COV_enqx2: cover property (
        i_enq ##1 i_enq
    );

    COV_deqx2: cover property (
        i_deq ##1 i_deq
    );

    COV_full_held_4cycle: cover property (
        o_full[*4]
    );

    // model checking

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
        AST_data_integrity: assert property (
            (w_enq_en && !o_full && (w_enq_ptr == i)) ##[1:$] (r_ref_cycles[i] == 'd0) |-> 
            (o_data == r_ref_data[i])
        );
    end endgenerate

);

endmodule

bind fifo fv_fifo #(
    .WIDTH(WIDTH),
    .DEPTH(DEPTH),
    .AF_DEPTH(AF_DEPTH),
    .AE_DEPTH(AE_DEPTH)
) FV_FIFO (
    .*
);

