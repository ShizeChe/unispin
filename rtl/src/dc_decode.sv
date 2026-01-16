// `default_nettype none
`timescale 1ns / 1ps
`include "dc.svh"

module dc_decode
   #(parameter DEPTH=DC_DEPTH)
    (input  logic [$clog2(DEPTH)-1:0] i_addr,
     input  dc_insn_t i_insn,
     output dc_decode_stg_t d,
     output dc_insn_t o_insn_modified);

    always_comb begin

        d = '{
            w_addr: i_addr,
            w_iters: i_insn.w_iters,
            w_spi_din: i_insn.w_spi_din,
            w_dspi_din: i_insn.w_dspi_din,
            w_spi_rd: i_insn.w_spi_rd,
            w_strb_ldac: i_insn.w_strb_ldac,
            w_hold_cycles: i_insn.w_hold_cycles,
            w_modify: i_insn.w_modify,
            w_arm: i_insn.w_arm
        };

        o_insn_modified = i_insn;
        o_insn_modified.w_arm = 1'b0;

        if (i_insn.w_modify)
            o_insn_modified.w_spi_din = {
                i_insn.w_spi_din[DC_SPI_DATA_WIDTH-1:DC_DAC_WIDTH],
                i_insn.w_spi_din[DC_DAC_WIDTH-1:0] + i_insn.w_dspi_din
            };

    end

endmodule

