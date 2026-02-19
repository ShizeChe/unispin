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

     output logic [7:0] o_validx8,
     output logic o_done);

    always_comb begin

        if (i_idle) begin

            o_samples_next = (i_samples_left < 'd8) ? 'd0 : (i_samples_left - 'd8);
            o_stride_next = 'bx;
            o_validx8 = 8'h0;

        end
        else if (i_stride_left > 'd8) begin

            o_samples_next = i_samples_left;
            o_stride_next = i_stride_left - 'd8;
            o_validx8 = 8'h0;

        end
        else if (i_stride_left == 'd7) begin

            o_samples_next = (i_samples_left < 'd1) ? 'd0 : (i_samples_left - 'd1);
            o_validx8 = (i_samples_left < 'd1) ? 8'h0 : 8'b10000000;
            o_stride_next = i_stride - 'd1;

        end
        else if (i_stride_left == 'd6) begin

            // i_stride = 1 won't reach here, period = 01234567 | 01234567...

            o_samples_next = (i_samples_left < 'd1) ? 'd0 : (i_samples_left - 'd1);
            o_validx8 = (i_samples_left < 'd1) ? 8'h0 : 8'b01000000;
            o_stride_next = i_stride - 'd2;

        end
        else if (i_stride_left == 'd5) begin

            // i_stride = 1 won't reach here, period = 01234567 | 01234567...
            // i_stride = 2 won't reach here, period = 0246 | 0246...

            o_samples_next = (i_samples_left < 'd1) ? 'd0 : (i_samples_left - 'd1);
            o_validx8 = (i_samples_left < 'd1) ? 8'h0 : 8'b00100000;
            o_stride_next = i_stride - 'd3;

        end
        else if (i_stride_left == 'd4) begin

            // i_stride = 1 won't reach here, period = 01234567 | 01234567...
            // i_stride = 2 won't reach here, period = 0246 | 0246...
            // i_stride = 3 won't reach here, period = 036 | 147 | 25 | 036...

            o_samples_next = (i_samples_left < 'd1) ? 'd0 : (i_samples_left - 'd1);
            o_validx8 = (i_samples_left < 'd1) ? 8'h0 : 8'b00010000;
            o_stride_next = i_stride - 'd4;

        end
        else if (i_stride_left == 'd3) begin

            // i_stride = 1 won't reach here, period = 01234567 | 01234567...
            // i_stride = 2 won't reach here, period = 0246 | 0246...
            // i_stride = 3 won't reach here, period = 036 | 147 | 25 | 036...
            // i_stride = 4 won't reach here, period = 04 | 04...

            o_samples_next = (i_samples_left < 'd1) ? 'd0 : (i_samples_left - 'd1);
            o_validx8 = (i_samples_left < 'd1) ? 8'h0 : 8'b00001000;
            o_stride_next = i_stride - 'd5;

        end
        else if (i_stride_left == 'd2) begin

            // i_stride = 1 won't reach here, period = 01234567 | 01234567...
            // i_stride = 2 won't reach here, period = 0246 | 0246...
            // i_stride = 3 can reach here, period = 036 | 147 | 25 | 036...
            // i_stride = 4 won't reach here, period = 04 | 04...
            // i_stride = 5 can reach here, period = 05 | 27 | 4 | 16 | 3 | 05...

            case (i_stride)
                'd3: begin
                    o_samples_next = (i_samples_left < 'd2) ? 'd0 : (i_samples_left - 'd2);
                    o_validx8 = (i_samples_left >= 'd2) ? 8'b00100100 : 
                                (i_samples_left == 'd1) ? 8'b00000100 : 8'h0;
                    o_stride_next = 'd0;
                end
                'd5: begin
                    o_samples_next = (i_samples_left < 'd2) ? 'd0 : (i_samples_left - 'd2);
                    o_validx8 = (i_samples_left >= 'd2) ? 8'b10000100 : 
                                (i_samples_left == 'd1) ? 8'b00000100 : 8'h0;
                    o_stride_next = 'd4;
                end
                default: begin
                    o_samples_next = (i_samples_left < 'd1) ? 'd0 : (i_samples_left - 'd1);
                    o_validx8 = (i_samples_left < 'd1) ? 8'h0 : 8'b00000100;
                    o_stride_next = i_stride - 'd6;
                end
            endcase

        end
        else if (i_stride_left == 'd1) begin

            // i_stride = 1 won't reach here, period = 01234567 | 01234567...
            // i_stride = 2 won't reach here, period = 0246 | 0246...
            // i_stride = 3 can reach here, period = 036 | 147 | 25 | 036...
            // i_stride = 4 won't reach here, period = 04 | 04...
            // i_stride = 5 can reach here, period = 05 | 27 | 4 | 16 | 3 | 05...
            // i_stride = 6 won't reach here, period = 06 | 4 | 2 | 06...

            case (i_stride)
                'd3: begin
                    o_samples_next = (i_samples_left < 'd3) ? 'd0 : (i_samples_left - 'd3);
                    o_validx8 = (i_samples_left >= 'd3) ? 8'b10010010 : 
                                (i_samples_left == 'd2) ? 8'b00010010 : 
                                (i_samples_left == 'd1) ? 8'b00000010 : 8'h0;
                    o_stride_next = 'd2;
                end
                'd5: begin
                    o_samples_next = (i_samples_left < 'd2) ? 'd0 : (i_samples_left - 'd2);
                    o_validx8 = (i_samples_left >= 'd2) ? 8'b01000010 : 
                                (i_samples_left == 'd1) ? 8'b00000010 : 8'h0;
                    o_stride_next = 'd3;
                end
                default: begin
                    o_samples_next = (i_samples_left < 'd1) ? 'd0 : (i_samples_left - 'd1);
                    o_validx8 = (i_samples_left < 'd1) ? 8'h0 : 8'b00000010;
                    o_stride_next = i_stride - 'd7;
                end
            endcase
        end
        else begin

            // i_stride = 1 can reach here, period = 01234567 | 01234567...
            // i_stride = 2 can reach here, period = 0246 | 0246...
            // i_stride = 3 can reach here, period = 036 | 147 | 25 | 036...
            // i_stride = 4 can reach here, period = 04 | 04...
            // i_stride = 5 can reach here, period = 05 | 27 | 4 | 16 | 3 | 05...
            // i_stride = 6 can reach here, period = 06 | 4 | 2 | 06...
            // i_stride = 7 can reach here, period = 07 | 6 | 5 | 4 | 3 | 2 | 1 | 07...

            case (i_stride)
                'd1: begin
                    o_samples_next = (i_samples_left < 'd8) ? 'd0 : (i_samples_left - 'd8);
                    o_validx8 = (i_samples_left >= 'd8) ? 8'b11111111 : 
                                (i_samples_left == 'd7) ? 8'b01111111 : 
                                (i_samples_left == 'd6) ? 8'b00111111 : 
                                (i_samples_left == 'd5) ? 8'b00011111 : 
                                (i_samples_left == 'd4) ? 8'b00001111 : 
                                (i_samples_left == 'd3) ? 8'b00000111 : 
                                (i_samples_left == 'd2) ? 8'b00000011 : 
                                (i_samples_left == 'd1) ? 8'b00000001 : 8'h0;
                    o_stride_next = 'd0;
                end
                'd2: begin
                    o_samples_next = (i_samples_left < 'd4) ? 'd0 : (i_samples_left - 'd4);
                    o_validx8 = (i_samples_left >= 'd4) ? 8'b01010101 : 
                                (i_samples_left == 'd3) ? 8'b00010101 : 
                                (i_samples_left == 'd2) ? 8'b00000101 : 
                                (i_samples_left == 'd1) ? 8'b00000001 : 8'h0;
                    o_stride_next = 'd0;
                end
                'd3: begin
                    o_samples_next = (i_samples_left < 'd3) ? 'd0 : (i_samples_left - 'd3);
                    o_validx8 = (i_samples_left >= 'd3) ? 8'b01001001 : 
                                (i_samples_left == 'd2) ? 8'b00001001 :
                                (i_samples_left == 'd1) ? 8'b00000001 : 8'h0;
                    o_stride_next = 'd1;
                end
                'd4: begin
                    o_samples_next = (i_samples_left < 'd2) ? 'd0 : (i_samples_left - 'd2);
                    o_validx8 = (i_samples_left >= 'd2) ? 8'b00010001 : 
                                (i_samples_left == 'd1) ? 8'b00000001 : 8'h0;
                    o_stride_next = 'd0;
                end
                'd5: begin
                    o_samples_next = (i_samples_left < 'd2) ? 'd0 : (i_samples_left - 'd2);
                    o_validx8 = (i_samples_left >= 'd2) ? 8'b00100001 : 
                                (i_samples_left == 'd1) ? 8'b00000001 : 8'h0;
                    o_stride_next = 'd2;
                end
                'd6: begin
                    o_samples_next = (i_samples_left < 'd2) ? 'd0 : (i_samples_left - 'd2);
                    o_validx8 = (i_samples_left >= 'd2) ? 8'b01000001 : 
                                (i_samples_left == 'd1) ? 8'b00000001 : 8'h0;
                    o_stride_next = 'd4;
                end
                'd7: begin
                    o_samples_next = (i_samples_left < 'd2) ? 'd0 : (i_samples_left - 'd2);
                    o_validx8 = (i_samples_left >= 'd2) ? 8'b10000001 : 
                                (i_samples_left == 'd1) ? 8'b00000001 : 8'h0;
                    o_stride_next = 'd6;
                end
                default: begin
                    o_samples_next = (i_samples_left < 'd1) ? 'd0 : (i_samples_left - 'd1);
                    o_validx8 = (i_samples_left < 'd1) ? 8'h0 : 8'b00000001;
                    o_stride_next = i_stride - 'd8;
                end
            endcase
        end

        o_done = (o_samples_next == 'd0);

    end

endmodule
