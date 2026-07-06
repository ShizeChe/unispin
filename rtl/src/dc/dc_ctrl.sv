// `default_nettype none
`timescale 1ns / 1ps
`include "dc.svh"

module dc_ctrl
   #(parameter CTRL_REGS=DC_CTRL_REGS,
     parameter SPI_DVSR_WIDTH=DC_SPI_DVSR_WIDTH,
     parameter SPI_DELAY_WIDTH=DC_SPI_DELAY_WIDTH,
     parameter SPI_CS_UP_WIDTH=DC_SPI_CS_UP_WIDTH,
     parameter SPI_LDAC_WIDTH=DC_SPI_LDAC_WIDTH)
    (input  logic i_clk, i_rst,

     input  logic [0:CTRL_REGS-1][31:0] i_regs,

     output dc_ctrl_t o_ctrl);

    logic w_new_ctrl;

    edge_detector SEQWR (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_signal(i_regs[DC_CTRL_STRB_REG][0]),
        .o_posedge(w_new_ctrl),
        .o_negedge()
    );

    logic [SPI_DVSR_WIDTH-1:0] r_dvsr;
    logic [SPI_DELAY_WIDTH-1:0] r_delay_cycles;
    logic [SPI_CS_UP_WIDTH-1:0] r_cs_up_cycles;
    logic [SPI_LDAC_WIDTH-1:0] r_ldac_cycles;

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            r_dvsr <= 'd6;
            r_delay_cycles <= 'd3;
            r_cs_up_cycles <= 'd3;
            r_ldac_cycles <= 'd2;
        end
        else if (w_new_ctrl) begin
            r_dvsr <= i_regs[DC_DVSR_REG][SPI_DVSR_WIDTH-1:0];
            r_delay_cycles <= i_regs[DC_DELAY_REG][SPI_DELAY_WIDTH-1:0];
            r_cs_up_cycles <= i_regs[DC_CS_UP_REG][SPI_CS_UP_WIDTH-1:0];
            r_ldac_cycles <= i_regs[DC_LDAC_REG][SPI_LDAC_WIDTH-1:0];
        end
    end

    assign o_ctrl.w_dvsr = r_dvsr;
    assign o_ctrl.w_delay_cycles = r_delay_cycles;
    assign o_ctrl.w_cs_up_cycles = r_cs_up_cycles;
    assign o_ctrl.w_ldac_cycles = r_ldac_cycles;

endmodule
