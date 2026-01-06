`timescale 1ns / 1ps

module rf_stream
   #(parameter INSN_WIDTH=238,
     parameter INSN_BUF_DEPTH=16,
     parameter IPTR_WIDTH=$clog2(INSN_BUF_DEPTH),
     parameter IPTR_BUF_DEPTH=1024,
     parameter INSN_REGS=(INSN_WIDTH+31)/32*INSN_BUF_DEPTH,
     parameter IPTR_REGS=(IPTR_BUF_DEPTH+32/IPTR_WIDTH-1)/(32/IPTR_WIDTH),
     parameter ITER_WIDTH=10,
     parameter TOTAL_REGS=INSN_REGS+IPTR_REGS+2)
    (input  logic i_clk, i_rst,

     input  logic [TOTAL_REGS-1:0][31:0] i_regs,

     input  logic i_next,
     output logic o_empty,
     output logic [INSN_WIDTH-1:0] o_insn);

    // decode to insn, insn pointer, iter, start, regs
    logic [INSN_REGS-1:0][31:0] w_insn_regs;
    logic [IPTR_REGS-1:0][31:0] w_iptr_regs;
    logic [31:0] w_ctrl_reg;
    logic [31:0] w_start_reg;

    assign {w_start_reg, w_ctrl_reg,
            w_iptr_regs, w_insn_regs} = i_regs;

    logic [ITER_WIDTH-1:0] w_iters_bits;
    logic [$clog2(IPTR_BUF_DEPTH)-1:0] w_iptr_last_bits;

    assign {w_iptr_last_bits, w_iters_bits} = w_ctrl_reg[
        $clog2(IPTR_BUF_DEPTH)+ITER_WIDTH-1:0
    ];

    // start stream edge detect
    logic w_last0, w_last0_ff1, w_last0_ff2;

    assign w_last0 = (w_start_reg == 'h0);

    always_ff @(posedge i_clk) begin
        w_last0_ff1 <= w_last0;
        w_last0_ff2 <= w_last0_ff1;
    end

    logic w_new_stream;
    assign w_new_stream = (w_last0_ff2 && !w_last0_ff1);

    // insn buffer and insn pointer buffer
    logic [INSN_WIDTH-1:0] r_insn_buffer [INSN_BUF_DEPTH-1:0];
    logic [IPTR_WIDTH-1:0] r_iptr_buffer [IPTR_BUF_DEPTH-1:0];
    logic [$clog2(IPTR_BUF_DEPTH)-1:0] r_iptr_last;
    logic [ITER_WIDTH-1:0] r_iters;

    localparam REG_PER_INSN = (INSN_WIDTH + 31) / 32;
    localparam IPTR_PER_REG = 32 / IPTR_WIDTH;

    for (genvar i = 0; i < INSN_BUF_DEPTH; i++) begin
        always_ff @(posedge i_clk) begin
            if (i_rst)
                r_insn_buffer[i] <= 'h0;
            else if (w_new_stream)
                r_insn_buffer[i] <= {
                    w_insn_regs[
                        (i+1)*REG_PER_INSN-1:i*REG_PER_INSN
                    ]
                }[INSN_WIDTH-1:0];
        end
    end

    for (genvar i = 0; i < IPTR_REGS; i++) begin
        for (genvar j = 0; j < IPTR_PER_REG; j++) begin
            always_ff @(posedge i_clk) begin
                if (i_rst)
                    r_iptr_buffer[i*IPTR_PER_REG+j] <= 'h0;
                else if (w_new_stream)
                    r_iptr_buffer[i*IPTR_PER_REG+j] <= 
                    w_iptr_regs[i][
                        (j+1)*IPTR_WIDTH-1:j*IPTR_WIDTH
                    ];
            end
        end
    end

    always_ff @(posedge i_clk) begin
        if (i_rst) r_iptr_last <= 'h0;
        else if (w_new_stream)
            r_iptr_last <= w_iptr_last_bits;
    end

    // fetch insn pipeline
    logic w_propagate;

    // r_iters and r_iptr_ptr logic
    logic [$clog2(IPTR_BUF_DEPTH)-1:0] r_iptr_ptr; 

    logic w_next_null;
    assign w_next_null = (r_iptr_ptr == r_iptr_last);

    always_ff @(posedge i_clk) begin
        if (i_rst) r_iters <= 'd0;
        else if (w_new_stream)
            r_iters <= w_iters_bits;
        else if (w_propagate && w_next_null)
            r_iters <= (r_iters == 'd0) ? 'd0 : r_iters - 'd1;
    end

    logic [$clog2(IPTR_BUF_DEPTH)-1:0] w_iptr_ptr_plus1;
    assign w_iptr_ptr_plus1 = (r_iptr_ptr == IPTR_BUF_DEPTH - 1) ? 
                              'd0 : r_iptr_ptr + 'd1;

    always_ff @(posedge i_clk) begin
        if (i_rst) r_iptr_ptr <= 'd0;
        else if (w_propagate)
            r_iptr_ptr <= w_next_null ? 'd0 : w_iptr_ptr_plus1;
    end

    // fetch insn ptr
    logic [IPTR_WIDTH-1:0] w_iptr_fetch;
    assign w_iptr_fetch = r_iptr_buffer[r_iptr_ptr];

    logic w_iptr_bubble;
    assign w_iptr_bubble = (r_iters == 'd0);

    logic r_iptr_bubble;
    logic [IPTR_WIDTH-1:0] r_iptr;

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            r_iptr <= 'h0;
            r_iptr_bubble <= 1'b1;
        end
        else if (w_propagate) begin
            r_iptr <= w_iptr_fetch;
            r_iptr_bubble <= w_iptr_bubble;
        end
    end

    // fetch insn
    logic [INSN_WIDTH-1:0] w_insn_fetch;
    assign w_insn_fetch = r_insn_buffer[r_iptr];

    logic w_insn_bubble;
    assign w_insn_bubble = r_iptr_bubble;

    logic [INSN_WIDTH-1:0] r_insn_fetch;
    logic r_insn_bubble; 

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            r_insn_fetch <= 'h0;
            r_insn_bubble <= 1'b1;
        end
        else begin
            r_insn_fetch <= w_insn_fetch;
            r_insn_bubble <= w_insn_bubble;
        end
    end

    assign w_propagate = (!(w_iptr_bubble && w_insn_bubble && r_insn_bubble) && o_empty) || 
                         (!o_empty && i_next);

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            o_insn <= 'h0;
            o_empty <= 1'b1;
        end
        else if (w_propagate) begin
            o_insn <= r_insn_fetch;
            o_empty <= r_insn_bubble;
        end
    end

endmodule

