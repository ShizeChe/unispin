// `default_nettype none
`timescale 1ns / 1ps

module sequencer
   #(parameter INSN_WIDTH=115,
     parameter ITER_WIDTH=16,
     parameter DEPTH=16,
     parameter REG_PER_INSN=(INSN_WIDTH+31)/32,
     parameter TOTAL_REGS=DEPTH*REG_PER_INSN+2)
    (input  logic i_clk, i_rst,

     input  logic [0:TOTAL_REGS-1][31:0] i_regs,

     output logic [$clog2(DEPTH)-1:0] o_addr,
     output logic [INSN_WIDTH-1:0] o_insn,
     input  logic i_next,
     output logic o_empty,
     input  logic [INSN_WIDTH-1:0] i_insn_modified);

    logic w_last0, w_last0_ff1, w_last0_ff2;

    assign w_last0 = (i_regs[TOTAL_REGS-1] == 'h0);

    always_ff @(posedge i_clk) begin
        w_last0_ff1 <= w_last0;
        w_last0_ff2 <= w_last0_ff1;
    end

    logic w_new_sequence;
    assign w_new_sequence = (w_last0_ff2 && !w_last0_ff1);

    logic [INSN_WIDTH-1:0] r_sequence [0:DEPTH-1];

    logic [$clog2(DEPTH)-1:0] r_iptr_modify;

    for (genvar i = 0; i < DEPTH; i++) begin : SEQUENCE_GEN
        always_ff @(posedge i_clk) begin
            if (i_rst)
                r_sequence[i] <= 'h0;
            else if (w_new_sequence)
                r_sequence[i] <= {i_regs[i*REG_PER_INSN:(i+1)*REG_PER_INSN-1]}[INSN_WIDTH-1:0];
            else if (!o_empty && i_next && r_iptr_modify == i)
                r_sequence[i] <= i_insn_modified;
        end
    end

    // fetch insn pipeline
    logic w_propagate;

    // r_iters and r_iptr logic
    logic [$clog2(DEPTH)-1:0] r_iptr, w_iptr_plus1;

    assign w_iptr_plus1 = (r_iptr == DEPTH - 1) ? 'd0 : r_iptr + 'd1;

    logic w_next_null;
    assign w_next_null = (r_sequence[w_iptr_plus1] == 'h0) || 
                         (w_iptr_plus1 == 'd0);

    logic [ITER_WIDTH:0] r_iters;

    always_ff @(posedge i_clk) begin
        if (i_rst)
            r_iters <= 'd0;
        else if (w_new_sequence)
            r_iters <= i_regs[TOTAL_REGS-2][ITER_WIDTH-1:0];
        else if (w_propagate && w_next_null)
            r_iters <= (r_iters == 'd0) ? 'd0 : r_iters - 'd1;
    end

    always_ff @(posedge i_clk) begin
        if (i_rst || w_new_sequence) r_iptr <= 'd0;
        else if (w_propagate) begin
            r_iptr <= w_next_null ? 'd0 : w_iptr_plus1;
        end
    end

    // fetch insn
    logic [INSN_WIDTH-1:0] w_insn_fetch;
    logic w_insn_bubble;
    
    assign w_insn_fetch = (r_iptr == r_iptr_modify && !o_empty) ? i_insn_modified : r_sequence[r_iptr];
    assign w_insn_bubble = (r_iters == 'd0);

    assign w_propagate = (!w_insn_bubble && o_empty) ||
                         (!o_empty && i_next);

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            o_insn <= 'h0;
            o_empty <= 1'b1;
        end
        else if (w_propagate) begin
            o_insn <= w_insn_fetch;
            o_empty <= w_insn_bubble;
        end
    end

    always_ff @(posedge i_clk) begin
        if (i_rst)
            r_iptr_modify <= 'd0;
        else if (w_propagate)
            r_iptr_modify <= r_iptr;
    end

    assign o_addr = r_iptr_modify;

endmodule
