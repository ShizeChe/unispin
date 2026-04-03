// `default_nettype none
`timescale 1ns / 1ps
`include "li.svh"

module li_core
   #(parameter NUM_SAMPLE_WIDTH=LI_NUM_SAMPLE_WIDTH,
     parameter STRIDE_WIDTH=LI_STRIDE_WIDTH,
     parameter DEPTH=LI_DEPTH,
     parameter ADC_WIDTH=LI_ADC_WIDTH,
     parameter SEQ_REGS=LI_SEQ_REGS,
     parameter CTRL_REGS=LI_CTRL_REGS,
     parameter STATUS_REGS=LI_STATUS_REGS)
    (input  logic i_clk, i_rst,

     // sequencer interface
     input  logic [$clog2(DEPTH)-1:0] i_addr,
     input  li_insn_t i_insn,
     output logic o_next,
     input  logic i_empty,
     output li_insn_t o_insn_modified,

     // rfadc interface
     input  logic [ADC_WIDTH*8-1:0] i_QIx4,

     output logic [3:0] o_sample_mask,

     // launch interface
     input  logic i_start,
     output logic o_armed,

     // output interface
     output logic [ADC_WIDTH*8-1:0] o_QIx4,
     output logic [3:0] o_validx4,
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

        .o_validx4(s.w_validx4),
        .o_done(s.w_done)
    );

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            s.r_addr <= 'bx;
            s.r_samples <= 'b0;
            s.r_samples_left <= 'd0;
            s.r_stride <= 'd1;
            s.r_stride_left <= 'd0;
            s.r_idle <= 1'b0;
            s.r_done <= 1'b1;
        end
        else if (!w_stall) begin

            if ((s.w_done || s.r_done) && !i_empty) begin
                s.r_addr <= d.w_addr;
                s.r_samples <= d.w_samples;
                s.r_samples_left <= d.w_samples;
                s.r_stride <= d.w_stride;
                s.r_stride_left <= 'd0;
                s.r_idle <= d.w_idle;
                s.r_done <= 1'b0;
            end
            else begin
                s.r_samples_left <= s.w_samples_next;
                s.r_stride_left <= s.w_stride_next;
                if (!s.r_done)
                    s.r_done <= s.w_done;
            end
            
        end
    end

    assign s.w_QIx4 = i_QIx4;
    assign s.w_last = (s.w_samples_next == 'd0) && (s.w_validx4 != 'h0);

    assign o_next = (s.w_done || s.r_done) && !i_empty && !w_stall;
    assign o_sample_mask = s.w_validx4;

    /************
    * pack stage
    *************/

    li_pack_stg_t p;
    
    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            p.r_addr <= 'bx;
            p.r_QIx4 <= 'bx;
            p.r_validx4 <= 8'h0;
            p.r_last <= 1'b0;
        end
        else begin
            p.r_addr <= w_stall ? 'bx : s.r_addr;
            p.r_QIx4 <= w_stall ? 'bx : s.w_QIx4;
            p.r_validx4 <= w_stall ? 8'h0 : s.w_validx4;
            p.r_last <= w_stall ? 1'b0 : s.w_last;
        end
    end

    assign p.w_validx4_scan[0] = 2'd0;
    assign p.w_validx4_scan[1] = {1'b0, p.r_validx4[0]} + p.w_validx4_scan[0];
    assign p.w_validx4_scan[2] = {1'b0, p.r_validx4[1]} + p.w_validx4_scan[1];
    assign p.w_validx4_scan[3] = {1'b0, p.r_validx4[2]} + p.w_validx4_scan[2];

    assign p.w_validx4_shftamt[0] =  2'd0;
    assign p.w_validx4_shftamt[1] =  2'd1 - p.w_validx4_scan[1];
    assign p.w_validx4_shftamt[2] =  2'd2 - p.w_validx4_scan[2];
    assign p.w_validx4_shftamt[3] =  2'd3 - p.w_validx4_scan[3];

    assign p.w_QIx4_shftamt[0] = {p.w_validx4_shftamt[0], 5'b00000};
    assign p.w_QIx4_shftamt[1] = {p.w_validx4_shftamt[1], 5'b00000};
    assign p.w_QIx4_shftamt[2] = {p.w_validx4_shftamt[2], 5'b00000};
    assign p.w_QIx4_shftamt[3] = {p.w_validx4_shftamt[3], 5'b00000};

    for (genvar i = 0; i < 4; i++) begin : SCAN_SHIFT_GEN

        assign p.w_validx4_shift[i] = p.r_validx4[i] ? {
            {(3-i){1'b0}}, p.r_validx4[i], {i{1'b0}}
        } >> p.w_validx4_shftamt[i] : 'h0;

        assign p.w_QIx4_shift[i] = p.r_validx4[i] ? {
            {(ADC_WIDTH*2*(3-i)){1'b0}}, p.r_QIx4[ADC_WIDTH*2*(i+1)-1:ADC_WIDTH*2*i], 
            {(ADC_WIDTH*2*i){1'b0}}
        } >> p.w_QIx4_shftamt[i] : 'h0;

    end

    assign p.w_validx4_packed = p.w_validx4_shift[0] | p.w_validx4_shift[1] |
        p.w_validx4_shift[2] | p.w_validx4_shift[3];
    assign p.w_QIx4_packed = p.w_QIx4_shift[0] | p.w_QIx4_shift[1] |
        p.w_QIx4_shift[2] | p.w_QIx4_shift[3];

    assign p.w_samples = {1'b0, p.w_validx4_scan[3]} + {2'b00, p.r_validx4[3]};

    /*******************************
    * align and buffer stages
    *******************************/

    li_align_stg_t a;
    li_buffer_stg_t b;

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            a.r_addr <= 'bx;
            a.r_QIx4 <= 'b0;
            a.r_validx4 <= 4'h0;
            a.r_last <= 1'b0;
            a.r_samples <= 'd0;
        end
        else begin
            a.r_addr <= p.r_addr; 
            a.r_QIx4 <= p.w_QIx4_packed;
            a.r_validx4 <= p.w_validx4_packed;
            a.r_last <= p.r_last;
            a.r_samples <= p.w_samples;
        end
    end

    assign a.w_validx8_aligned = {4'h0, b.r_validx4} |
        ({4'h0, a.r_validx4} << b.r_samples);

    assign a.w_QIx8_aligned = {{(ADC_WIDTH*8){1'b0}}, b.r_QIx4} |
        ({{(ADC_WIDTH*8){1'b0}}, a.r_QIx4} << {b.r_samples, 5'b0000});

    assign a.w_forward_last = (b.w_total_samples == 'd4) && !b.r_last && a.r_last;

    assign b.w_total_samples = {1'b0, a.r_samples} + {1'b0, b.r_samples};
    assign b.w_full = (b.w_total_samples >= 'd4);

    assign b.w_validx4_inbuf = b.r_last ? b.r_validx4 : a.w_validx8_aligned[3:0];
    assign b.w_QIx4_inbuf = b.r_last ? b.r_QIx4 : a.w_QIx8_aligned[8*ADC_WIDTH-1:0];

    assign b.w_validx4_overflow = b.r_last ? 'h0 : a.w_validx8_aligned[7:4];
    assign b.w_QIx4_overflow = b.r_last ? 'h0 : a.w_QIx8_aligned[16*ADC_WIDTH-1:8*ADC_WIDTH];

    always_ff @(posedge i_clk) begin
        if (i_rst) begin 
            b.r_addr <= 'bx;
            b.r_QIx4 <= 'b0;
            b.r_validx4 <= 4'h0;
            b.r_last <= 1'b0;
            b.r_samples <= 'd0;
        end
        else if (b.r_last) begin
            b.r_addr <= a.r_addr;
            b.r_QIx4 <= a.r_QIx4;
            b.r_validx4 <= a.r_validx4;
            b.r_last <= a.r_last;
            b.r_samples <= a.r_samples;
        end
        else begin
            b.r_addr <= a.r_addr;
            b.r_QIx4 <= b.w_full ? b.w_QIx4_overflow : b.w_QIx4_inbuf;
            b.r_validx4 <= b.w_full ? b.w_validx4_overflow : b.w_validx4_inbuf;
            b.r_last <= a.w_forward_last ? 1'b0 : a.r_last;
            b.r_samples <= b.w_full ? (b.w_total_samples - 'd4) : b.w_total_samples;
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
                r_QIx4: 'b0,
                r_validx4: 'h0,
                r_last: 1'b0
            };
        end
        else if (b.w_full || b.r_last) begin
            o <= '{
                r_addr: b.r_addr,
                r_QIx4: b.w_QIx4_inbuf,
                r_validx4: b.w_validx4_inbuf,
                r_last: b.r_last || a.w_forward_last
            };
        end
        else begin
            o <= '{
                r_addr: 'bx,
                r_QIx4: 'b0,
                r_validx4: 'h0,
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

    assign o_QIx4 = o.r_QIx4;
    assign o_validx4 = o.r_validx4;
    assign o_last = o.r_last;

    assign o_armed = !i_empty && d.w_arm;

    assign o_empty = i_empty && (s.w_done || s.r_done) && !s.w_last && 
        !p.r_last && !a.r_last && !b.r_last && !o.r_last;

    assign o_eop = '{
        w_addr: o.r_addr,
        w_QIx4: o.r_QIx4,
        w_validx4: o.r_validx4,
        w_last: o.r_last
    };

endmodule
