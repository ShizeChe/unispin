// `default_nettype none
`timescale 1ns / 1ps
`include "dc.svh"
`include "rf.svh"
`include "launch.vh"

module dcrfli
   #(parameter NUM_DC_CHANNEL=24,
     parameter NUM_RF_CHANNEL=6,
     parameter NUM_LI_CHANNEL=1,
     parameter NUM_DEBOUNCE_CYCLES=25)
    (input  logic i_clk, i_rst,

     // dc mmio registers
     input  logic [0:NUM_DC_CHANNEL-1][0:DC_SEQ_REGS-1][31:0] i_dc_seq_regs,
     input  logic [0:NUM_DC_CHANNEL-1][0:DC_CTRL_REGS-1][31:0] i_dc_ctrl_regs,

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

     // rf IQ stream to RFDC IP
     output logic [0:NUM_RF_CHANNEL-1][RF_DAC_WIDTH*16-1:0] o_rf_QIx8_bus,

     // rf armed buses for LED
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

     // launch mmio registers
     input  logic [0:LCH_TOTAL_REGS-1][31:0] i_lch_regs);
     
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

        .i_dc_armed(w_dc_armed_bus),
        .i_rf_armed(w_rf_armed_bus),
        .i_li_armed(NUM_LI_CHANNEL'('h0)),

        .i_trigger(1'b1),

        .o_dc_start(w_dc_start_bus),
        .o_rf_start(w_rf_start_bus),
        .o_li_start()
    );

    assign o_dc_armed_bus = w_dc_armed_bus;
    assign o_rf_armed_bus = w_rf_armed_bus;

endmodule
