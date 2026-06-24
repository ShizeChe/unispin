// `default_nettype none
`timescale 1ns / 1ps
`include "li.svh"

module li_decode
   #(parameter DEPTH=LI_DEPTH,
     parameter PC_ADDR_WIDTH=LI_PC_ADDR_WIDTH)
    (input  logic [$clog2(DEPTH)-1:0] i_pc,
     input  logic [PC_ADDR_WIDTH-1:0] i_pc_addr,
     input  li_insn_t i_insn,
     output li_decode_stg_t d,
     output li_insn_t o_insn_modified);

    always_comb begin

        d.w_pc_addr = i_pc_addr;
        d.w_pc = i_pc;
        d.w_samples = i_insn.w_samples;
        d.w_dsamples = i_insn.w_dsamples;
        d.w_arm = i_insn.w_arm || i_insn.w_sticky_arm;
        d.w_idle = i_insn.w_idle;
        d.w_marker = i_insn.w_marker;
        d.w_stride = i_insn.w_stride;

        o_insn_modified = i_insn;
        o_insn_modified.w_arm = 1'b0;
        o_insn_modified.w_sticky_arm = i_insn.w_sticky_arm;
        o_insn_modified.w_marker = i_insn.w_marker;
        o_insn_modified.w_samples = i_insn.w_samples + i_insn.w_dsamples;

    end

endmodule

