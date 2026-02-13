// `default_nettype none
`timescale 1ns / 1ps
`include "li.svh"

module li_core
   #(parameter NUM_SAMPLE_WIDTH=LI_NUM_SAMPLE_WIDTH,
     parameter STRIDE_WIDTH=LI_STRIDE_WIDTH,
     parameter DEPTH=LI_DEPTH,
     parameter ADC_WIDTH=LI_ADC_WIDTH,
     parameter SEQ_REGS=LI_SEQ_REGS,
     parameter CTRL_REGS=LI_CTRL_REGS)
    (input  logic i_clk, i_rst,

     // sequencer interface
     input  logic [$clog2(DEPTH)-1:0] i_addr,
     input  li_insn_t i_insn,
     output logic o_next,
     input  logic i_empty,
     output li_insn_t o_insn_modified,

     // rfadc interface
     input  logic [ADC_WIDTH*16-1:0] i_QIx8,

     // launch interface
     input  logic i_start,
     output logic o_armed,

     // pipeline empty flag
     output logic o_empty,
     
     // output interface
     output logic [ADC_WIDTH*16-1:0] o_QIx8,
     output logic [7:0] o_validx8,

     // eop for verification
     output li_eop_t o_eop);


    /**************
    * decode stage
    **************/

    li_decode_stg_t d;

    li_decode #(
        .DEPTH(DEPTH)
    ) DECODER (
        .i_addr(i_addr),
        .i_insn(i_insn),
        .d(d),
        .o_insn_modified(o_insn_modified)
    );

    /**************
    * sample stage
    **************/

    li_sample_stg_t s;
    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            s <= '{
                r_addr: 'bx,
                r_samples: 'bx,
                r_samples_left: 'd0,
                r_stride: 'bx,
                r_stride_left: 'd0,
                r_arm: 1'b0,
                r_idle: 1'b0
            };
        end
        else if (!w_stall) begin

            if (r_stride_left < 'd8) begin

            end
        end
    end

     
endmodule
