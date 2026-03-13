`timescale 1ns / 1ps
`include "rf.svh"

module rf_cordic_tb;

    logic w_clk, w_rst;
    logic [RF_PHASE_WIDTH-1:0] w_phase;
    logic [RF_IQ_WIDTH-1:0] w_I, w_Q;

    rf_phase_stg_t p;

    assign p = '{
        r_addr: 'd0,
        r_samples: 'd0,
        r_samples_left: 'd1000,
        r_arm: 1'b0,
        r_idle: 1'b1,
        w_zerox8: 'd0,
        w_phasex8: {{(7*RF_PHASE_WIDTH){1'b0}}, w_phase}
    };

    rf_result_stg_t r;

    rf_cordic #(
        .PHASE_WIDTH(RF_PHASE_WIDTH),
        .IQ_WIDTH(RF_IQ_WIDTH),
        .NUM_STAGES(RF_CORDIC_STAGES),
        .PAD_ZEROS(RF_CORDIC_PAD_ZEROS),
        .INDEX(0)
    ) dut (
        .i_clk(w_clk),
        .i_rst(w_rst),
        .p(p),
        .r(r),
        .i_stall(1'b0)
    );

    assign w_I = r.r_I;
    assign w_Q = r.r_Q;

    initial begin
        w_clk = 1'b0;
        forever #2 w_clk = !w_clk;
    end

    localparam int PHASE_W = RF_PHASE_WIDTH;   // 18
    localparam int AMP_W   = RF_IQ_WIDTH;               // sin/cos output width

    localparam int PHASE_SCALE = 1 << PHASE_W;       // 2^18
    localparam int AMP_SCALE   = 1 << (AMP_W - 1);   // 2^13

    function automatic real phase_to_rad(input logic signed [PHASE_W-1:0] phase);
        begin
            return 2.0 * 3.14159265358979323846
                 * real'($signed(phase))
                 / real'(PHASE_SCALE);
        end
    endfunction

    function automatic int round_nearest(input real x);
        begin
            if (x >= 0.0) return $rtoi(x + 0.5);
            else          return $rtoi(x - 0.5);
        end
    endfunction

    function automatic logic signed [AMP_W-1:0] real_to_q14(input real x);
        int v;
        logic signed [AMP_W-1:0] y;
        begin
            // Convert real in [-1, 1] to signed 14-bit fixed-point.
            // Range becomes [-8192, 8191] for AMP_W=14.
            v = round_nearest(x * AMP_SCALE);

            // Saturate to representable signed range
            if (v >  AMP_SCALE - 1) v =  AMP_SCALE - 1;
            if (v < -AMP_SCALE)     v = -AMP_SCALE;

            y = v;
            return y;
        end
    endfunction

    function automatic logic signed [AMP_W-1:0] golden_cos
    (
        input logic signed [PHASE_W-1:0] phase
    );
        begin
            return real_to_q14($cos(phase_to_rad(phase)));
        end
    endfunction

    function automatic logic signed [AMP_W-1:0] golden_sin
    (
        input logic signed [PHASE_W-1:0] phase
    );
        begin
            return real_to_q14($sin(phase_to_rad(phase)));
        end
    endfunction

    // delay RF_CORDIC_STAGE + 2 cycles
    logic [RF_PHASE_WIDTH-1:0] r_phase_ffs [RF_CORDIC_STAGES + 2];

    always_ff @(posedge w_clk) begin
        r_phase_ffs[0] <= w_phase;
    end

    for (genvar i = 1; i < RF_CORDIC_STAGES + 2; i++) begin
        always_ff @(posedge w_clk) begin
            r_phase_ffs[i] <= r_phase_ffs[i - 1];
        end
    end

    function automatic void check_sin_cos
    (
        input string                     name,
        input logic signed [13:0]       sin_val,
        input logic signed [13:0]       cos_val,
        input logic signed [13:0]       sin_gold,
        input logic signed [13:0]       cos_gold,
        input int                       tolerate
    );
        int sin_err, cos_err;
        begin
            sin_err = $signed(sin_val) - $signed(sin_gold);
            cos_err = $signed(cos_val) - $signed(cos_gold);

            if ((sin_err > tolerate) || (sin_err < -tolerate) ||
                (cos_err > tolerate) || (cos_err < -tolerate)) begin
                $display("[%0t] %s mismatch: sin=%0d (0x%h), sin_gold=%0d (0x%h), sin_err=%0d, cos=%0d (0x%h), cos_gold=%0d (0x%h), cos_err=%0d, tolerate=%0d",
                    $time, name,
                    $signed(sin_val),  sin_val,
                    $signed(sin_gold), sin_gold,
                    sin_err,
                    $signed(cos_val),  cos_val,
                    $signed(cos_gold), cos_gold,
                    cos_err,
                    tolerate);
            end
        end
    endfunction

    logic signed [PHASE_W-1:0] phase;
    logic signed [13:0] cos_gold, sin_gold;

    assign phase = r_phase_ffs[RF_CORDIC_STAGES+1];

    initial begin

        repeat (18) @(posedge w_clk);

        forever begin
            @(negedge w_clk);
            cos_gold = golden_cos(phase);
            sin_gold = golden_sin(phase);
            check_sin_cos("I/Q", w_Q, w_I, sin_gold, cos_gold, 1);
        end
    end

    initial begin

        w_rst = 1'b1;
        @(negedge w_clk);
        w_rst = 1'b0;

        w_phase = 'd0;
        for (int i = 0; i < 2 ** RF_PHASE_WIDTH; i++) begin
            @(negedge w_clk);
            w_phase = w_phase + 'd1;
        end

        #100;
        $finish;
    end

endmodule
