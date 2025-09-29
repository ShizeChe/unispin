`timescale 1ns / 1ps

module dc_stream
   #(parameter INSN_WIDTH=72,
     parameter ITER_WIDTH=10,
     parameter DEPTH=20)
    (input  i_clk, i_rst,

     input  logic [63:0][31:0] i_reg64,

     input  logic i_next,
     output logic o_empty,
     output logic [INSN_WIDTH-1:0] o_insn);

    logic w_last0, w_last0_ff1, w_last0_ff2;

    assign w_last0 = (i_reg64[63] == 'h0);

    always_ff @(posedge i_clk) begin
        w_last0_ff1 <= w_last0;
        w_last0_ff2 <= w_last0_ff1;
    end

    logic w_new_stream;
    assign w_new_stream = (w_last0_ff2 && !w_last0_ff1);

    logic [INSN_WIDTH-1:0] r_dc_stream [0:DEPTH-1];

    logic [$clog2(DEPTH)-1:0] r_load_ptr, w_load_ptr_plus1;

    for (genvar i = 0; i < DEPTH; i++) begin
        always_ff @(posedge i_clk) begin
            if (i_rst)
                r_dc_stream[i] <= 'h0;
            else if (w_new_stream)
                r_dc_stream[i] <= {i_reg64[i*3+2], 
                                   i_reg64[i*3+1], 
                                   i_reg64[i*3]}[INSN_WIDTH-1:0];
        end
    end

    assign o_insn = r_dc_stream[r_load_ptr];

    assign w_load_ptr_plus1 = (r_load_ptr == DEPTH - 1) ? 'd0 : r_load_ptr + 'd1;

    logic w_next_null;
    assign w_next_null = (r_dc_stream[w_load_ptr_plus1] == 'h0) || 
                         (w_load_ptr_plus1 == 'd0);

    logic [ITER_WIDTH:0] r_iters;

    always_ff @(posedge i_clk) begin
        if (i_rst)
            r_iters <= 'd0;
        else if (w_new_stream)
            r_iters <= i_reg64[DEPTH*3][ITER_WIDTH-1:0];
        else if (w_next_null && i_next)
            r_iters <= (r_iters == 'd0) ? 'd0 : r_iters - 'd1;
    end

    always_ff @(posedge i_clk) begin
        if (i_rst) r_load_ptr <= 'd0;
        else if (i_next) begin
            r_load_ptr <= w_next_null ? 'd0 : w_load_ptr_plus1;
        end
    end

    assign o_empty = (r_iters == 'd0);
     
endmodule
