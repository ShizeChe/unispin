`timescale 1ns / 1ps

module li_core
   #(parameter NUM_SAMPLE_WIDTH=20,
     parameter STRIDE_WIDTH=30,
     parameter IQ_WIDTH=14,
     parameter ADC_WIDTH=16,
     parameter INSN_WIDTH=STRIDE_WIDTH+NUM_SAMPLE_WIDTH*2)
    (input  logic i_clk, i_rst,
     
     input  logic i_insn,
     output logic o_next,
     input  logic i_empty,

     input  logic [ADC_WIDTH*16-1:0] i_QIx8,

     output logic [ADC_WIDTH*2-1:0] o_tdata,
     output logic [(ADC_WIDTH*2)/8-1:0] o_tkeep,
     output logic o_tlast,
     input  logic i_tready,
     output logic o_tvalid,

     input  logic i_start,
     output logic o_armed);

    logic [NUM_SAMPLE_WIDTH-1:0] w_delays_decode;
    logic [NUM_SAMPLE_WIDTH-1:0] w_samples_decode;
    logic [STRIDE_WIDTH-1:0] w_stride_decode;

    assign {w_delays_decode, w_samples_decode, w_stride_decode} = i_insn;

    logic [NUM_SAMPLE_WIDTH-1:0] r_delays, r_delays_next;
    logic [NUM_SAMPLE_WIDTH-1:0] r_samples, r_samples_next;
    logic [NUM_SAMPLE_WIDTH-1:0] r_samples, w_samples_next;
    logic [STRIDE_WIDTH-1:0] r_stride, w_stride_next;

    logic r_mode, w_mode_next;

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            r_waits <= 'd0;
            r_keeps <= 'd0;
            r_samples <= 'd0;
            r_stride <= 'd0;
            r_mode <= 1'b0;
        end
        else begin
            r_waits <= w_waits_next;
            r_keeps <= w_keeps_next
            r_samples <= w_samples_next;
            r_stride <= w_stride_next;
            r_mode <= w_mode_next;
        end
    end

    logic w_big_propagate, w_small_propagate, w_switch_mode;

    assign w_big_propagate = !i_empty && r_mode && (r_samples == 'd1) && 
                             ('d0 <= r_stride && r_stride <= 'd7); 

    assign w_small_propagate = (r_samples > 'd1) && 
                               ('d0 <= r_stride && r_stride <= 'd7);

    assign w_switch_mode = !r_mode && (r_samples == 'd1) && 
                           ('d0 <= r_stride && r_stride <= 'd7);

    enum {IDLE, ARMED, DELAY, KEEP} r_state;

    always_ff @(posedge i_clk) begin
        if (i_rst)
            r_state <= IDLE;
        else if (r_state == ARMED && i_start)
            r_state <= 
    end

    always_comb begin
        case ({w_big_propagate, w_small_propagate})
            2'b00: begin
                w_samples_next = r_samples;
                w_stride_next = r_stride - 'd8;
            end
            2'b01: begin
                w_samples_next = r_samples - 'd1;
                w_stride_next = r_stride_rst - ('d8 - r_stride);
            end
            2'b10: begin
                w_samples_next = w_samples_decode;
                w_stride_next = w_stride_decode;
            end
            default: begin
                w_samples_next = r_samples;
                w_stride_next = r_stride;
            end
        endcase
    end

endmodule
