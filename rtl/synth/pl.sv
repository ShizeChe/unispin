// `default_nettype none
`timescale 1ns / 1ps
`include "dc.svh"
`include "rf.svh"
`include "launch.vh"

module pl
    (input  logic i_adc1_clk_n, i_adc1_clk_p,
     input  logic i_dac1_clk_n, i_dac1_clk_p,

     input  logic i_sysref_n, i_sysref_p,

     input  logic i_vin10_n, i_vin10_p,
     input  logic i_vin11_n, i_vin11_p,

     output logic o_vout00_n, o_vout00_p,
     output logic o_vout01_n, o_vout01_p,
     output logic o_vout02_n, o_vout02_p,
     output logic o_vout03_n, o_vout03_p,

     output logic o_vout10_n, o_vout10_p,
     output logic o_vout11_n, o_vout11_p,
     output logic o_vout12_n, o_vout12_p,
     output logic o_vout13_n, o_vout13_p,

     output logic o_vout20_n, o_vout20_p,
     output logic o_vout21_n, o_vout21_p,
     output logic o_vout22_n, o_vout22_p,
     output logic o_vout23_n, o_vout23_p,

     // J2
     output logic o_la01_p, o_la06_p, o_la01_n,
                  o_la03_p, o_la06_n, o_la05_p,
                  o_la09_n, o_la09_p, o_la05_n, 
                  o_la10_n, o_la10_p, o_la14_p, 
                  o_la17_p, o_la33_p, o_la29_n, 
                  o_la29_p, o_la25_p, o_la27_n, 
                  o_la27_p, o_la26_p, o_la23_n, 
                  o_la23_p, o_la18_n, o_la18_p,

     input  logic i_la00_p, i_la13_p, i_la13_n, 
                  i_la33_n, i_la25_n, i_la26_n,
    
     // J3
     output logic o_la31_p, o_la28_n, o_la28_p,
                  o_la24_n, o_la21_n, o_la21_p,
                  o_la22_n, o_la22_p, o_la19_p,
                  o_la20_n, o_la20_p, o_la15_n,
                  o_la00_n, o_la02_p, o_la02_n, 
                  o_la03_n, o_la04_n, o_la08_p, 
                  o_la08_n, o_la07_p, o_la12_p, 
                  o_la12_n, o_la11_p, o_la11_n, 
                  o_la16_n,

     input  logic i_la31_n, i_la24_p, i_la19_n,
                  i_la15_p, i_la04_p, i_la07_n,
                  i_la16_p,

     // J4
     output logic o_clk0_m2c_n, o_clk1_m2c_n,
     input  logic i_clk0_m2c_p, i_clk1_m2c_p,

     // J6
    output  logic o_sync_c2m_p, o_sync_c2m_n, o_sync_m2c_p, 
                  o_sync_m2c_n, o_la30_p, o_la30_n,
                  o_la32_n, o_la14_n,
     input  logic i_la32_p, i_la17_n,

     output logic o_dacio00, o_dacio01, o_dacio02, 
                  o_dacio03, o_dacio04, o_dacio06, 
                  o_dacio07, o_dacio09, o_dacio10, 
                  o_dacio11, o_dacio13, o_dacio14, 
                  o_dacio15,
     input  logic i_dacio05, i_dacio08, i_dacio12,

     output logic o_adcio00, o_adcio01, o_adcio02, 
                  o_adcio04, o_adcio05, o_adcio06, 
                  o_adcio07, o_adcio08, o_adcio09, 
                  o_adcio11, o_adcio12, o_adcio13, 
                  o_adcio14, o_adcio15,
     input  logic i_adcio03, i_adcio10,

     // PMOD0
     output logic o_pmod00, o_pmod01, o_pmod02, 
                  o_pmod03, o_pmod04, o_pmod05, 
                  o_pmod06,
     input  logic i_pmod07,

     // PMOD1
     output logic o_pmod11, o_pmod12, o_pmod13, 
                  o_pmod14, o_pmod15, o_pmod16, 
                  o_pmod17,
     input  logic i_pmod10,

     output logic o_rled0, o_rled1, o_rled2, o_rled3,
     output logic o_rled4, o_rled5, o_rled6, o_rled7,
    
     output logic o_gled0, o_gled1, o_gled2, o_gled3,
     output logic o_gled4, o_gled5, o_gled6, o_gled7,
    
     output logic o_bled0, o_bled1, o_bled2, o_bled3,
     output logic o_bled4, o_bled5, o_bled6, o_bled7,
    
     input  logic i_btn_w);

    localparam NUM_DC_CHANNEL=24;
    localparam NUM_RF_CHANNEL=6;
    localparam NUM_LI_CHANNEL=1;
    localparam NUM_DEBOUNCE_CYCLES=25000000;

    logic w_dcrfli_clk, w_dcrfli_rst_n;

    logic [0:NUM_DC_CHANNEL-1][0:DC_TOTAL_REGS-1][31:0] w_dc_regs;

    logic [0:NUM_DC_CHANNEL-1] w_dc_sclk_bus;
    logic [0:NUM_DC_CHANNEL-1] w_dc_mosi_bus;
    logic [0:NUM_DC_CHANNEL-1] w_dc_miso_bus;
    logic [0:NUM_DC_CHANNEL-1] w_dc_cs_n_bus;
    logic [0:NUM_DC_CHANNEL-1] w_dc_ldac_n_bus;
    logic w_dc_clr, w_dc_rst;

    logic [NUM_DC_CHANNEL-1:0] w_dc_armed_bus;

    logic [0:NUM_RF_CHANNEL-1][0:RF_TOTAL_REGS-1][31:0] w_rf_regs;

    logic [0:NUM_RF_CHANNEL-1][RF_DAC_WIDTH*16-1:0] w_rf_QIx8_bus;

    logic [NUM_RF_CHANNEL-1:0] w_rf_armed_bus;

    logic [0:NUM_RF_CHANNEL-1] w_rf_ready_bus;

    logic [0:LCH_TOTAL_REGS-1][31:0] w_lch_regs;

    logic [0:1] w_li_valid_bus;

    bd_wrapper BD (

        // clock
        .adc1_clk_0_clk_n(i_adc1_clk_n),
        .adc1_clk_0_clk_p(i_adc1_clk_p),
        .clk_adc1_0(),
        .clk_dac0_0(),
        .clk_dac1_0(w_dcrfli_clk),
        .clk_dac2_0(),
        .dac1_clk_0_clk_n(i_dac1_clk_n),
        .dac1_clk_0_clk_p(i_dac1_clk_p),
        .dcrfli_clk(w_dcrfli_clk),

        // reset
        .dcrfli_rst_n(w_dcrfli_rst_n),

        // dc x 24
        .o_regs_0(w_dc_regs[0]),
        .o_regs_1(w_dc_regs[1]),
        .o_regs_2(w_dc_regs[2]),
        .o_regs_3(w_dc_regs[3]),
        .o_regs_4(w_dc_regs[4]),
        .o_regs_5(w_dc_regs[5]),
        .o_regs_6(w_dc_regs[6]),
        .o_regs_7(w_dc_regs[7]),
        .o_regs_8(w_dc_regs[8]),
        .o_regs_9(w_dc_regs[9]),
        .o_regs_10(w_dc_regs[10]),
        .o_regs_11(w_dc_regs[11]),
        .o_regs_12(w_dc_regs[12]),
        .o_regs_13(w_dc_regs[13]),
        .o_regs_14(w_dc_regs[14]),
        .o_regs_15(w_dc_regs[15]),
        .o_regs_16(w_dc_regs[16]),
        .o_regs_17(w_dc_regs[17]),
        .o_regs_18(w_dc_regs[18]),
        .o_regs_19(w_dc_regs[19]),
        .o_regs_20(w_dc_regs[20]),
        .o_regs_21(w_dc_regs[21]),
        .o_regs_22(w_dc_regs[22]),
        .o_regs_23(w_dc_regs[23]),

        // rf x 6
        .o_regs_24(w_rf_regs[0]),
        .o_regs_25(w_rf_regs[1]),
        .o_regs_26(w_rf_regs[2]),
        .o_regs_27(w_rf_regs[3]),
        .o_regs_28(w_rf_regs[4]),
        .o_regs_29(w_rf_regs[5]),

        // rf dac tile 228-0/1
        .s00_axis_0_tdata(w_rf_QIx8_bus[0]),
        .s00_axis_0_tready(w_rf_ready_bus[0]),
        .s00_axis_0_tvalid(1'b1),
        .vout00_0_v_n(o_vout00_n),
        .vout00_0_v_p(o_vout00_p),
        .vout01_0_v_n(o_vout01_n),
        .vout01_0_v_p(o_vout01_p),

        // rf dac tile 228-2/3
        .s02_axis_0_tdata(w_rf_QIx8_bus[1]),
        .s02_axis_0_tready(w_rf_ready_bus[1]),
        .s02_axis_0_tvalid(1'b1),
        .vout02_0_v_n(o_vout02_n),
        .vout02_0_v_p(o_vout02_p),
        .vout03_0_v_n(o_vout03_n),
        .vout03_0_v_p(o_vout03_p),

        // rf dac tile 229-0/1
        .s10_axis_0_tdata(w_rf_QIx8_bus[2]),
        .s10_axis_0_tready(w_rf_ready_bus[2]),
        .s10_axis_0_tvalid(1'b1),
        .vout10_0_v_n(o_vout10_n),
        .vout10_0_v_p(o_vout10_p),
        .vout11_0_v_n(o_vout11_n),
        .vout11_0_v_p(o_vout11_p),

        // rf dac tile 229-2/3
        .s12_axis_0_tdata(w_rf_QIx8_bus[3]),
        .s12_axis_0_tready(w_rf_ready_bus[3]),
        .s12_axis_0_tvalid(1'b1),
        .vout12_0_v_n(o_vout12_n),
        .vout12_0_v_p(o_vout12_p),
        .vout13_0_v_n(o_vout13_n),
        .vout13_0_v_p(o_vout13_p),

        // rf dac tile 230-0/1
        .s20_axis_0_tdata(w_rf_QIx8_bus[4]),
        .s20_axis_0_tready(w_rf_ready_bus[4]),
        .s20_axis_0_tvalid(1'b1),
        .vout20_0_v_n(o_vout20_n),
        .vout20_0_v_p(o_vout20_p),
        .vout21_0_v_n(o_vout21_n),
        .vout21_0_v_p(o_vout21_p),

        // rf dac tile 230-2/3
        .s22_axis_0_tdata(w_rf_QIx8_bus[5]),
        .s22_axis_0_tready(w_rf_ready_bus[5]),
        .s22_axis_0_tvalid(1'b1),
        .vout22_0_v_n(o_vout22_n),
        .vout22_0_v_p(o_vout22_p),
        .vout23_0_v_n(o_vout23_n),
        .vout23_0_v_p(o_vout23_p),

        // rf adc tile 225-0/1
        .m10_axis_tvalid_0(w_li_valid_bus[0]),
        .vin10_0_v_n(i_vin10_n),
        .vin10_0_v_p(i_vin10_p),
        .m11_axis_tvalid_0(w_li_valid_bus[1]),
        .vin11_0_v_n(i_vin11_n),
        .vin11_0_v_p(i_vin11_p),

        .sysref_in_0_diff_n(i_sysref_n),
        .sysref_in_0_diff_p(i_sysref_p),

        // launch x 1
        .o_regs_30(w_lch_regs)

    );

    dcrfli_btn #(
        .NUM_DC_CHANNEL(NUM_DC_CHANNEL),
        .NUM_RF_CHANNEL(NUM_RF_CHANNEL),
        .NUM_LI_CHANNEL(NUM_LI_CHANNEL),
        .NUM_DEBOUNCE_CYCLES(NUM_DEBOUNCE_CYCLES)
    ) DCRFLI (
        .i_clk(w_dcrfli_clk),
        .i_rst(!w_dcrfli_rst_n),

        // dc
        .i_dc_regs(w_dc_regs),

        .o_dc_sclk_bus(w_dc_sclk_bus),
        .o_dc_mosi_bus(w_dc_mosi_bus),
        .i_dc_miso_bus(w_dc_miso_bus),
        .o_dc_cs_n_bus(w_dc_cs_n_bus),
        .o_dc_ldac_n_bus(w_dc_ldac_n_bus),

        .o_dc_armed_bus(w_dc_armed_bus),

        // rf
        .i_rf_regs(w_rf_regs),
        .o_rf_QIx8_bus(w_rf_QIx8_bus),

        .o_rf_armed_bus(w_rf_armed_bus),

        // launch
        .i_lch_regs(w_lch_regs),
        
        .i_btn(i_btn_w)
    );
    
    assign w_dc_clr = 1'b0;
    assign w_dc_rst = 1'b0;

    io #(
        .NUM_DC_CHANNEL(NUM_DC_CHANNEL),
        .NUM_RF_CHANNEL(NUM_RF_CHANNEL),
        .NUM_LI_CHANNEL(NUM_LI_CHANNEL)
    ) IO (
        // dc
        .i_dc_sclk_bus(w_dc_sclk_bus),
        .i_dc_mosi_bus(w_dc_mosi_bus),
        .o_dc_miso_bus(w_dc_miso_bus),
        .i_dc_cs_n_bus(w_dc_cs_n_bus),
        .i_dc_ldac_n_bus(w_dc_ldac_n_bus),
        .i_dc_clr(w_dc_clr),
        .i_dc_rst(w_dc_rst),
        .i_dc_armed_bus(w_dc_armed_bus),

        // rf
        .i_rf_armed_bus(w_rf_armed_bus),
        .i_rf_ready_bus(w_rf_ready_bus),

        // li
        .i_li_valid_bus(w_li_valid_bus),

        // fpga pins
        .*
    );

endmodule
