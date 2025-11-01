`timescale 1ns / 1ps

module cordic
   #(parameter PHASE_WIDTH=18,
     parameter IQ_WIDTH=14,
     parameter NUM_STAGES=15,
     parameter PAD_ZEROS=3)
    (input  logic i_clk,
     input  logic [PHASE_WIDTH-1:0] i_phase,
     output logic [IQ_WIDTH-1:0] o_I, o_Q,
     input  logic i_stall);

    logic [PHASE_WIDTH-1:0] r_phase_left [0:NUM_STAGES];
    logic signed [IQ_WIDTH+PAD_ZEROS-1:0] r_x [0:NUM_STAGES];
    logic signed [IQ_WIDTH+PAD_ZEROS-1:0] r_y [0:NUM_STAGES];
    
    // 2's complement encoding of highest and lowest voltage level
    // arithmatic pad 1-bit at front for cordic gain
    // pad zeros at the end to increase resolution
    logic [IQ_WIDTH-1:0] w_pre_gain_pos, w_pre_gain_neg;
    // assign  w_pre_gain_pos = 14'h1b7b;
    // assign  w_pre_gain_neg = ~w_pre_gain_pos + 'h1;
    assign  w_pre_gain_pos = 14'h1b7b + 14'h2000;
    assign  w_pre_gain_neg = ~(14'h1b7b) + 14'h1 + 14'h2000;
    logic [IQ_WIDTH+PAD_ZEROS-1:0] w_hi, w_lo;
    assign w_hi = {w_pre_gain_pos, {(PAD_ZEROS){1'b0}}};
    assign w_lo = {w_pre_gain_neg, {(PAD_ZEROS){1'b0}}};

    // 90 degree is a fourth of 2**PHASE_WIDTH
    // 180 degree is a half of 2**PHASE_WIDTH
    logic [PHASE_WIDTH-1:0] w_90_degree, w_180_degree;
    assign w_90_degree = {2'b01, {(PHASE_WIDTH-2){1'b0}}};
    assign w_180_degree = {2'b10, {(PHASE_WIDTH-2){1'b0}}};

    // coarse rotation into +/- 45 degrees range
    always_ff @(posedge i_clk) begin
        if (!i_stall) begin
            case (i_phase[PHASE_WIDTH-1:PHASE_WIDTH-3])
                3'b000: begin // 0..45
                    // rotate 0, 0-45 left to rotate
                    r_phase_left[0] <= i_phase;
                    r_x[0] <= w_hi;
                    r_y[0] <= 'h0;
                end
                3'b001: begin // 45..90
                    // rotate 90, -45..0 left to rotate
                    r_phase_left[0] <= i_phase - w_90_degree;
                    r_x[0] <= 'h0;
                    r_y[0] <= w_hi;
                end
                3'b010: begin // 90..135
                    // rotate 90, 0..45 left to rotate
                    r_phase_left[0] <= i_phase - w_90_degree; 
                    r_x[0] <= 'h0; 
                    r_y[0] <= w_hi; 
                end 
                3'b011: begin // 135..180 
                    // rotate 180, -45..0 left to rotate
                    r_phase_left[0] <= i_phase - w_180_degree; 
                    r_x[0] <= w_lo;
                    r_y[0] <= 'h0;
                end
                3'b100: begin // -180..-135
                    // rotate -180, 0..45 left to rotate
                    r_phase_left[0] <= i_phase + w_180_degree;
                    r_x[0] <= w_lo;
                    r_y[0] <= 'h0;
                end
                3'b101: begin // -135..-90
                    // rotate -90, -45..0 left to rotate
                    r_phase_left[0] <= i_phase + w_90_degree;
                    r_x[0] <= 'h0;
                    r_y[0] <= w_lo;
                end
                3'b110: begin // -90..-45
                    // rotate -90, 0..45 left to rotate
                    r_phase_left[0] <= i_phase + w_90_degree;
                    r_x[0] <= 'h0;
                    r_y[0] <= w_lo;
                end
                3'b111: begin // -45..0
                    // rotate 0, -45..0 left to rotate
                    r_phase_left[0] <= i_phase;
                    r_x[0] <= w_hi;
                    r_y[0] <= 'h0;
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
    for (genvar i = 0; i < NUM_STAGES; i++) begin
        always_ff @(posedge i_clk) begin
            if (!i_stall) begin
                if (r_phase_left[i][PHASE_WIDTH-1]) begin
                    // phase left is negative 
                    r_phase_left[i + 1] <= r_phase_left[i] + angle[i];
                    r_x[i + 1] <= r_x[i] + (r_y[i] >>> (i + 1));
                    r_y[i + 1] <= r_y[i] - (r_x[i] >>> (i + 1));
                end
                else begin
                    // phase left is zero or positive
                    r_phase_left[i + 1] <= r_phase_left[i] - angle[i];
                    r_x[i + 1] <= r_x[i] - (r_y[i] >>> (i + 1));
                    r_y[i + 1] <= r_y[i] + (r_x[i] >>> (i + 1));
                end
            end
        end
    end

    logic [IQ_WIDTH+PAD_ZEROS-1:0] w_x, w_y;
    assign w_x = r_x[NUM_STAGES];
    assign w_y = r_y[NUM_STAGES];

    // convergent rounding without causing overflow
    logic [IQ_WIDTH+PAD_ZEROS-1:0] w_x_conv_round, w_y_conv_round;
    logic [IQ_WIDTH+PAD_ZEROS-1:0] w_x_round, w_y_round;
    assign w_x_conv_round = w_x + {{(IQ_WIDTH){1'b0}}, w_x[PAD_ZEROS], {(PAD_ZEROS-1){!w_x[PAD_ZEROS]}}};
    assign w_y_conv_round = w_y + {{(IQ_WIDTH){1'b0}}, w_y[PAD_ZEROS], {(PAD_ZEROS-1){!w_y[PAD_ZEROS]}}};
    assign w_x_round = (w_x_conv_round[IQ_WIDTH+PAD_ZEROS-1] == w_x[IQ_WIDTH+PAD_ZEROS-1]) ? w_x_conv_round : w_x;
    assign w_y_round = (w_y_conv_round[IQ_WIDTH+PAD_ZEROS-1] == w_y[IQ_WIDTH+PAD_ZEROS-1]) ? w_y_conv_round : w_y;
    
    always_ff @(posedge i_clk) begin
        if (!i_stall) begin
            o_I <= w_x_round[IQ_WIDTH+PAD_ZEROS-1:PAD_ZEROS];
            o_Q <= w_y_round[IQ_WIDTH+PAD_ZEROS-1:PAD_ZEROS];
        end
    end

endmodule
