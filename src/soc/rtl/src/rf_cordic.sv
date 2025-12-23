`default_nettype none
`timescale 1ns / 1ps
`include "include/rf.svh"

module rf_cordic
   #(parameter PHASE_WIDTH=RF_PHASE_WIDTH,
     parameter IQ_WIDTH=RF_IQ_WIDTH,
     parameter NUM_STAGES=RF_CORDIC_STAGES,
     parameter PAD_ZEROS=RF_CORDIC_PAD_ZEROS,
     parameter INDEX)
    (input  logic i_clk, i_rst,
     input  rf_phase_stg_t p,
     output rf_result_stg_t r,
     input  logic i_stall);

    rf_cordic_stg_t c [0:NUM_STAGES];

    // 2's complement encoding of highest and lowest voltage level
    // arithmatic pad 1-bit at front for cordic gain
    // pad zeros at the end to increase resolution
    logic [IQ_WIDTH-1:0] w_pre_gain_pos, w_pre_gain_neg;
    assign  w_pre_gain_pos = 14'h1b7b;
    assign  w_pre_gain_neg = ~w_pre_gain_pos + 'h1;

    logic [IQ_WIDTH+PAD_ZEROS-1:0] w_hi, w_lo;
    assign w_hi = {w_pre_gain_pos, {(PAD_ZEROS){1'b0}}};
    assign w_lo = {w_pre_gain_neg, {(PAD_ZEROS){1'b0}}};

    // 90 degree is a fourth of 2**PHASE_WIDTH
    // 180 degree is a half of 2**PHASE_WIDTH
    logic [PHASE_WIDTH-1:0] w_90_degree, w_180_degree;
    assign w_90_degree = {2'b01, {(PHASE_WIDTH-2){1'b0}}};
    assign w_180_degree = {2'b10, {(PHASE_WIDTH-2){1'b0}}};

    logic [PHASE_WIDTH-1:0] w_phase;
    assign w_phase = p.w_phasex8[INDEX];

    // coarse rotation into +/- 45 degrees range
    always_ff @(posedge i_clk) begin

        if (i_rst) begin
            c[0] <= '{
                r_addr: 'bx,
                r_sample: 'bx,
                r_phase_left: 'bx,
                r_x: 'bx,
                r_y: 'bx,
                r_bubble: 1'b1,
                r_zero: 1'b1,
                r_arm: 1'b0
            };
        end
        else if (!i_stall) begin

            c[0].r_addr <= p.r_addr;
            c[0].r_sample <= (p.r_samples_left > INDEX) ? (p.r_samples - p.r_samples_left + INDEX) : 'bx;
            c[0].r_bubble <= (p.r_samples_left == 'd0) || (p.r_samples_left <= INDEX);
            c[0].r_zero <= p.w_zerox8[INDEX];
            c[0].r_arm <= p.r_arm;

            case (w_phase[PHASE_WIDTH-1:PHASE_WIDTH-3])
                3'b000: begin // 0..45
                    // rotate 0, 0-45 left to rotate
                    c[0].r_phase_left <= w_phase;
                    c[0].r_x <= w_hi;
                    c[0].r_y <= 'h0;
                end
                3'b001: begin // 45..90
                    // rotate 90, -45..0 left to rotate
                    c[0].r_phase_left <= w_phase - w_90_degree;
                    c[0].r_x <= 'h0;
                    c[0].r_y <= w_hi;
                end
                3'b010: begin // 90..135
                    // rotate 90, 0..45 left to rotate
                    c[0].r_phase_left <= w_phase - w_90_degree; 
                    c[0].r_x <= 'h0; 
                    c[0].r_y <= w_hi; 
                end 
                3'b011: begin // 135..180 
                    // rotate 180, -45..0 left to rotate
                    c[0].r_phase_left <= w_phase - w_180_degree; 
                    c[0].r_x <= w_lo;
                    c[0].r_y <= 'h0;
                end
                3'b100: begin // -180..-135
                    // rotate -180, 0..45 left to rotate
                    c[0].r_phase_left <= w_phase + w_180_degree;
                    c[0].r_x <= w_lo;
                    c[0].r_y <= 'h0;
                end
                3'b101: begin // -135..-90
                    // rotate -90, -45..0 left to rotate
                    c[0].r_phase_left <= w_phase + w_90_degree;
                    c[0].r_x <= 'h0;
                    c[0].r_y <= w_lo;
                end
                3'b110: begin // -90..-45
                    // rotate -90, 0..45 left to rotate
                    c[0].r_phase_left <= w_phase + w_90_degree;
                    c[0].r_x <= 'h0;
                    c[0].r_y <= w_lo;
                end
                3'b111: begin // -45..0
                    // rotate 0, -45..0 left to rotate
                    c[0].r_phase_left <= w_phase;
                    c[0].r_x <= w_hi;
                    c[0].r_y <= 'h0;
                end
            endcase

        end

    end

    logic [PHASE_WIDTH-1:0] angle [0:NUM_STAGES-1];
    assign angle = {
        18'h04B90,
        18'h027ED,
        18'h01444,
        18'h00A2C,
        18'h00517,
        18'h0028C,
        18'h00146,
        18'h000A3,
        18'h00051,
        18'h00029,
        18'h00014,
        18'h0000A,
        18'h00005,
        18'h00003,
        18'h00001
    };

    // cordic fine rotation
    for (genvar i = 0; i < NUM_STAGES; i++) begin : PIPELINE_GEN

        always_ff @(posedge i_clk) begin

            if (i_rst) begin
                c[i + 1] <= '{
                    r_addr: 'bx,
                    r_sample: 'bx,
                    r_phase_left: 'bx,
                    r_x: 'bx,
                    r_y: 'bx,
                    r_bubble: 1'b1,
                    r_zero: 1'b1,
                    r_arm: 1'b0
                };
            end
            else if (!i_stall) begin

                c[i + 1].r_addr <= c[i].r_addr;
                c[i + 1].r_sample <= c[i].r_sample;
                c[i + 1].r_bubble <= c[i].r_bubble;
                c[i + 1].r_zero <= c[i].r_zero;
                c[i + 1].r_arm <= c[i].r_arm;

                if (c[i].r_phase_left[PHASE_WIDTH-1]) begin
                    // phase left is negative 
                    c[i + 1].r_phase_left <= c[i].r_phase_left + angle[i];
                    c[i + 1].r_x <= c[i].r_x + (c[i].r_y >>> (i + 1));
                    c[i + 1].r_y <= c[i].r_y - (c[i].r_x >>> (i + 1));
                end
                else begin
                    // phase left is zero or positive
                    c[i + 1].r_phase_left <= c[i].r_phase_left - angle[i];
                    c[i + 1].r_x <= c[i].r_x - (c[i].r_y >>> (i + 1));
                    c[i + 1].r_y <= c[i].r_y + (c[i].r_x >>> (i + 1));
                end
            end

        end

    end

    logic [IQ_WIDTH+PAD_ZEROS-1:0] w_x, w_y;
    assign w_x = c[NUM_STAGES].r_x;
    assign w_y = c[NUM_STAGES].r_y;

    // convergent rounding without causing overflow
    logic [IQ_WIDTH+PAD_ZEROS-1:0] w_x_conv_round, w_y_conv_round;
    logic [IQ_WIDTH+PAD_ZEROS-1:0] w_x_round, w_y_round;
    assign w_x_conv_round = w_x + {{(IQ_WIDTH){1'b0}}, w_x[PAD_ZEROS], {(PAD_ZEROS-1){!w_x[PAD_ZEROS]}}};
    assign w_y_conv_round = w_y + {{(IQ_WIDTH){1'b0}}, w_y[PAD_ZEROS], {(PAD_ZEROS-1){!w_y[PAD_ZEROS]}}};
    assign w_x_round = (w_x_conv_round[IQ_WIDTH+PAD_ZEROS-1] == w_x[IQ_WIDTH+PAD_ZEROS-1]) ? w_x_conv_round : w_x;
    assign w_y_round = (w_y_conv_round[IQ_WIDTH+PAD_ZEROS-1] == w_y[IQ_WIDTH+PAD_ZEROS-1]) ? w_y_conv_round : w_y;
    
    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            r <= '{
                r_addr: 'bx,
                r_sample: 'bx,
                r_Q: 'h0,
                r_I: 'h0,
                r_bubble: 1'b1,
                r_arm: 1'b0
            };
        end
        else if (!i_stall) begin
            r <= '{
                r_addr: c[NUM_STAGES].r_addr,
                r_sample: c[NUM_STAGES].r_sample,
                r_Q: c[NUM_STAGES].r_zero ? 'h0 : w_x_round[IQ_WIDTH+PAD_ZEROS-1:PAD_ZEROS],
                r_I: c[NUM_STAGES].r_zero ? 'h0 : w_y_round[IQ_WIDTH+PAD_ZEROS-1:PAD_ZEROS],
                r_bubble: c[NUM_STAGES].r_bubble,
                r_arm: c[NUM_STAGES].r_arm
            };
        end
    end

endmodule
