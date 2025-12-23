`default_nettype none
`timescale 1ns / 1ps
`include "include/rf.svh"

module rf_decode 
   #(parameter DEPTH=RF_DEPTH)
    (input  logic [$clog2(DEPTH)-1:0] i_addr,
     input  rf_insn_t i_insn,
     output rf_decode_stg_t d,
     output rf_insn_t o_insn_modified);

    always_comb begin

        d.w_addr = i_addr;
        d.w_samples = i_insn.w_samples;
        d.w_arm = i_insn.w_arm;

        case (i_insn.w_kbc_mode)
            RF_KB: begin
                d.w_k = i_insn.w_kbc1;
                d.w_b = i_insn.w_kbc2;
                d.w_c = 'h0;
                d.w_idle = 1'b0;
                d.w_set_phasor = 1'b1;
            end
            RF_BC: begin
                d.w_k = 'h0;
                d.w_b = i_insn.w_kbc1;
                d.w_c = i_insn.w_kbc2;
                d.w_idle = 1'b0;
                d.w_set_phasor = 1'b1;
            end
            RF_IDLE: begin
                d.w_k = 'h0;
                d.w_b = 'h0;
                d.w_c = 'h0;
                d.w_idle = 1'b1;
                d.w_set_phasor = 1'b0;
            end
            default: begin
                d.w_k = 'h0;
                d.w_b = 'h0;
                d.w_c = 'h0;
                d.w_idle = 1'b1;
                d.w_set_phasor = 1'b0;
            end
        endcase

        o_insn_modified = i_insn;
        o_insn_modified.w_arm = 1'b0;
        o_insn_modified.w_samples = i_insn.w_samples + i_insn.w_dsamples;

    end

endmodule
