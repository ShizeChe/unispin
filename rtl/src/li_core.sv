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
     input  logic [ADC_WIDTH*8-1:0] i_Ix8,
     input  logic [ADC_WIDTH*8-1:0] i_Qx8,

     // launch interface
     input  logic i_start,
     output logic o_armed,

     // output interface
     output logic [ADC_WIDTH*8-1:0] o_Ix8,
     output logic [ADC_WIDTH*8-1:0] o_Qx8,
     output logic [7:0] o_validx8,

     // pipeline empty flag
     output logic o_empty,

     // eop for verification
     output li_eop_t o_eop);

    logic w_stall;

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

    li_sample #(
        .NUM_SAMPLE_WIDTH(NUM_SAMPLE_WIDTH),
        .STRIDE_WIDTH(STRIDE_WIDTH)
    ) SAMPLE (
        .i_samples_left(s.r_samples_left),
        .o_samples_next(s.w_samples_next),

        .i_stride(s.r_stride),
        .i_stride_left(s.r_stride_left),
        .o_stride_next(s.w_stride_next)

        .i_idle(s.w_idle),

        .o_validx8(s.w_validx8),
        .o_done(s.w_done)
    );

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

            if (s.w_done && !i_empty) begin
                s <= '{
                    r_addr: d.w_addr,
                    r_samples: d.w_samples,
                    r_samples_left: d.w_samples,
                    r_stride: d.w_stride,
                    r_stride_left: 'd0,
                    r_arm: d.w_arm,
                    r_idle: d.w_idle
                };
            end
            else begin
                s.r_samples_left <= s.w_samples_next;
                s.r_stride_left <= s.w_stride_next;
                s.r_arm <= 1'b0;
            end
            
        end
    end

    /**************
    * output stage
    **************/

    li_output_stg_t o;

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            o <= '{
                r_addr: 'bx,
                r_Ix8: 'bx,
                r_Qx8: 'bx,
                r_validx8: 'h0
                r_last: 1'b1
            };
        end
        else if (!w_stall) begin
            o <= '{
                r_addr: s.r_addr,
                r_Ix8: i_Ix8,
                r_Qx8: i_Qx8,
                r_validx8: s.w_validx8,
                r_last: s.w_done && (s.w_validx8 != 'h0)
            };
        end
    end

    /*************
    * stall logic
    *************/

    assign w_stall = (o_armed && !i_start);

    /****************
    * output signals
    ****************/

    assign o_Ix8 = o.r_Ix8;
    assign o_Qx8 = o.r_Qx8;
    assign o_validx8 = o.r_validx8;

    assign o_armed = s.r_arm;

    assign o_empty = i_empty && s.w_done;

    assign o_eop = '{
        w_addr: o.r_addr,
        w_Ix8: o.r_Ix8,
        w_Qx8: o.r_Qx8,
        w_validx8: o.r_validx8,
        w_last: o.r_last
    };
     
endmodule
