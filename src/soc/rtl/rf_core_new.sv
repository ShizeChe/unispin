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

endmodule
