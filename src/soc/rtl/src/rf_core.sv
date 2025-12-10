`timescale 1ns / 1ps

module rf_core
   #(parameter KBC_WIDTH=36,
     parameter NUM_SAMPLE_WIDTH=20,
     parameter INSN_WIDTH=KBC_WIDTH*2+NUM_SAMPLE_WIDTH*2+3,
     parameter IQ_WIDTH=14,
     parameter DAC_WIDTH=16,
     parameter PHASE_WIDTH=18,
     parameter CORDIC_STAGES=15,
     parameter CORDIC_PAD_ZEROS=8)
    (input  logic i_clk, i_rst,
     
     input  logic [INSN_WIDTH-1:0] i_insn,
     output logic o_next,
     input  logic i_empty,
     output logic [INSN_WIDTH-1:0] o_insn_modified,

     output logic [DAC_WIDTH*16-1:0] o_QIx8,

     input  logic i_start,
     output logic o_armed);

    logic [KBC_WIDTH-1:0] w_k;
    logic [KBC_WIDTH-1:0] w_b;
    logic [KBC_WIDTH-1:0] w_c;

    logic [NUM_SAMPLE_WIDTH-1:0] w_samples;

    logic w_arm;
    logic w_idle;

    rf_decode #(
        .KBC_WIDTH(KBC_WIDTH),
        .NUM_SAMPLE_WIDTH(NUM_SAMPLE_WIDTH)
    ) DECODER (
        .i_insn(i_insn),
        .o_k(w_k), 
        .o_b(w_b), 
        .o_c(w_c),
        .o_samples(w_samples),
        .o_arm(w_arm),
        .o_idle(w_idle),
        .o_insn_modified(o_insn_modified)
    );

    logic [NUM_SAMPLE_WIDTH-1:0] r_samples;
    logic r_idle;
    logic r_arm;

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            r_samples <= 'd0;
            r_idle <= 1'b1;
            r_arm <= 1'b0;
        end
        else if (o_next) begin
            r_samples <= w_samples;
            r_idle <= w_idle;
            r_arm <= w_arm;
        end
        else begin
            r_samples <= r_samples < 'd8 ? 'd0 : r_samples - 'd8;
            r_arm <= 1'b0;
        end
    end

    assign o_next = (r_samples <= 'd8) && !i_empty;

    logic w_stall;

    logic [7:0][PHASE_WIDTH-1:0] w_phasex8;
    logic w_set_phasor;

    assign w_set_phasor = o_next;

    parabolic_counterx8 #(
        .IW(PHASE_WIDTH*2),
        .OW(PHASE_WIDTH)
    ) PHASOR (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_set(w_set_phasor),
        .i_k(w_k),
        .i_b(w_b),
        .i_c(w_c),
        .o_p(w_phasex8),
        .i_stall(w_stall)
    );

    logic [7:0] w_zerox8;

    always_comb begin
        if (r_idle) begin
            w_zerox8 = 8'hff;
        end
        else begin
            w_zerox8 = ~((8'b1 << r_samples) - 8'd1);
        end
    end

    logic [7:0] w_arm_now;
    logic [IQ_WIDTH-1:0] w_Ix8_cordic [0:7];
    logic [IQ_WIDTH-1:0] w_Qx8_cordic [0:7];

    for (genvar i = 0; i < 8; i++) begin : CORDIC_GEN

        cordic #(
            .PHASE_WIDTH(PHASE_WIDTH),
            .IQ_WIDTH(IQ_WIDTH),
            .NUM_STAGES(CORDIC_STAGES),
            .PAD_ZEROS(CORDIC_PAD_ZEROS),
            .OPT_DATA_WIDTH(1)
        ) CORDIC (
            .i_clk(i_clk),
            .i_rst(i_rst),
            .i_phase(w_phasex8[i]),
            .i_zero(w_zerox8[i]),
            .i_opt_data(r_arm),
            .i_opt_data_rst(1'b0),
            .o_I(w_Ix8_cordic[i]),
            .o_Q(w_Qx8_cordic[i]),
            .o_opt_data(w_arm_now[i]),
            .i_stall(w_stall)
        );

        always_ff @(posedge i_clk) begin
            o_QIx8[DAC_WIDTH*2*(i+1)-1:DAC_WIDTH*2*i] <= 
            w_stall ? 'h0 : {w_Qx8_cordic[i], 2'b00, w_Ix8_cordic[i], 2'b00};
        end

    end

    assign o_armed = |w_arm_now;
    assign w_stall = o_armed && !i_start; 

endmodule
