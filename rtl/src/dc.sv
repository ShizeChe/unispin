// `default_nettype none
`timescale 1ns / 1ps
`include "dc.svh"

module dc
   #(parameter SPI_DATA_WIDTH=DC_SPI_DATA_WIDTH,
     parameter CYCLE_WIDTH=DC_CYCLE_WIDTH,
     parameter SEQ_ITER_WIDTH=DC_SEQ_ITER_WIDTH,
     parameter CORE_ITER_WIDTH=DC_CORE_ITER_WIDTH,
     parameter DEPTH=DC_DEPTH,
     parameter INSN_WIDTH=DC_INSN_WIDTH,
     parameter REG_PER_INSN=DC_REG_PER_INSN,
     parameter SEQ_REGS=DC_SEQ_REGS,
     parameter CTRL_REGS=DC_CTRL_REGS)
    (input  logic i_clk, i_rst,
     
     input  logic [0:SEQ_REGS-1][31:0] i_seq_regs,
     input  logic [0:CTRL_REGS-1][31:0] i_ctrl_regs,

     output logic o_sclk,
     output logic o_mosi,
     input  logic i_miso,
     output logic o_cs_n,
     output logic o_ldac_n,

     input  logic i_start,
     output logic o_armed);

    logic w_next, w_empty;
    logic [$clog2(DEPTH)-1:0] w_addr;
    dc_insn_t w_insn, w_insn_modified;

    sequencer #(
        .INSN_WIDTH(INSN_WIDTH),
        .ITER_WIDTH(SEQ_ITER_WIDTH),
        .DEPTH(DEPTH)
    ) SEQ (
        .i_clk(i_clk),
        .i_rst(i_rst),

        .i_regs(i_seq_regs),

        .o_addr(w_addr),
        .o_insn(w_insn),
        .i_next(w_next),
        .o_empty(w_empty),
        .i_insn_modified(w_insn_modified)
    );

    logic dc_ctrl_t w_ctrl;

    dc_core #(
        .SPI_DATA_WIDTH(SPI_DATA_WIDTH),
        .CYCLE_WIDTH(CYCLE_WIDTH),
        .ITER_WIDTH(CORE_ITER_WIDTH)
    ) CORE (
        .i_clk(i_clk),
        .i_rst(i_rst),

        .i_addr(w_addr),
        .i_insn(w_insn),
        .o_next(w_next),
        .i_empty(w_empty),
        .o_insn_modified(w_insn_modified),

        .i_ctrl(w_ctrl),

        .o_sclk(o_sclk),
        .o_mosi(o_mosi),
        .i_miso(i_miso),
        .o_cs_n(o_cs_n),
        .o_ldac_n(o_ldac_n),

        .i_start(i_start),
        .o_armed(o_armed),

        // signals for verification only
        .o_addr(),
        .o_iter(),
        .o_spi_din(),
        .o_spi_rd(),
        .o_spi_dout(),
        .o_cycles_left()
    );

    dc_ctrl #(
        .CTRL_REGS(CTRL_REGS),
        .SPI_DVSR_WIDTH(DVSR_WIDTH),
        .SPI_CS_UP_WIDTH(CS_UP_WIDTH),
        .SPI_LDAC_WIDTH(LDAC_WIDTH)
    ) CTRL (
        .i_clk(i_clk),
        .i_rst(i_rst),

        .i_regs(i_ctrl_regs),

        .o_ctrl(w_ctrl)
    );

endmodule
