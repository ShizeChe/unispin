`timescale 1ns / 1ps

module cordic_tb;

    localparam PHASE_WIDTH = 18;
    localparam IQ_WIDTH=14;
    localparam NUM_STAGES=15;
    localparam PAD_ZEROS=8;

    logic w_clk;
    logic [PHASE_WIDTH-1:0] w_phase;
    logic [IQ_WIDTH-1:0] w_I, w_Q;

    cordic #(
        .PHASE_WIDTH(PHASE_WIDTH),
        .IQ_WIDTH(IQ_WIDTH),
        .NUM_STAGES(NUM_STAGES),
        .PAD_ZEROS(PAD_ZEROS)
    ) dut (
        .i_clk(w_clk),
        .i_phase(w_phase),
        .o_I(w_I),
        .o_Q(w_Q)
    );

    initial begin
        w_clk = 1'b0;
        forever #5 w_clk = !w_clk;
    end

    initial begin
        w_phase = 'd0;
        for (int i = 0; i < 2 ** PHASE_WIDTH; i++) begin
            @(negedge w_clk);
            w_phase = w_phase + 'd1;
        end

        #100;
        $finish;
    end

endmodule
