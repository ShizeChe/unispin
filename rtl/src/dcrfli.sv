`default_nettype none
`timescale 1ns / 1ps
`include "dc.svh"
`include "rf.svh"

module dcrfli
   #(parameter NUM_DC_CHANNEL=24,
     parameter NUM_RF_CHANNEL=6,
     parameter NUM_LI_CHANNEL=1)
    (input  logic i_clk, i_rst,

     input  logic [0:NUM_DC_CHANNEL-1][0:DC_TOTAL_REGS-1][31:0] i_dc_regs,

     output logic [0:NUM_DC_CHANNEL-1] o_dc_sclk_bus,
     output logic [0:NUM_DC_CHANNEL-1] o_dc_mosi_bus,
     input  logic [0:NUM_DC_CHANNEL-1] i_dc_miso_bus,
     output logic [0:NUM_DC_CHANNEL-1] o_dc_cs_n_bus,
     output logic [0:NUM_DC_CHANNEL-1] o_dc_ldac_n_bus,

     input  logic [0:NUM_RF_CHANNEL-1][0:RF_TOTAL_REGS-1][31:0] i_rf_regs,

     output logic [0:NUM_RF_CHANNEL-1][RF_DAC_WIDTH*16-1:0] o_rf_QIx8_bus,

     input  logic [0:LCH_TOTAL_REGS-1][31:0] i_lch_regs,

     input  logic i_trigger);
     
    logic [0:NUM_DC_CHANNEL-1] w_dc_start_bus;
    logic [0:NUM_DC_CHANNEL-1] w_dc_armed_bus;

    for (genvar i = 0; i < NUM_DC_CHANNEL; i++) begin : DC_GEN

        dc DC (
            .i_clk(i_clk),
            .i_rst(i_rst),

            .i_regs(i_dc_regs[i]),

            .o_sclk(o_dc_sclk_bus[i]),
            .o_mosi(o_dc_mosi_bus[i]),
            .i_miso(i_dc_miso_bus[i]),
            .o_cs_n(o_dc_cs_n_bus[i]),
            .o_ldac_n(o_dc_ldac_n_bus[i]),

            .i_start(w_dc_start_bus[i]),
            .o_armed(w_dc_armed_bus[i])
        );

    end

    logic [NUM_RF_CHANNEL-1:0] w_rf_armed_bus;
    logic [NUM_RF_CHANNEL-1:0] w_rf_start_bus;

    for (genvar i = 0; i < NUM_RF_CHANNEL; i++) begin : RF_GEN

        rf RF (
            .i_clk(i_clk),
            .i_rst(i_rst),

            .i_regs(i_rf_regs[i]),

            .o_QIx8(o_rf_QIx8_bus[i]),

            .i_start(w_rf_start_bus[i]),
            .o_armed(w_rf_armed_bus[i])
        );

    end

    launch #(
        .NUM_DC_CHANNEL(NUM_DC_CHANNEL),
        .NUM_RF_CHANNEL(NUM_RF_CHANNEL),
        .NUM_LI_CHANNEL(NUM_LI_CHANNEL)
    ) LCH (
        .i_clk(i_clk),
        .i_rst(i_rst),

        .i_regs(i_lch_regs),

        .i_dc_armed(w_dc_armed_bus),
        .i_rf_armed(w_rf_armed_bus),
        .i_li_armed(NUM_LI_CHANNEL'('h0)),

        .i_trigger(i_trigger),

        .o_dc_start(w_dc_start_bus),
        .o_rf_start(w_rf_start_bus),
        .o_li_start()
    );

endmodule
