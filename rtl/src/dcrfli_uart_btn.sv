// `default_nettype none
`timescale 1ns / 1ps
`include "dc.svh"
`include "rf.svh"
`include "li.svh"
`include "launch.vh"

module dcrfli_uart_btn
   #(parameter NUM_DC_CHANNEL=24,
     parameter NUM_RF_CHANNEL=6,
     parameter NUM_LI_CHANNEL=1,
     parameter NUM_DEBOUNCE_CYCLES=25)
    (input  logic i_clk, i_rst,

     // dc mmio registers
     input  logic [0:NUM_DC_CHANNEL-1][0:DC_SEQ_REGS-1][31:0] i_dc_seq_regs,
     input  logic [0:NUM_DC_CHANNEL-1][0:DC_CTRL_REGS-1][31:0] i_dc_ctrl_regs,

     // dc uart registers
     input  logic [0:DC_SEQ_REGS-1][31:0] i_dc_seq_uregs,
     input  logic [0:DC_CTRL_REGS-1][31:0] i_dc_ctrl_uregs,

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

     // rf uart registers
     input  logic [0:RF_SEQ_REGS-1][31:0] i_rf_seq_uregs,
     input  logic [0:RF_CTRL_REGS-1][31:0] i_rf_ctrl_uregs,

     // rf IQ stream to RFDC IP
     output logic [0:NUM_RF_CHANNEL-1][RF_DAC_WIDTH*16-1:0] o_rf_QIx8_bus,

     // rf armed bus for LED
     output logic [NUM_RF_CHANNEL-1:0] o_rf_armed_bus,

     // rf empty bus for simulation
     output logic [0:NUM_RF_CHANNEL-1] o_rf_empty_bus,

     // rf nco freq/phase update buses
     output logic [0:(NUM_RF_CHANNEL+1)/2-1] o_rf_nco_req_bus,
     input  logic [0:(NUM_RF_CHANNEL+1)/2-1] i_rf_nco_busy_bus,
     output logic [0:NUM_RF_CHANNEL-1][RF_NCO_FREQ_WIDTH-1:0] o_rf_nco_freq_bus,
     output logic [0:NUM_RF_CHANNEL-1][RF_NCO_PHASE_WIDTH-1:0] o_rf_nco_phase_bus,
     output logic [0:NUM_RF_CHANNEL-1][RF_NCO_EN_WIDTH-1:0] o_rf_nco_en_bus,

     // rf eop bus
     output rf_eop_t [0:NUM_RF_CHANNEL-1] o_rf_eop_bus,

     // li mmio registers
     input  logic [0:NUM_LI_CHANNEL-1][0:LI_SEQ_REGS-1][31:0] i_li_seq_regs,
     input  logic [0:NUM_LI_CHANNEL-1][0:LI_CTRL_REGS-1][31:0] i_li_ctrl_regs,

     // li uart registers
     input  logic [0:LI_SEQ_REGS-1][31:0] i_li_seq_uregs,
     input  logic [0:LI_CTRL_REGS-1][31:0] i_li_ctrl_uregs,

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

     // launch mmio registers
     input  logic [0:LCH_TOTAL_REGS-1][31:0] i_lch_regs,

     // launch uart registers
     input  logic [0:LCH_TOTAL_REGS-1][31:0] i_lch_uregs,

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

            .i_seq_uregs({i_dc_seq_uregs[0:DC_SEQ_REGS-2], 31'h0,
                          i_dc_seq_uregs[DC_SEQ_REGS-1][i]}),
            .i_ctrl_uregs({i_dc_ctrl_uregs[0:DC_CTRL_REGS-2], 31'h0,
                           i_dc_ctrl_uregs[DC_CTRL_REGS-1][i]}),

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

    logic [0:NUM_RF_CHANNEL-1] w_rf_nco_chreq_bus;
    logic [0:NUM_RF_CHANNEL-1] w_rf_nco_iwait_bus;
    logic [0:NUM_RF_CHANNEL-1] w_rf_nco_owait_bus;

    for (genvar i = 0; i < NUM_RF_CHANNEL; i++) begin : RF_GEN

        rf RF (
            .i_clk(i_clk),
            .i_rst(i_rst),

            .i_seq_regs(i_rf_seq_regs[i]),
            .i_ctrl_regs(i_rf_ctrl_regs[i]),

            .i_seq_uregs({i_rf_seq_uregs[0:RF_SEQ_REGS-2], 31'h0,
                          i_rf_seq_uregs[RF_SEQ_REGS-1][i]}),
            .i_ctrl_uregs({i_rf_ctrl_uregs[0:RF_CTRL_REGS-2], 31'h0,
                           i_rf_ctrl_uregs[RF_CTRL_REGS-1][i]}),

            .o_QIx8(o_rf_QIx8_bus[i]),

            .i_start(w_rf_start_bus[i]),
            .o_armed(w_rf_armed_bus[i]),

            .o_empty(o_rf_empty_bus[i]),

            .i_nco_wait(w_rf_nco_iwait_bus[i]),
            .o_nco_wait(w_rf_nco_owait_bus[i]),

            .o_nco_req(w_rf_nco_chreq_bus[i]),
            .i_nco_busy(i_rf_nco_busy_bus[i / 2]),
            .o_nco_freq(o_rf_nco_freq_bus[i]),
            .o_nco_phase(o_rf_nco_phase_bus[i]),
            .o_nco_en(o_rf_nco_en_bus[i]),

            .o_eop(o_rf_eop_bus[i])
        );

    end

    for (genvar i = 0; i < NUM_RF_CHANNEL; i++) begin : RF_NCO_IWAIT_REQ_GEN

        if (i % 2 == 0) begin : EVEN
            if (i + 1 < NUM_RF_CHANNEL) begin : PAIR
                assign o_rf_nco_req_bus[i / 2] = w_rf_nco_chreq_bus[i] | 
                                                 w_rf_nco_chreq_bus[i + 1];
                assign w_rf_nco_iwait_bus[i] = w_rf_nco_owait_bus[i + 1];
            end
            else begin : SINGLE
                assign o_rf_nco_req_bus[i / 2] = w_rf_nco_chreq_bus[i];
                assign w_rf_nco_iwait_bus[i] = 1'b0;
            end
        end
        else begin : ODD
            assign w_rf_nco_iwait_bus[i] = w_rf_nco_owait_bus[i - 1];
        end

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

            .i_seq_uregs({i_li_seq_uregs[0:LI_SEQ_REGS-2], 31'h0,
                          i_li_seq_uregs[LI_SEQ_REGS-1][i]}),
            .i_ctrl_uregs({i_li_ctrl_uregs[0:LI_CTRL_REGS-2], 31'h0,
                           i_li_ctrl_uregs[LI_CTRL_REGS-1][i]}),

            .i_QIx4(i_li_QIx4_bus[i]),

            .o_sample_mask(o_li_sample_mask_bus[i]),

            .o_QIx4(o_li_QIx4_bus[i]),
            .o_validx4(o_li_validx4_bus[i]),
            .o_last(o_li_last_bus[i]),

            .i_start(w_li_start_bus[i]),
            .o_armed(w_li_armed_bus[i]),

            .o_empty(o_li_empty_bus[i]),

            .o_ctrl(o_li_ctrl_bus[i]),

            .o_eop(o_li_eop_bus[i])
        );

    end

    /********************
    * launch connections
    ********************/

    logic w_trigger;

    launch #(
        .NUM_DC_CHANNEL(NUM_DC_CHANNEL),
        .NUM_RF_CHANNEL(NUM_RF_CHANNEL),
        .NUM_LI_CHANNEL(NUM_LI_CHANNEL)
    ) LCH (
        .i_clk(i_clk),
        .i_rst(i_rst),

        .i_regs(i_lch_regs),
        .i_uregs(i_lch_uregs),

        .i_dc_armed(w_dc_armed_bus),
        .i_rf_armed(w_rf_armed_bus),
        .i_li_armed(w_li_armed_bus),

        .i_trigger(w_trigger),

        .o_dc_start(w_dc_start_bus),
        .o_rf_start(w_rf_start_bus),
        .o_li_start(w_li_start_bus)
    );

    assign o_dc_armed_bus = w_dc_armed_bus;
    assign o_rf_armed_bus = w_rf_armed_bus;
    assign o_li_armed_bus = w_li_armed_bus;

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
