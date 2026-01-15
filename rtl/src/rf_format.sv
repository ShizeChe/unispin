// `default_nettype none
`timescale 1ns / 1ps
`include "rf.svh"

module rf_format
   #(parameter NUM_SAMPLE_WIDTH=RF_SAMPLE_WIDTH,
     parameter IQ_WIDTH=RF_IQ_WIDTH,
     parameter DEPTH=RF_DEPTH)
    (input  rf_result_stg_t [0:7] r,
     
     output logic [$clog2(DEPTH)-1:0] o_addr,
     output logic [NUM_SAMPLE_WIDTH-1:0] o_sample_start,
     output logic [NUM_SAMPLE_WIDTH-1:0] o_sample_end,
     output logic [IQ_WIDTH*16-1:0] o_QIx8);

    assign o_addr = r[0].r_addr;

    assign o_sample_start = r[0].r_sample;

    assign o_sample_end = (
        !r[7].r_bubble ? r[7].r_sample :
        !r[6].r_bubble ? r[6].r_sample :
        !r[5].r_bubble ? r[5].r_sample :
        !r[4].r_bubble ? r[4].r_sample :
        !r[3].r_bubble ? r[3].r_sample :
        !r[2].r_bubble ? r[2].r_sample :
        !r[1].r_bubble ? r[1].r_sample :
        !r[0].r_bubble ? r[0].r_sample : 'bx
    );

    assign o_QIx8 = {
        r[7].r_bubble ? i_ctrl.w_default_Q : r[7].r_Q, PAD, 
        r[7].r_bubble ? i_ctrl.w_default_I : r[7].r_I, PAD, 
        r[6].r_bubble ? i_ctrl.w_default_Q : r[6].r_Q, PAD, 
        r[6].r_bubble ? i_ctrl.w_default_I : r[6].r_I, PAD, 
        r[5].r_bubble ? i_ctrl.w_default_Q : r[5].r_Q, PAD, 
        r[5].r_bubble ? i_ctrl.w_default_I : r[5].r_I, PAD, 
        r[4].r_bubble ? i_ctrl.w_default_Q : r[4].r_Q, PAD, 
        r[4].r_bubble ? i_ctrl.w_default_I : r[4].r_I, PAD, 
        r[3].r_bubble ? i_ctrl.w_default_Q : r[3].r_Q, PAD, 
        r[3].r_bubble ? i_ctrl.w_default_I : r[3].r_I, PAD, 
        r[2].r_bubble ? i_ctrl.w_default_Q : r[2].r_Q, PAD, 
        r[2].r_bubble ? i_ctrl.w_default_I : r[2].r_I, PAD, 
        r[1].r_bubble ? i_ctrl.w_default_Q : r[1].r_Q, PAD, 
        r[1].r_bubble ? i_ctrl.w_default_I : r[1].r_I, PAD, 
        r[0].r_bubble ? i_ctrl.w_default_Q : r[0].r_Q, PAD, 
        r[0].r_bubble ? i_ctrl.w_default_I : r[0].r_I, PAD 
    };

endmodule
