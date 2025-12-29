`default_nettype none
`timescale 1ns / 1ps
`include "include/rf.svh"

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
     
     // sequencer interface
     input  logic [$clog2(DEPTH)-1:0] i_addr,
     input  rf_insn_t i_insn,
     output logic o_next,
     input  logic i_empty,
     output rf_insn_t o_insn_modified,

     // output interface
     output logic [$clog2(DEPTH)-1:0] o_addr,
     output logic [NUM_SAMPLE_WIDTH-1:0] o_sample_start,
     output logic [NUM_SAMPLE_WIDTH-1:0] o_sample_end,
     output logic [DAC_WIDTH*16-1:0] o_QIx8,

     // launcher interface
     input  logic i_start,
     output logic o_armed);

    logic w_stall;

    /**************
    * decode stage
    **************/

    rf_decode_stg_t d;

    rf_decode #(
        .DEPTH(DEPTH)
    ) DECODER (
        .i_addr(i_addr),
        .i_insn(i_insn),
        .d(d),
        .o_insn_modified(o_insn_modified)
    );

    /*************
    * phase stage
    *************/

    rf_phase_stg_t p;

    rf_phasor #(
        .IW(PHASE_WIDTH*2),
        .OW(PHASE_WIDTH)
    ) PHASOR (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_set(d.w_set_phasor && o_next),
        .i_k(p.r_k),
        .i_b(p.r_b),
        .i_c(p.r_c),
        .o_p(p.w_phasex8),
        .i_stall(w_stall)
    );

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            p.r_addr <= 'bx;
            p.r_k <= 'bx;
            p.r_b <= 'bx;
            p.r_c <= 'bx;
            p.r_samples <= 'bx;
            p.r_samples_left <= 'd0;
            p.r_arm <= 1'b0;
            p.r_idle <= 1'b0;
        end
        else if (!w_stall) begin

            if (p.r_samples_left > 'd8) begin
                p.r_arm <= 1'b0;
                p.r_samples_left <= p.r_samples_left - 'd8;
            end
            else if (!i_empty) begin
                p.r_addr <= d.w_addr;
                p.r_k <= d.w_k;
                p.r_b <= d.w_b;
                p.r_c <= d.w_c;
                p.r_samples <= d.w_samples;
                p.r_samples_left <= d.w_samples;
                p.r_arm <= d.w_arm;
                p.r_idle <= d.w_idle;
            end
            else begin
                p.r_arm <= 1'b0;
                p.r_samples_left <= 'd0;
            end

        end
    end

    assign o_next = (p.r_samples_left <= 'd8) && !i_empty;

    assign p.w_zerox8 = p.r_idle ? 8'hff : ~((8'b1 << p.r_samples_left) - 8'd1);

    /*************************
    * cordic and result stage
    **************************/

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
            .p(p),
            .r(r[i]),
            .i_stall(w_stall)
        );

    end

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            o_addr <= 'bx;
            o_sample_start <= 'bx;
            o_sample_end <= 'bx;
            o_QIx8 <= 'h0;
        end
        else if (!w_stall) begin
            o_addr <= r[0].r_addr;
            o_sample_start <= r[0].r_sample;
            o_sample_end <= (
                !r[7].r_bubble ? r[7].r_sample :
                !r[6].r_bubble ? r[6].r_sample :
                !r[5].r_bubble ? r[5].r_sample :
                !r[4].r_bubble ? r[4].r_sample :
                !r[3].r_bubble ? r[3].r_sample :
                !r[2].r_bubble ? r[2].r_sample :
                !r[1].r_bubble ? r[1].r_sample :
                !r[0].r_bubble ? r[0].r_sample : 'bx
            );
            o_QIx8 <= {
                r[7].r_Q, PAD, r[7].r_Q, PAD, 
                r[6].r_Q, PAD, r[6].r_Q, PAD, 
                r[5].r_Q, PAD, r[5].r_Q, PAD, 
                r[4].r_Q, PAD, r[4].r_Q, PAD, 
                r[3].r_Q, PAD, r[3].r_Q, PAD, 
                r[2].r_Q, PAD, r[2].r_Q, PAD, 
                r[1].r_Q, PAD, r[1].r_Q, PAD, 
                r[0].r_Q, PAD, r[0].r_Q, PAD 
            };
        end
    end

    assign o_armed = |{r[0].r_arm, r[1].r_arm, r[2].r_arm, r[3].r_arm,
                       r[4].r_arm, r[5].r_arm, r[6].r_arm, r[7].r_arm};

    assign w_stall = o_armed && !i_start; 

endmodule
