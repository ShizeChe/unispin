// `default_nettype none
`timescale 1ns / 1ps
`include "dc.svh"
`include "rf.svh"
`include "li.svh"
`include "ex.svh"
`include "launch.svh"

module processor
   #(parameter NUM_DC_CHANNEL=24,
     parameter NUM_RF_CHANNEL=6,
     parameter NUM_LI_CHANNEL=2,
     parameter NUM_EX_CHANNEL=2,
     parameter NUM_DEBOUNCE_CYCLES=25)
    (input  logic i_clk, i_rst,

     // dc mmio registers
     input  logic [0:NUM_DC_CHANNEL-1][0:DC_SEQ_REGS-1][31:0] i_dc_seq_regs,
     input  logic [0:NUM_DC_CHANNEL-1][0:DC_CTRL_REGS-1][31:0] i_dc_ctrl_regs,
     output logic [0:NUM_DC_CHANNEL-1][0:DC_STATUS_REGS-1][31:0] o_dc_status_regs,

     // dc spi buses
     output logic [0:NUM_DC_CHANNEL-1] o_dc_sclk_bus,
     output logic [0:NUM_DC_CHANNEL-1] o_dc_mosi_bus,
     input  logic [0:NUM_DC_CHANNEL-1] i_dc_miso_bus,
     output logic [0:NUM_DC_CHANNEL-1] o_dc_cs_n_bus,
     output logic [0:NUM_DC_CHANNEL-1] o_dc_ldac_n_bus,

     // dc armed bus for LED
     output logic [NUM_DC_CHANNEL-1:0] o_dc_armed_bus,

     // dc empty bus for simulation
     output logic [0:NUM_DC_CHANNEL-1] o_dc_empty_bus,

     // dc eop bus
     output dc_eop_t [0:NUM_DC_CHANNEL-1] o_dc_eop_bus,

     // rf mmio registers
     input  logic [0:NUM_RF_CHANNEL-1][0:RF_SEQ_REGS-1][31:0] i_rf_seq_regs,
     input  logic [0:NUM_RF_CHANNEL-1][0:RF_CTRL_REGS-1][31:0] i_rf_ctrl_regs,
     output logic [0:NUM_RF_CHANNEL-1][0:RF_STATUS_REGS-1][31:0] o_rf_status_regs,

     // rf IQ stream to RFDC IP
     output logic [0:NUM_RF_CHANNEL-1][RF_DAC_WIDTH*16-1:0] o_rf_QIx8_bus,

     // rf armed bus for LED
     output logic [NUM_RF_CHANNEL-1:0] o_rf_armed_bus,

     // rf empty bus for simulation
     output logic [0:NUM_RF_CHANNEL-1] o_rf_empty_bus,

     // rf eop bus
     output rf_eop_t [0:NUM_RF_CHANNEL-1] o_rf_eop_bus,

     // li mmio registers
     input  logic [0:NUM_LI_CHANNEL-1][0:LI_SEQ_REGS-1][31:0] i_li_seq_regs,
     input  logic [0:NUM_LI_CHANNEL-1][0:LI_CTRL_REGS-1][31:0] i_li_ctrl_regs,
     output logic [0:NUM_LI_CHANNEL-1][0:LI_STATUS_REGS-1][31:0] o_li_status_regs,

     // li IQ stream from RFDC IP
     input  logic [0:NUM_LI_CHANNEL-1][LI_ADC_WIDTH*8-1:0] i_li_QIx4_bus,

     // li armed bus for LED
     output logic [NUM_LI_CHANNEL-1:0] o_li_armed_bus,

     // li empty bus for simulation
     output logic [0:NUM_LI_CHANNEL-1] o_li_empty_bus,

     // li sample mask
     output logic [0:NUM_LI_CHANNEL-1][3:0] o_li_sample_mask_bus,

     // li output
     output logic [0:NUM_LI_CHANNEL-1][LI_ADC_WIDTH*8-1:0] o_li_QIx4_bus,
     output logic [0:NUM_LI_CHANNEL-1][3:0] o_li_validx4_bus,
     output logic [0:NUM_LI_CHANNEL-1] o_li_last_bus,

     // li ctrl bus
     output li_ctrl_t [0:NUM_LI_CHANNEL-1] o_li_ctrl_bus,

     // li eop bus
     output li_eop_t [0:NUM_LI_CHANNEL-1] o_li_eop_bus,

     // li samples lost bus
     input  logic [0:NUM_LI_CHANNEL-1][31:0] i_li_samples_lost_bus,

     // li samples inbuf bus
     input  logic [0:NUM_LI_CHANNEL-1][LI_AXIBUF_ADDR_WIDTH-1:0] i_li_samples_inbuf_bus,

     // ex mmio registers
     input  logic [0:NUM_EX_CHANNEL-1][0:EX_SEQ_REGS-1][31:0] i_ex_seq_regs,
     output logic [0:NUM_EX_CHANNEL-1][0:EX_STATUS_REGS-1][31:0] o_ex_status_regs,

     // ex real stream to RFDC IP
     output logic [0:NUM_EX_CHANNEL-1][EX_DAC_WIDTH*16-1:0] o_ex_realx16_bus,

     // ex armed bus for LED
     output logic [NUM_EX_CHANNEL-1:0] o_ex_armed_bus,

     // ex empty bus for simulation
     output logic [0:NUM_EX_CHANNEL-1] o_ex_empty_bus,

     // ex eop bus
     output ex_eop_t [0:NUM_EX_CHANNEL-1] o_ex_eop_bus,

     // launch mmio registers
     input  logic [0:LCH_CTRL_REGS-1][31:0] i_lch_ctrl_regs,
     output logic [0:LCH_STATUS_REGS-1][31:0] o_lch_status_regs,

     // user button press
     input  logic i_btn);
     
    /****************
    * dc connections
    ****************/

    logic [NUM_DC_CHANNEL-1:0] w_dc_start_bus;
    logic [NUM_DC_CHANNEL-1:0] w_dc_armed_bus;

    for (genvar i = 0; i < NUM_DC_CHANNEL; i++) begin : DC_GEN

        dc DC (
            .i_clk(i_clk),
            .i_rst(i_rst),

            .i_seq_regs(i_dc_seq_regs[i]),
            .i_ctrl_regs(i_dc_ctrl_regs[i]),
            .o_status_regs(o_dc_status_regs[i]),

            .o_sclk(o_dc_sclk_bus[i]),
            .o_mosi(o_dc_mosi_bus[i]),
            .i_miso(i_dc_miso_bus[i]),
            .o_cs_n(o_dc_cs_n_bus[i]),
            .o_ldac_n(o_dc_ldac_n_bus[i]),

            .i_start(w_dc_start_bus[i]),
            .o_armed(w_dc_armed_bus[i]),

            .o_empty(o_dc_empty_bus[i]),

            .o_eop(o_dc_eop_bus[i])
        );

    end

    /****************
    * rf connections
    ****************/

    logic [NUM_RF_CHANNEL-1:0] w_rf_armed_bus;
    logic [NUM_RF_CHANNEL-1:0] w_rf_start_bus;
    
    for (genvar i = 0; i < NUM_RF_CHANNEL; i++) begin : RF_GEN

        rf RF (
            .i_clk(i_clk),
            .i_rst(i_rst),

            .i_seq_regs(i_rf_seq_regs[i]),
            .i_ctrl_regs(i_rf_ctrl_regs[i]),
            .o_status_regs(o_rf_status_regs[i]),

            .o_QIx8(o_rf_QIx8_bus[i]),

            .i_start(w_rf_start_bus[i]),
            .o_armed(w_rf_armed_bus[i]),

            .o_empty(o_rf_empty_bus[i]),

            .o_eop(o_rf_eop_bus[i])
        );

    end

    /****************
    * li connections
    ****************/

    logic [NUM_LI_CHANNEL-1:0] w_li_armed_bus;
    logic [NUM_LI_CHANNEL-1:0] w_li_start_bus;

    for (genvar i = 0; i < NUM_LI_CHANNEL; i++) begin : LI_GEN

        li LI (
            .i_clk(i_clk),
            .i_rst(i_rst),

            .i_seq_regs(i_li_seq_regs[i]),
            .i_ctrl_regs(i_li_ctrl_regs[i]),
            .o_status_regs(o_li_status_regs[i]),

            .i_QIx4(i_li_QIx4_bus[i]),

            .o_sample_mask(o_li_sample_mask_bus[i]),

            .o_QIx4(o_li_QIx4_bus[i]),
            .o_validx4(o_li_validx4_bus[i]),
            .o_last(o_li_last_bus[i]),

            .i_start(w_li_start_bus[i]),
            .o_armed(w_li_armed_bus[i]),

            .o_empty(o_li_empty_bus[i]),

            .o_ctrl(o_li_ctrl_bus[i]),

            .o_eop(o_li_eop_bus[i]),

            .i_samples_lost(i_li_samples_lost_bus[i]),
            .i_samples_inbuf(i_li_samples_inbuf_bus[i])
        );

    end

    /****************
    * ex connections
    ****************/

    logic [NUM_EX_CHANNEL-1:0] w_ex_armed_bus;
    logic [NUM_EX_CHANNEL-1:0] w_ex_start_bus;
    
    for (genvar i = 0; i < NUM_EX_CHANNEL; i++) begin : EX_GEN

        ex EX (
            .i_clk(i_clk),
            .i_rst(i_rst),

            .i_seq_regs(i_ex_seq_regs[i]),
            .o_status_regs(o_ex_status_regs[i]),

            .o_realx16(o_ex_realx16_bus[i]),

            .i_start(w_ex_start_bus[i]),
            .o_armed(w_ex_armed_bus[i]),

            .o_empty(o_ex_empty_bus[i]),

            .o_eop(o_ex_eop_bus[i])
        );

    end

    /********************
    * launch connections
    ********************/

    logic w_trigger;

    launch #(
        .NUM_DC_CHANNEL(NUM_DC_CHANNEL),
        .NUM_RF_CHANNEL(NUM_RF_CHANNEL),
        .NUM_LI_CHANNEL(NUM_LI_CHANNEL),
        .NUM_EX_CHANNEL(NUM_EX_CHANNEL)
    ) LCH (
        .i_clk(i_clk),
        .i_rst(i_rst),

        .i_ctrl_regs(i_lch_ctrl_regs),
        .o_status_regs(o_lch_status_regs),

        .i_dc_armed(w_dc_armed_bus),
        .i_rf_armed(w_rf_armed_bus),
        .i_li_armed(w_li_armed_bus),
        .i_ex_armed(w_ex_armed_bus),

        .i_trigger(w_trigger),

        .o_dc_start(w_dc_start_bus),
        .o_rf_start(w_rf_start_bus),
        .o_li_start(w_li_start_bus),
        .o_ex_start(w_ex_start_bus)
    );

    assign o_dc_armed_bus = w_dc_armed_bus;
    assign o_rf_armed_bus = w_rf_armed_bus;
    assign o_li_armed_bus = w_li_armed_bus;
    assign o_ex_armed_bus = w_ex_armed_bus;

    /********************
    * button for trigger
    ********************/

    button_detector #(
        .NUM_CYCLES(NUM_DEBOUNCE_CYCLES),
        .NUM_BUTTONS(1)
    ) BTN (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_btn(i_btn),
        .o_pressed(w_trigger)
    );

endmodule
