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

     output logic [7:0] o_sample_mask,

     // launch interface
     input  logic i_start,
     output logic o_armed,

     // output interface
     output logic [ADC_WIDTH*8-1:0] o_Ix8,
     output logic [ADC_WIDTH*8-1:0] o_Qx8,
     output logic [7:0] o_validx8,
     output logic o_last,

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
        .o_stride_next(s.w_stride_next),

        .i_idle(s.r_idle),

        .o_validx8(s.w_validx8),
        .o_done(s.w_done)
    );

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            s.r_addr <= 'bx;
            s.r_samples <= 'bx;
            s.r_samples_left <= 'd0;
            s.r_stride <= 'bx;
            s.r_stride_left <= 'd0;
            s.r_arm <= 1'b0;
            s.r_idle <= 1'b0;
        end
        else if (!w_stall) begin

            if (s.w_done && !i_empty) begin
                s.r_addr <= d.w_addr;
                s.r_samples <= d.w_samples;
                s.r_samples_left <= d.w_samples;
                s.r_stride <= d.w_stride;
                s.r_stride_left <= 'd0;
                s.r_arm <= d.w_arm;
                s.r_idle <= d.w_idle;
            end
            else begin
                s.r_samples_left <= s.w_samples_next;
                s.r_stride_left <= s.w_stride_next;
                s.r_arm <= 1'b0;
            end
            
        end
    end

    assign s.w_Ix8 = i_Ix8;
    assign s.w_Qx8 = i_Qx8;
    assign s.w_last = s.w_done && (s.w_validx8 != 'h0);

    assign o_next = s.w_done && !i_empty;
    assign o_sample_mask = s.w_validx8;

    /*******************************
    * pack, align and buffer stages
    *******************************/

    li_pack_stg_t p;

    li_pack PACK (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .s(s),
        .p(p),
        .i_stall(w_stall)
    );

    li_align_stg_t a;
    li_buffer_stg_t b;

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            a.r_addr <= 'bx;
            a.r_Ix8 <= 'b0;
            a.r_Qx8 <= 'b0;
            a.r_validx8 <= 8'h0;
            a.r_last <= 1'b0;
            a.r_samples <= 'd0;
        end
        else begin
            a.r_addr <= p.r_addr; 
            a.r_Ix8 <= p.w_Ix8_packed;
            a.r_Qx8 <= p.w_Qx8_packed;
            a.r_validx8 <= p.w_validx8_packed;
            a.r_last <= p.r_last;
            a.r_samples <= p.w_samples;
        end
    end

    assign a.w_validx16_aligned = {8'h0, b.r_validx8} |
        ({8'h0, a.r_validx8} << b.r_samples);

    assign a.w_Ix16_aligned = {{(ADC_WIDTH*8){1'b0}}, b.r_Ix8} |
        ({{(ADC_WIDTH*8){1'b0}}, a.r_Ix8} << {b.r_samples, 4'b0000});

    assign a.w_Qx16_aligned = {{(ADC_WIDTH*8){1'b0}}, b.r_Qx8} |
        ({{(ADC_WIDTH*8){1'b0}}, a.r_Qx8} << {b.r_samples, 4'b0000});

    assign b.w_total_samples = {1'b0, a.r_samples} + {1'b0, b.r_samples};
    assign b.w_full = (b.w_total_samples >= 'd8);

    assign b.w_validx8_inbuf = b.r_last ? b.r_validx8 : a.w_validx16_aligned[7:0];
    assign b.w_Ix8_inbuf = b.r_last ? b.r_Ix8 : a.w_Ix16_aligned[8*ADC_WIDTH-1:0];
    assign b.w_Qx8_inbuf = b.r_last ? b.r_Qx8 : a.w_Qx16_aligned[8*ADC_WIDTH-1:0];

    assign b.w_validx8_overflow = b.r_last ? 'h0 : a.w_validx16_aligned[15:8];
    assign b.w_Ix8_overflow = b.r_last ? 'h0 : a.w_Ix16_aligned[16*ADC_WIDTH-1:8*ADC_WIDTH];
    assign b.w_Qx8_overflow = b.r_last ? 'h0 : a.w_Qx16_aligned[16*ADC_WIDTH-1:8*ADC_WIDTH];

    always_ff @(posedge i_clk) begin
        if (i_rst) begin 
            b.r_addr <= 'bx;
            b.r_Ix8 <= 'b0;
            b.r_Qx8 <= 'b0;
            b.r_validx8 <= 8'h0;
            b.r_last <= 1'b0;
            b.r_samples <= 'd0;
        end
        else if (b.r_last) begin
            b.r_addr <= a.r_addr;
            b.r_Ix8 <= a.r_Ix8;
            b.r_Qx8 <= a.r_Qx8;
            b.r_validx8 <= a.r_validx8;
            b.r_last <= a.r_last;
            b.r_samples <= a.r_samples;
        end
        else begin
            b.r_addr <= a.r_addr;
            b.r_Ix8 <= b.w_full ? b.w_Ix8_overflow : b.w_Ix8_inbuf;
            b.r_Qx8 <= b.w_full ? b.w_Qx8_overflow : b.w_Qx8_inbuf;
            b.r_validx8 <= b.w_full ? b.w_validx8_overflow : b.w_validx8_inbuf;
            b.r_last <= a.r_last;
            b.r_samples <= b.w_full ? (b.w_total_samples - 'd8) : b.w_total_samples;
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
                r_Ix8: 'b0,
                r_Qx8: 'b0,
                r_validx8: 'h0,
                r_last: 1'b0
            };
        end
        else if (b.w_full || b.r_last) begin
            o <= '{
                r_addr: b.r_addr,
                r_Ix8: b.w_Ix8_inbuf,
                r_Qx8: b.w_Qx8_inbuf,
                r_validx8: b.w_validx8_inbuf,
                r_last: b.r_last
            };
        end
        else begin
            o <= '{
                r_addr: 'bx,
                r_Ix8: 'b0,
                r_Qx8: 'b0,
                r_validx8: 'h0,
                r_last: 1'b0
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
    assign o_last = o.r_last;

    assign o_armed = s.r_arm;

    assign o_empty = i_empty && s.w_done && !PACK.p.r_last && 
        !a.r_last && !b.r_last && !o.r_last;

    assign o_eop = '{
        w_addr: o.r_addr,
        w_Ix8: o.r_Ix8,
        w_Qx8: o.r_Qx8,
        w_validx8: o.r_validx8,
        w_last: o.r_last
    };
     
endmodule
