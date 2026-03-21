// `default_nettype none
`timescale 1ns / 1ps
`include "ex.svh"

module ex_core
   #(parameter NUM_SAMPLE_WIDTH=EX_NUM_SAMPLE_WIDTH,
     parameter INSN_WIDTH=EX_INSN_WIDTH,
     parameter REAL_WIDTH=EX_REAL_WIDTH,
     parameter DAC_WIDTH=EX_DAC_WIDTH,
     parameter DEPTH=EX_DEPTH)
    (input  logic i_clk, i_rst,
     
     // sequencer interface
     input  logic [$clog2(DEPTH)-1:0] i_addr,
     input  ex_insn_t i_insn,
     output logic o_next,
     input  logic i_empty,
     output ex_insn_t o_insn_modified,

     // rfdac interface
     output logic [DAC_WIDTH*16-1:0] o_realx16,

     // launcher interface
     input  logic i_start,
     output logic o_armed,

     // pipeline empty flag
     output logic o_empty,

     // eop for verification
     output ex_eop_t o_eop);

    logic w_stall;

    /**************
    * decode stage
    **************/

    ex_decode_stg_t d;

    assign d = '{
        w_addr: i_addr,
        w_arm: i_insn.w_arm,
        w_real: i_insn.w_real,
        w_samples: i_insn.w_samples
    };

    assign o_insn_modified.w_arm = 1'b0;
    assign o_insn_modified.w_real = i_insn.w_real;
    assign o_insn_modified.w_samples = i_insn.w_samples + i_insn.w_dsamples;
    assign o_insn_modified.w_dsamples = i_insn.w_dsamples;

    /*************
    * count stage
    *************/

    ex_count_stg_t c;

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            c.r_addr <= 'bx;
            c.r_arm <= 1'b0;
            c.r_real <= 'h0;
            c.r_samples <= 'bx;
            c.r_samples_left <= 'd0;
        end
        else if (!w_stall) begin

            if (c.r_samples_left > 'd16) begin
                c.r_arm <= 1'b0;
                c.r_samples_left <= c.r_samples_left - 'd16;
            end
            else if (!i_empty) begin
                c.r_addr <= d.w_addr;
                c.r_arm <= d.w_arm;
                c.r_real <= d.w_real;
                c.r_samples <= d.w_samples;
                c.r_samples_left <= d.w_samples;
            end
            else begin
                c.r_arm <= 1'b0;
                c.r_samples_left <= 'd0;
            end

        end
    end

    assign o_next = (c.r_samples_left <= 'd16) && !i_empty;

    always_comb begin
        if (c.r_samples_left > 'd16) begin
            c.w_realx16 = {16{c.r_real, 2'b00}};
        end
        else begin

            case (c.r_samples_left) 
                'd0: c.w_realx16 = 'h0;
                'd1: c.w_realx16 = {{15{16'h0}}, {c.r_real, 2'b00}};
                'd2: c.w_realx16 = {{14{16'h0}}, {2{c.r_real, 2'b00}}};
                'd3: c.w_realx16 = {{13{16'h0}}, {3{c.r_real, 2'b00}}};
                'd4: c.w_realx16 = {{12{16'h0}}, {4{c.r_real, 2'b00}}};
                'd5: c.w_realx16 = {{11{16'h0}}, {5{c.r_real, 2'b00}}};
                'd6: c.w_realx16 = {{10{16'h0}}, {6{c.r_real, 2'b00}}};
                'd7: c.w_realx16 = {{9{16'h0}}, {7{c.r_real, 2'b00}}};
                'd8: c.w_realx16 = {{8{16'h0}}, {8{c.r_real, 2'b00}}};
                'd9: c.w_realx16 = {{7{16'h0}}, {9{c.r_real, 2'b00}}};
                'd10: c.w_realx16 = {{6{16'h0}}, {10{c.r_real, 2'b00}}};
                'd11: c.w_realx16 = {{5{16'h0}}, {11{c.r_real, 2'b00}}};
                'd12: c.w_realx16 = {{4{16'h0}}, {12{c.r_real, 2'b00}}};
                'd13: c.w_realx16 = {{3{16'h0}}, {13{c.r_real, 2'b00}}};
                'd14: c.w_realx16 = {{2{16'h0}}, {14{c.r_real, 2'b00}}};
                'd15: c.w_realx16 = {16'h0, {15{c.r_real, 2'b00}}};
                'd16: c.w_realx16 = {16{c.r_real, 2'b00}};
                default: c.w_realx16 = 'h0;
            endcase

        end
    end

    /**************
    * output stage
    **************/

    ex_output_stg_t o;

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            o.r_addr <= 'bx;
            o.r_realx16 <= 'h0;
        end
        else if (!w_stall) begin
            o.r_addr <= c.r_addr;
            o.r_realx16 <= c.w_realx16;
        end
    end

    /*************
    * stall logic
    *************/

    assign o_armed = c.r_arm;

    assign w_stall = (o_armed && !i_start);

    assign o_empty = i_empty && (c.r_samples_left == 'd0);

    assign o_realx16 = o.r_realx16;
    assign o_eop = '{
        w_addr: o.r_addr,
        w_realx16: o.r_realx16
    };

endmodule
