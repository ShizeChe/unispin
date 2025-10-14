`timescale 1ns / 1ps

module chirp_tb;

    localparam PHASE_WIDTH = 18;
    localparam IQ_WIDTH = 14;
    localparam NUM_STAGES = 15;
    localparam PAD_ZEROS = 8;

    logic w_clk, w_rst;
    logic w_set;
    logic [35:0] w_k;
    logic [35:0] w_b;
    logic [35:0] w_c;
    logic [7:0][17:0] w_p;

    parabolic_counterx8 #(
        .IW(36),
        .OW(PHASE_WIDTH)
    ) phase_counter (
        .i_clk(w_clk),
        .i_rst(w_rst),
        .i_set(w_set),
        .i_k(w_k),
        .i_b(w_b),
        .i_c(w_c),
        .o_p(w_p)
    );

    logic [7:0][PHASE_WIDTH-1:0] w_phasex8;
    logic [7:0][IQ_WIDTH-1:0] w_Ix8, w_Qx8;

    assign w_phasex8 = w_p;

    for (genvar i = 0; i < 8; i++) begin
        cordic #(
            .PHASE_WIDTH(PHASE_WIDTH),
            .IQ_WIDTH(IQ_WIDTH),
            .NUM_STAGES(NUM_STAGES),
            .PAD_ZEROS(PAD_ZEROS)
        ) IQ_gen (
            .i_clk(w_clk),
            .i_phase(w_phasex8[i]),
            .o_I(w_Ix8[i]),
            .o_Q(w_Qx8[i])
        );
    end

    initial begin
        w_clk = 1'b0;
        forever #2 w_clk = !w_clk;
    end

    logic w_dac_clk;

    initial begin
        w_dac_clk = 1'b1;
        forever #0.25 w_dac_clk = !w_dac_clk;
    end

    // simulate DUC with 10MHz
    int dac_cycle;
    initial begin
        @(posedge w_clk);
        dac_cycle = 0;
        forever begin
            @(posedge w_dac_clk);
            dac_cycle = (dac_cycle == 7) ? 0 : (dac_cycle + 1);
        end
    end

    function automatic real iq2real(input int N, input logic [13:0] iq);
        return $itor($signed(iq)) / (1.0 * (1 << (N-1)));
    endfunction

    real I, Q;
    real deg, rad, out;
    logic [PHASE_WIDTH:0] w_phase;
    logic [35:0] w_phase_full;
    logic [13:0] w_I, w_Q;
    initial begin
        deg = 0;
        @(posedge w_clk);
        forever begin
            @(negedge w_dac_clk);
            w_I = w_Ix8[dac_cycle];
            w_Q = w_Qx8[dac_cycle];
            w_phase = w_phasex8[dac_cycle];
            w_phase_full = phase_counter.r_p[dac_cycle];
            I = iq2real(IQ_WIDTH, w_I);
            Q = iq2real(IQ_WIDTH, w_Q);
            deg = deg + 1.8;
            rad = deg * 3.14159265358979323846 / 180.0;
            out = I * $cos(rad) - Q * $sin(rad);
        end
    end

    initial begin

        w_rst = 1'b1;
        @(negedge w_clk)
        w_rst = 1'b0;

        w_set = 1'b1;
        w_k = 36'd34;
        w_b = (~36'd377957105) + 'd1;
        w_c = 'd0;
        @(negedge w_clk);
        w_set = 1'b0;

        #1100000;
        $finish;

    end
    
endmodule
