`default_nettype none
`timescale 1ns / 1ps
`include "include/internal.svh"

module dc_decode
   #(parameter DEPTH=DC_DEPTH)
    (input  logic [$clog2(DEPTH)-1:0] i_addr,
     input  rf_insn_t i_insn,
     output rf_decode_stg_t d,
     output rf_insn_t o_insn_modified);

    always_comb begin

        d = '{
            w_addr: i_addr,
            w_iters: i_insn.w_iters,
            w_spi_dvsr: i_insn.w_spi_dvsr,
            w_dcc: i_insn.w_dcc,
            w_ddcc: i_insn.w_ddcc,
            w_cycles: i_insn.w_cycles,
            w_arm: i_insn.w_arm
        };

        o_insn_modified = i_insn;
        o_insn_modified.w_arm = 1'b0;

        if (i_insn.w_modify)
            o_insn_modified.w_dcc = i_insn.w_dcc + i_insn.w_ddcc;

    end

endmodule

