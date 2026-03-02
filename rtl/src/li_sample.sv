// `default_nettype none
`timescale 1ns / 1ps
`include "li.svh"

module li_sample
   #(parameter NUM_SAMPLE_WIDTH=LI_NUM_SAMPLE_WIDTH,
     parameter STRIDE_WIDTH=LI_STRIDE_WIDTH)
    (input  logic [NUM_SAMPLE_WIDTH-1:0] i_samples_left,
     output logic [NUM_SAMPLE_WIDTH-1:0] o_samples_next,

     input  logic [STRIDE_WIDTH-1:0] i_stride,
     input  logic [STRIDE_WIDTH-1:0] i_stride_left,
     output logic [STRIDE_WIDTH-1:0] o_stride_next,

     input  logic i_idle,

     output logic [3:0] o_validx4,
     output logic o_done);

    always_comb begin

        if (i_idle) begin

            o_samples_next = (i_samples_left < 'd4) ? 'd0 : (i_samples_left - 'd4);
            o_stride_next = 'b0;
            o_validx4 = 4'h0;

        end
        else if (i_stride_left >= 'd4) begin

            o_samples_next = i_samples_left;
            o_stride_next = i_stride_left - 'd4;
            o_validx4 = 4'h0;

        end
        else if (i_stride_left == 'd3) begin

            // i_stride = 1 won't reach here, period = 0123 | 0123...
            // i_stride = 2 won't reach here, period = 02 | 02...
            // i_stride = 3 won't reach here, period = 03 | 2 | 1 | 03...

            o_samples_next = (i_samples_left < 'd1) ? 'd0 : (i_samples_left - 'd1);
            o_validx4 = (i_samples_left < 'd1) ? 4'h0 : 4'b1000;
            o_stride_next = i_stride - 'd1;

        end
        else if (i_stride_left == 'd2) begin

            // i_stride = 1 won't reach here, period = 0123 | 0123...
            // i_stride = 2 won't reach here, period = 02 | 02...
            // i_stride = 3 can reach here, period = 03 | 2 | 1 | 03...

            o_samples_next = (i_samples_left < 'd1) ? 'd0 : (i_samples_left - 'd1);
            o_validx4 = (i_samples_left < 'd1) ? 4'h0 : 4'b0100;
            o_stride_next = i_stride - 'd2;

        end
        else if (i_stride_left == 'd1) begin

            // i_stride = 1 won't reach here, period = 0123 | 0123...
            // i_stride = 2 won't reach here, period = 02 | 02...
            // i_stride = 3 can reach here, period = 03 | 2 | 1 | 03...

            o_samples_next = (i_samples_left < 'd1) ? 'd0 : (i_samples_left - 'd1);
            o_validx4 = (i_samples_left < 'd1) ? 4'h0 : 4'b0010;
            o_stride_next = i_stride - 'd3;

        end
        else begin

            // i_stride = 1 can reach here, period = 0123 | 0123...
            // i_stride = 2 can reach here, period = 02 | 02...
            // i_stride = 3 can reach here, period = 03 | 2 | 1 | 03...

            case (i_stride)
                'd1: begin
                    o_samples_next = (i_samples_left < 'd4) ? 'd0 : (i_samples_left - 'd4);
                    o_validx4 = (i_samples_left >= 'd4) ? 4'b1111 : 
                                (i_samples_left == 'd3) ? 4'b0111 : 
                                (i_samples_left == 'd2) ? 4'b0011 : 
                                (i_samples_left == 'd1) ? 4'b0001 : 4'h0;
                    o_stride_next = 'd0;
                end
                'd2: begin
                    o_samples_next = (i_samples_left < 'd2) ? 'd0 : (i_samples_left - 'd2);
                    o_validx4 = (i_samples_left >= 'd2) ? 4'b0101 : 
                                (i_samples_left == 'd1) ? 4'b0001 : 4'h0;
                    o_stride_next = 'd0;
                end
                'd3: begin
                    o_samples_next = (i_samples_left < 'd2) ? 'd0 : (i_samples_left - 'd2);
                    o_validx4 = (i_samples_left >= 'd2) ? 4'b1001 : 
                                (i_samples_left == 'd1) ? 4'b0001 : 4'h0;
                    o_stride_next = 'd2;
                end
                default: begin
                    o_samples_next = (i_samples_left < 'd1) ? 'd0 : (i_samples_left - 'd1);
                    o_validx4 = (i_samples_left < 'd1) ? 4'h0 : 4'b0001;
                    o_stride_next = i_stride - 'd4;
                end
            endcase
        end

        o_done = (o_samples_next == 'd0 && o_stride_next < 'd4);

    end

endmodule
