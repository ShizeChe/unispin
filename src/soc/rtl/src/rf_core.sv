`default_nettype none
`timescale 1ns / 1ps
`include "include/internal.svh"

module rf_core
   #(parameter KBC_WIDTH=RF_KBC_WIDTH,
     parameter NUM_SAMPLE_WIDTH=RF_NUM_SAMPLE_WIDTH,
     parameter INSN_WIDTH=RF_INSN_WIDTH,
     parameter IQ_WIDTH=RF_IQ_WIDTH,
     parameter DAC_WIDTH=RF_DAC_WIDTH,
     parameter PHASE_WIDTH=RF_PHASE_WIDTH,
     parameter CORDIC_STAGES=RF_CORDIC_STAGES,
     parameter CORDIC_PAD_ZEROS=RF_CORDIC_PAD_ZEROS,
     parameter DEPTH=RF_DEPTH)
    (input  logic i_clk, i_rst,
     
     input  logic [$clog2(DEPTH)-1:0] i_addr,
     input  rf_insn_t i_insn,
     output logic o_next,
     input  logic i_empty,
     output rf_insn_t o_insn_modified,

     output rf_output_stg_t o,

     input  logic i_start,
     output logic o_armed);

    logic w_stall;

    rf_decode_stg_t d;

    rf_decode #(
        .DEPTH(DEPTH)
    ) DECODER (
        .i_addr(i_addr),
        .i_insn(i_insn),
        .d(d),
        .o_insn_modified(o_insn_modified)
    );

    rf_execute_stg_t x;

    rf_phasor #(
        .IW(PHASE_WIDTH*2),
        .OW(PHASE_WIDTH)
    ) PHASOR (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_set(d.w_set_phasor && o_next),
        .i_k(x.r_k),
        .i_b(x.r_b),
        .i_c(x.r_c),
        .o_p(x.w_phasex8),
        .i_stall(w_stall)
    );

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            x.r_addr <= 'bx;
            x.r_k <= 'bx;
            x.r_b <= 'bx;
            x.r_c <= 'bx;
            x.r_samples <= 'bx;
            x.r_samples_left <= 'd0;
            x.r_arm <= 1'b0;
            x.r_idle <= 1'b0;
        end
        else if (!w_stall) begin

            if (x.r_samples_left > 'd8) begin
                x.r_arm <= 1'b0;
                x.r_samples_left <= x.r_samples_left - 'd8;
            end
            else if (!i_empty) begin
                x.r_addr <= d.w_addr;
                x.r_k <= d.w_k;
                x.r_b <= d.w_b;
                x.r_c <= d.w_c;
                x.r_samples <= d.w_samples;
                x.r_samples_left <= d.w_samples;
                x.r_arm <= d.w_arm;
                x.r_idle <= d.w_idle;
            end
            else begin
                x.r_arm <= 1'b0;
                x.r_samples_left <= 'd0;
            end

        end
    end

    assign o_next = (x.r_samples_left <= 'd8) && !i_empty;

    assign x.w_zerox8 = x.r_idle ? 8'hff : ~((8'b1 << x.r_samples_left) - 8'd1);

    rf_result_stg_t r [0:7];

    for (genvar i = 0; i < 8; i++) begin : CORDIC_GEN

        rf_cordic #(
            .PHASE_WIDTH(PHASE_WIDTH),
            .IQ_WIDTH(IQ_WIDTH),
            .NUM_STAGES(CORDIC_STAGES),
            .PAD_ZEROS(CORDIC_PAD_ZEROS),
            .INDEX(i)
        ) CORDIC (
            .i_clk(i_clk),
            .i_rst(i_rst),
            .x(x),
            .r(r[i]),
            .i_stall(w_stall)
        );

    end

    assign o_armed = |{r[0].r_arm, r[1].r_arm, r[2].r_arm, r[3].r_arm,
                       r[4].r_arm, r[5].r_arm, r[6].r_arm, r[7].r_arm};
    assign w_stall = o_armed && !i_start; 

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            o <= '{
                r_addr: 'bx,
                r_sample_start: 'bx,
                r_sample_end: 'bx,
                r_QIx8: 'h0
            };
        end
        else if (!w_stall) begin
            o <= '{
                r_addr: r[0].r_addr,
                r_sample_start: r[0].r_sample,
                r_sample_end: (
                    r[7] === r[7] ? r[7].r_sample :
                    r[6] === r[6] ? r[6].r_sample :
                    r[5] === r[5] ? r[5].r_sample :
                    r[4] === r[4] ? r[4].r_sample :
                    r[3] === r[3] ? r[3].r_sample :
                    r[2] === r[2] ? r[2].r_sample :
                    r[1] === r[1] ? r[1].r_sample :
                    r[0] === r[0] ? r[0].r_sample : 'bx
                ),
                r_QIx8: {
                    r[7].r_Q, PAD, r[7].r_Q, PAD, 
                    r[6].r_Q, PAD, r[6].r_Q, PAD, 
                    r[5].r_Q, PAD, r[5].r_Q, PAD, 
                    r[4].r_Q, PAD, r[4].r_Q, PAD, 
                    r[3].r_Q, PAD, r[3].r_Q, PAD, 
                    r[2].r_Q, PAD, r[2].r_Q, PAD, 
                    r[1].r_Q, PAD, r[1].r_Q, PAD, 
                    r[0].r_Q, PAD, r[0].r_Q, PAD 
                }
            };
        end
    end

endmodule
