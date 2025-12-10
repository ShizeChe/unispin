`timescale 1ns / 1ps

module rf_core
   #(parameter KBC_WIDTH=36,
     parameter NUM_SAMPLE_WIDTH=30,
     parameter ITER_WIDTH=10,
     parameter INSN_WIDTH=KBC_WIDTH*3+ITER_WIDTH+NUM_SAMPLE_WIDTH*4,
     parameter IQ_WIDTH=14,
     parameter DAC_WIDTH=16,
     parameter PHASE_WIDTH=18,
     parameter CORDIC_STAGES=15,
     parameter CORDIC_PAD_ZEROS=8)
    (input  logic i_clk, i_rst,
     
     input  logic [INSN_WIDTH-1:0] i_insn,
     output logic o_next,
     input  logic i_empty,

     output logic [DAC_WIDTH*16-1:0] o_QIx8,

     input  logic i_start,
     output logic o_armed);

    logic [KBC_WIDTH-1:0] w_k_decode;
    logic [KBC_WIDTH-1:0] w_b_decode;
    logic [KBC_WIDTH-1:0] w_c_decode;

    logic [ITER_WIDTH-1:0] w_iters_decode;

    logic [NUM_SAMPLE_WIDTH-1:0] w_dkbcs_decode;
    logic [NUM_SAMPLE_WIDTH-1:0] w_kbcs_decode;
    logic [NUM_SAMPLE_WIDTH-1:0] w_dzeros_decode;
    logic [NUM_SAMPLE_WIDTH-1:0] w_zeros_decode;

    assign {w_k_decode, w_b_decode, w_c_decode,
            w_iters_decode, w_dkbcs_decode, w_kbcs_decode,
            w_dzeros_decode, w_zeros_decode} = i_insn;

    logic [NUM_SAMPLE_WIDTH-1:0] r_samples;
    logic [NUM_SAMPLE_WIDTH-1:0] w_samples_next;

    logic [ITER_WIDTH-1:0] r_iters;
    logic [ITER_WIDTH-1:0] w_iters_next;

    logic r_mode, w_mode_next;
    logic r_ibubble, w_ibubble_next;

    logic [NUM_SAMPLE_WIDTH-1:0] r_dkbcs, w_dkbcs_next;
    logic [NUM_SAMPLE_WIDTH-1:0] r_kbcs, w_kbcs_next;
    logic [NUM_SAMPLE_WIDTH-1:0] r_dzeros, w_dzeros_next;
    logic [NUM_SAMPLE_WIDTH-1:0] r_zeros, w_zeros_next;

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            r_dkbcs <= 'h0;
            r_kbcs <= 'h0;
            r_dzeros <= 'h0;
            r_zeros <= 'h0;
            r_samples <= 'h0;
            r_iters <= 'h0;
            r_mode <= 'b0;
            r_ibubble <= 'b1;
        end
        else begin
            r_dkbcs <= w_dkbcs_next;
            r_kbcs <= w_kbcs_next;
            r_dzeros <= w_dzeros_next;
            r_zeros <= w_zeros_next;
            r_samples <= w_samples_next;
            r_iters <= w_iters_next;
            r_mode <= w_mode_next;
            r_ibubble <= w_ibubble_next;
        end
    end

    logic w_stall;
    logic [7:0][1:0] r_masks [0:CORDIC_STAGES+1];

    for (genvar i = 1; i <= CORDIC_STAGES + 1; i++) begin
        always_ff @(posedge i_clk) begin
            if (i_rst) r_masks[i] <= {8{2'b10}};
            else if (!w_stall) r_masks[i] <= r_masks[i - 1];
        end
    end

    logic [7:0][PHASE_WIDTH-1:0] w_phasex8;
    logic w_set_phasor;

    parabolic_counterx8 #(
        .IW(PHASE_WIDTH*2),
        .OW(PHASE_WIDTH)
    ) phasor (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_set(w_set_phasor),
        .i_k(w_k_decode),
        .i_b(w_b_decode),
        .i_c(w_c_decode),
        .o_p(w_phasex8),
        .i_stall(w_stall)
    );

    logic [IQ_WIDTH-1:0] w_Ix8_cordic [0:7];
    logic [IQ_WIDTH-1:0] w_Qx8_cordic [0:7];

    for (genvar i = 0; i < 8; i++) begin

        cordic #(
            .PHASE_WIDTH(PHASE_WIDTH),
            .IQ_WIDTH(IQ_WIDTH),
            .NUM_STAGES(CORDIC_STAGES),
            .PAD_ZEROS(CORDIC_PAD_ZEROS)
        ) IQ_gen (
            .i_clk(i_clk),
            .i_phase(w_phasex8[i]),
            .o_I(w_Ix8_cordic[i]),
            .o_Q(w_Qx8_cordic[i]),
            .i_stall(w_stall)
        );

        always_ff @(posedge i_clk) begin
            if (!w_stall && 
                r_masks[CORDIC_STAGES+1][i] == 2'b01) begin

                o_QIx8[DAC_WIDTH*2*(i+1)-1:DAC_WIDTH*2*i] <=
                {w_Qx8_cordic[i], 2'b00, w_Ix8_cordic[i], 2'b00};

            end
            else begin
                o_QIx8[DAC_WIDTH*2*(i+1)-1:DAC_WIDTH*2*i] <= 'h0;
            end
        end

    end

    // mutually exclusive indicator signals
    logic w_switch_mode, w_small_propagate, w_big_propagate;
    logic w_propagate_bubble;

    assign w_switch_mode = !r_ibubble && (r_samples <= 'd8) && r_mode && 
                           ((r_samples + r_zeros) > 'd8) && !w_stall;

    assign w_small_propagate = !r_ibubble && (r_samples <= 'd8) && 
                               (r_iters > 'd0) && !w_stall && 
                               (!r_mode || (r_mode && ((r_samples + r_zeros) <= 'd8)));

    assign w_big_propagate = !i_empty && (r_ibubble || (!r_ibubble && (r_samples <= 'd8) && 
                             (r_iters == 'd0) && !w_stall &&
                             (!r_mode || (r_mode && ((r_samples + r_zeros) <= 'd8)))));

    assign w_propagate_bubble = i_empty && (r_ibubble || (!r_ibubble && (r_samples <= 'd8) && 
                                (r_iters == 'd0) && !w_stall &&
                                (!r_mode || (r_mode && ((r_samples + r_zeros) <= 'd8)))));

    assign o_next = w_big_propagate;
    assign w_set_phasor = w_big_propagate || w_small_propagate;

    logic [7:0][1:0] w_fine_mask;

    always_comb begin
        case (r_samples[3:0])
            4'd1: w_fine_mask = {{7{2'b00}}, {1{2'b01}}};
            4'd2: w_fine_mask = {{6{2'b00}}, {2{2'b01}}};
            4'd3: w_fine_mask = {{5{2'b00}}, {3{2'b01}}};
            4'd4: w_fine_mask = {{4{2'b00}}, {4{2'b01}}};
            4'd5: w_fine_mask = {{3{2'b00}}, {5{2'b01}}};
            4'd6: w_fine_mask = {{2{2'b00}}, {6{2'b01}}};
            4'd7: w_fine_mask = {{1{2'b00}}, {7{2'b01}}};
            4'd8: w_fine_mask = {8{2'b01}};
            default: w_fine_mask = {8{2'b00}};
        endcase
    end

    always_ff @(posedge i_clk) begin
        if (i_rst || r_ibubble) r_masks[0] <= {8{2'b10}};
        else if (w_switch_mode || 
                 (r_mode && 
                 (w_small_propagate || w_big_propagate || w_propagate_bubble)))
            r_masks[0] <= w_fine_mask;
        else if (!w_stall) r_masks[0] <= r_mode ? {8{2'b01}} : {8{2'b00}};
    end

    logic w_obubble, r_prev_obubble;

    assign w_obubble = (r_masks[CORDIC_STAGES+1] == {8{2'b10}});

    always_ff @(posedge i_clk) 
        if (!w_stall)
            r_prev_obubble <= w_obubble;

    assign w_stall = r_prev_obubble && !w_obubble && !i_start;

    always_ff @(posedge i_clk)
        o_armed <= r_prev_obubble && !w_obubble;

    always_comb begin
        case ({w_big_propagate, w_small_propagate,
               w_switch_mode, w_propagate_bubble})
            4'b1000: begin
                w_dkbcs_next = w_dkbcs_decode;
                w_kbcs_next = w_kbcs_decode;
                w_dzeros_next = w_dzeros_decode;
                w_zeros_next = w_zeros_decode;
                w_samples_next = w_kbcs_decode;
                w_iters_next = w_iters_decode;
                w_mode_next = 1'b1;
                w_ibubble_next = 1'b0;
            end
            4'b0100: begin
                w_dkbcs_next = r_dkbcs;
                w_kbcs_next = r_kbcs + r_dkbcs;
                w_dzeros_next = r_dzeros;
                w_zeros_next = r_zeros + r_dzeros;
                w_samples_next = r_kbcs + r_dkbcs;
                w_iters_next = r_iters - 'd1;
                w_mode_next = 1'b1;
                w_ibubble_next = 1'b0;
            end
            4'b0010: begin
                w_dkbcs_next = r_dkbcs;
                w_kbcs_next = r_kbcs;
                w_dzeros_next = r_dzeros;
                w_zeros_next = r_zeros;
                w_samples_next = r_zeros + r_samples - 'd8;
                w_iters_next = r_iters;
                w_mode_next = 1'b0;
                w_ibubble_next = 1'b0;
            end
            4'b0001: begin
                w_dkbcs_next = 'h0;
                w_kbcs_next = 'h0;
                w_dzeros_next = 'h0;
                w_zeros_next = 'h0;
                w_samples_next ='h0;
                w_iters_next = 'h0;
                w_mode_next = 1'b0;
                w_ibubble_next = 1'b1;
            end
            4'b0000: begin
                w_dkbcs_next = r_dkbcs;
                w_kbcs_next = r_kbcs;
                w_dzeros_next = r_dzeros;
                w_zeros_next = r_zeros;
                w_samples_next = w_stall ? r_samples : r_samples - 'd8;
                w_iters_next = r_iters;
                w_mode_next = r_mode;
                w_ibubble_next = r_ibubble;
            end
            default: begin
                w_dkbcs_next = r_dkbcs;
                w_kbcs_next = r_kbcs;
                w_dzeros_next = r_dzeros;
                w_zeros_next = r_zeros;
                w_samples_next = r_samples;
                w_iters_next = r_iters;
                w_mode_next = r_mode;
                w_ibubble_next = r_ibubble;
            end
        endcase
    end

endmodule
