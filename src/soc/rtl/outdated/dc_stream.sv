`timescale 1ns / 1ps

module dc_stream
   #(parameter INSN_WIDTH=72,
     parameter ITER_WIDTH=10,
     parameter DEPTH=20,
     parameter TOTAL_REGS=DEPTH*3+2)
    (input  i_clk, i_rst,

     input  logic [TOTAL_REGS-1:0][31:0] i_regs,

     input  logic i_next,
     output logic o_empty,
     output logic [INSN_WIDTH-1:0] o_insn);

    logic w_last0, w_last0_ff1, w_last0_ff2;

    assign w_last0 = (i_regs[TOTAL_REGS-1] == 'h0);

    always_ff @(posedge i_clk) begin
        w_last0_ff1 <= w_last0;
        w_last0_ff2 <= w_last0_ff1;
    end

    logic w_new_stream;
    assign w_new_stream = (w_last0_ff2 && !w_last0_ff1);

    logic [INSN_WIDTH-1:0] r_dc_stream [0:DEPTH-1];

    for (genvar i = 0; i < DEPTH; i++) begin
        always_ff @(posedge i_clk) begin
            if (i_rst)
                r_dc_stream[i] <= 'h0;
            else if (w_new_stream)
                r_dc_stream[i] <= {i_regs[i*3+2], 
                                   i_regs[i*3+1], 
                                   i_regs[i*3]}[INSN_WIDTH-1:0];
        end
    end

    // fetch insn pipeline
    logic w_propagate;

    // r_iters and r_iptr logic
    logic [$clog2(DEPTH)-1:0] r_iptr, w_iptr_plus1;

    assign w_iptr_plus1 = (r_iptr == DEPTH - 1) ? 'd0 : r_iptr + 'd1;

    logic w_next_null;
    assign w_next_null = (r_dc_stream[w_iptr_plus1] == 'h0) || 
                         (w_iptr_plus1 == 'd0);

    logic [ITER_WIDTH:0] r_iters;

    always_ff @(posedge i_clk) begin
        if (i_rst)
            r_iters <= 'd0;
        else if (w_new_stream)
            r_iters <= i_regs[DEPTH*3][ITER_WIDTH-1:0];
        else if (w_propagate && w_next_null)
            r_iters <= (r_iters == 'd0) ? 'd0 : r_iters - 'd1;
    end

    always_ff @(posedge i_clk) begin
        if (i_rst) r_iptr <= 'd0;
        else if (i_next) begin
            r_iptr <= w_next_null ? 'd0 : w_iptr_plus1;
        end
    end

    // fetch insn
    logic [INSN_WIDTH-1:0] w_insn_fetch;
    logic w_insn_bubble;
    
    assign w_insn_fetch = r_dc_stream[r_iptr];
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
     
endmodule
