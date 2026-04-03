// `default_nettype none
`timescale 1ns / 1ps
`include "li.svh"

module li
   #(parameter NUM_SAMPLE_WIDTH=LI_NUM_SAMPLE_WIDTH,
     parameter ITER_WIDTH=LI_ITER_WIDTH,
     parameter STRIDE_WIDTH=LI_STRIDE_WIDTH,
     parameter INSN_WIDTH=LI_INSN_WIDTH,
     parameter DEPTH=LI_DEPTH,
     parameter ADC_WIDTH=LI_ADC_WIDTH,
     parameter AXIBUF_ADDR_WIDTH=LI_AXIBUF_ADDR_WIDTH,
     parameter IQ_WIDTH=LI_IQ_WIDTH,
     parameter SEQ_REGS=LI_SEQ_REGS,
     parameter CTRL_REGS=LI_CTRL_REGS,
     parameter STATUS_REGS=LI_STATUS_REGS)
    (input  logic i_clk, i_rst,

     input  logic [0:SEQ_REGS-1][31:0] i_seq_regs,
     input  logic [0:CTRL_REGS-1][31:0] i_ctrl_regs,
     output logic [0:STATUS_REGS-1][31:0] o_status_regs,

     input  logic [ADC_WIDTH*8-1:0] i_QIx4,

     output logic [3:0] o_sample_mask,

     output logic [ADC_WIDTH*8-1:0] o_QIx4,
     output logic [3:0] o_validx4,
     output logic o_last,

     input  logic i_start,
     output logic o_armed,
     
     output logic o_empty,

     output li_ctrl_t o_ctrl,

     // eop for verification
     output li_eop_t o_eop,

     // from li_save for status report
     input [31:0] i_samples_lost,
     input [AXIBUF_ADDR_WIDTH-1:0] i_samples_inbuf);

    logic w_next, w_empty;
    logic [$clog2(DEPTH)-1:0] w_addr;
    li_insn_t w_insn, w_insn_modified;

    sequencer #(
        .INSN_WIDTH(INSN_WIDTH),
        .ITER_WIDTH(ITER_WIDTH),
        .DEPTH(DEPTH)
    ) SEQ (
        .i_clk(i_clk),
        .i_rst(i_rst),

        .i_regs(i_seq_regs),

        .o_addr(w_addr),
        .o_insn(w_insn),
        .i_next(w_next),
        .o_empty(w_empty),
        .i_insn_modified(w_insn_modified)
    );

    li_core #(
    	.NUM_SAMPLE_WIDTH(NUM_SAMPLE_WIDTH),
        .STRIDE_WIDTH(STRIDE_WIDTH),
        .DEPTH(DEPTH),
        .ADC_WIDTH(ADC_WIDTH),
        .SEQ_REGS(SEQ_REGS),
        .CTRL_REGS(CTRL_REGS)
    ) CORE (
        .i_clk(i_clk),
        .i_rst(i_rst),

        .i_addr(w_addr),
        .i_insn(w_insn),
        .o_next(w_next),
        .i_empty(w_empty),
        .o_insn_modified(w_insn_modified),

        .i_QIx4(i_QIx4),

        .o_sample_mask(o_sample_mask),

        .i_start(i_start),
        .o_armed(o_armed),

        .o_QIx4(o_QIx4),
        .o_validx4(o_validx4),
        .o_last(o_last),

        .o_empty(o_empty),

        .o_eop(o_eop)
    );

    li_ctrl #(
        .CTRL_REGS(CTRL_REGS),
        .IQ_WIDTH(IQ_WIDTH),
        .ADC_WIDTH(ADC_WIDTH)
    ) CTRL (
        .i_clk(i_clk),
        .i_rst(i_rst),

        .i_regs(i_ctrl_regs),

        .o_ctrl(o_ctrl)
    );

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            {o_status_regs[0:3]} <= 128'h0;
            o_status_regs[4] <= 'b11;
            o_status_regs[5] <= 'b0;
            o_status_regs[6] <= 'b0;
        end
        else begin
            {o_status_regs[0:3]} <= i_QIx4;
            o_status_regs[4] <= {
                {(32-3){1'b0}}, 
                o_armed, w_empty, o_empty
            };
            o_status_regs[5] <= i_samples_lost;
            o_status_regs[6] <= {
                {(32-AXIBUF_ADDR_WIDTH){1'b0}},
                i_samples_inbuf
            };
        end
    end

endmodule
