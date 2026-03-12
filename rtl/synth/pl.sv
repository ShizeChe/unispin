// `default_nettype none
`timescale 1ns / 1ps
`include "dc.svh"
`include "rf.svh"
`include "li.svh"
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
    
     input  logic i_btn_w,
     
     input  logic i_rx,
     output logic o_tx);
     
    localparam NUM_DC_CHANNEL=24;
    localparam NUM_RF_CHANNEL=6;
    localparam NUM_LI_CHANNEL=2;
    localparam NUM_DEBOUNCE_CYCLES=25000000;

    localparam NUM_DAC_TILE=4;
    localparam NUM_ADC_TILE=1;
    localparam NCO_PER_DAC_TILE=2;
    localparam NCO_PER_ADC_TILE=2;

    logic w_dcrfli_clk, w_dcrfli_rst_n;
    logic w_pl_clk, w_pl_rst_n;

    // uart regs
    localparam TOTAL_UREGS=DC_SEQ_REGS+DC_CTRL_REGS+
                           RF_SEQ_REGS+RF_CTRL_REGS+
                           LI_SEQ_REGS+LI_CTRL_REGS+
                           LCH_TOTAL_REGS;

    localparam U_DC_SEQ_START = 0;
    localparam U_DC_SEQ_END = U_DC_SEQ_START + DC_SEQ_REGS - 1;

    localparam U_DC_CTRL_START = U_DC_SEQ_END + 1;
    localparam U_DC_CTRL_END = U_DC_CTRL_START + DC_CTRL_REGS - 1;

    localparam U_RF_SEQ_START = U_DC_CTRL_END + 1;
    localparam U_RF_SEQ_END = U_RF_SEQ_START + RF_SEQ_REGS - 1;

    localparam U_RF_CTRL_START = U_RF_SEQ_END + 1;
    localparam U_RF_CTRL_END = U_RF_CTRL_START + RF_CTRL_REGS - 1;

    localparam U_LI_SEQ_START = U_RF_CTRL_END + 1;
    localparam U_LI_SEQ_END = U_LI_SEQ_START + LI_SEQ_REGS - 1;

    localparam U_LI_CTRL_START = U_LI_SEQ_END + 1;
    localparam U_LI_CTRL_END = U_LI_CTRL_START + LI_CTRL_REGS - 1;

    localparam U_LCH_START = U_LI_CTRL_END + 1;
    localparam U_LCH_END = U_LCH_START + LCH_TOTAL_REGS - 1;

    logic [0:TOTAL_UREGS-1][31:0] w_uregs;
    
    uart_regs #(
        .DATA_WIDTH(8),
        .RX_FIFO_DEPTH(8),
        .RX_FIFO_AF_DEPTH(6),
        .RX_FIFO_AE_DEPTH(2),
        .TX_FIFO_DEPTH(8),
        .TX_FIFO_AF_DEPTH(6),
        .TX_FIFO_AE_DEPTH(2),
        .NUM_REGS(TOTAL_UREGS)
    ) REGS (
        .i_clk(w_dcrfli_clk),
        .i_rst(!w_dcrfli_rst_n),
        .i_rx(i_rx),
        .o_tx(o_tx),
        .i_dvsr(11'd16),
        .o_regs(w_uregs)
    );

    // dc signals
    logic [0:NUM_DC_CHANNEL-1][0:DC_SEQ_REGS-1][31:0] w_dc_seq_regs;
    logic [0:NUM_DC_CHANNEL-1][0:DC_CTRL_REGS-1][31:0] w_dc_ctrl_regs;

    logic [0:NUM_DC_CHANNEL-1] w_dc_sclk_bus;
    logic [0:NUM_DC_CHANNEL-1] w_dc_mosi_bus;
    logic [0:NUM_DC_CHANNEL-1] w_dc_miso_bus;
    logic [0:NUM_DC_CHANNEL-1] w_dc_cs_n_bus;
    logic [0:NUM_DC_CHANNEL-1] w_dc_ldac_n_bus;
    logic w_dc_clr, w_dc_rst;

    logic [NUM_DC_CHANNEL-1:0] w_dc_armed_bus;

    // rf signals
    logic [0:NUM_RF_CHANNEL-1][0:RF_SEQ_REGS-1][31:0] w_rf_seq_regs;
    logic [0:NUM_RF_CHANNEL-1][0:RF_CTRL_REGS-1][31:0] w_rf_ctrl_regs;

    logic [0:NUM_RF_CHANNEL-1][RF_DAC_WIDTH*16-1:0] w_rf_QIx8_bus;

    logic [NUM_RF_CHANNEL-1:0] w_rf_armed_bus;

    logic [0:NUM_RF_CHANNEL-1] w_rf_ready_bus;

    // li signals
    logic [0:NUM_LI_CHANNEL-1][0:LI_SEQ_REGS-1][31:0] w_li_seq_regs;
    logic [0:NUM_LI_CHANNEL-1][0:LI_CTRL_REGS-1][31:0] w_li_ctrl_regs;

    logic [0:NUM_LI_CHANNEL-1] w_li_valid_bus;
    logic [0:NUM_LI_CHANNEL-1][LI_ADC_WIDTH*8-1:0] w_li_QIx4_bus;
    logic [0:NUM_LI_CHANNEL-1][LI_ADC_WIDTH*16-1:0] w_li_QIx8_bus;

    logic [0:NUM_LI_CHANNEL-1][3:0] w_li_validx4_bus;
    logic [0:NUM_LI_CHANNEL-1][LI_ADC_WIDTH*8-1:0] w_li_QIx4_save_bus;
    logic [0:NUM_LI_CHANNEL-1] w_li_last_bus;

    logic [NUM_LI_CHANNEL-1:0] w_li_armed_bus;

    li_ctrl_t [0:NUM_LI_CHANNEL-1] w_li_ctrl_bus;

    // launch signals
    logic [0:LCH_TOTAL_REGS-1][31:0] w_lch_regs;

    // nco update signals
    logic [0:NUM_DAC_TILE-1][0:NCO_PER_DAC_TILE*3][31:0] w_dac_nco_regs;

    logic [0:NUM_DAC_TILE-1][0:NCO_PER_DAC_TILE-1][47:0] w_dac_nco_freq;
    logic [0:NUM_DAC_TILE-1][0:NCO_PER_DAC_TILE-1][17:0] w_dac_nco_phase;
    logic [0:NUM_DAC_TILE-1][0:NCO_PER_DAC_TILE-1] w_dac_nco_phase_rst;
    logic [0:NUM_DAC_TILE-1][0:NCO_PER_DAC_TILE-1][5:0] w_dac_nco_en;
    logic [0:NUM_DAC_TILE-1] w_dac_nco_req;
    logic [0:NUM_DAC_TILE-1] w_dac_nco_busy;

    // nco update registers adc tile 225
    logic [0:NUM_ADC_TILE-1][0:NCO_PER_ADC_TILE*3][31:0] w_adc_nco_regs;

    logic [0:NUM_ADC_TILE-1][0:NCO_PER_ADC_TILE-1][47:0] w_adc_nco_freq;
    logic [0:NUM_ADC_TILE-1][0:NCO_PER_ADC_TILE-1][17:0] w_adc_nco_phase;
    logic [0:NUM_ADC_TILE-1][0:NCO_PER_ADC_TILE-1] w_adc_nco_phase_rst;
    logic [0:NUM_ADC_TILE-1][0:NCO_PER_ADC_TILE-1][5:0] w_adc_nco_en;
    logic [0:NUM_ADC_TILE-1] w_adc_nco_req;
    logic [0:NUM_ADC_TILE-1] w_adc_nco_busy;
    
    bd_wrapper BD (

        // clock
        .adc1_clk_0_clk_n(i_adc1_clk_n),
        .adc1_clk_0_clk_p(i_adc1_clk_p),
        .dac1_clk_0_clk_n(i_dac1_clk_n),
        .dac1_clk_0_clk_p(i_dac1_clk_p),
        .clk_dac1_0(w_dcrfli_clk),
        .dcrfli_clk(w_dcrfli_clk),
        .o_pl_clk(w_pl_clk),
        
        // reset
        .dcrfli_rst_n(w_dcrfli_rst_n),
        .o_pl_rst_n(w_pl_rst_n),

        // dc x 24
        .o_dc_seq_regs0(w_dc_seq_regs[0]),
        .o_dc_seq_regs1(w_dc_seq_regs[1]),
        .o_dc_seq_regs2(w_dc_seq_regs[2]),
        .o_dc_seq_regs3(w_dc_seq_regs[3]),
        .o_dc_seq_regs4(w_dc_seq_regs[4]),
        .o_dc_seq_regs5(w_dc_seq_regs[5]),
        .o_dc_seq_regs6(w_dc_seq_regs[6]),
        .o_dc_seq_regs7(w_dc_seq_regs[7]),
        .o_dc_seq_regs8(w_dc_seq_regs[8]),
        .o_dc_seq_regs9(w_dc_seq_regs[9]),
        .o_dc_seq_regs10(w_dc_seq_regs[10]),
        .o_dc_seq_regs11(w_dc_seq_regs[11]),
        .o_dc_seq_regs12(w_dc_seq_regs[12]),
        .o_dc_seq_regs13(w_dc_seq_regs[13]),
        .o_dc_seq_regs14(w_dc_seq_regs[14]),
        .o_dc_seq_regs15(w_dc_seq_regs[15]),
        .o_dc_seq_regs16(w_dc_seq_regs[16]),
        .o_dc_seq_regs17(w_dc_seq_regs[17]),
        .o_dc_seq_regs18(w_dc_seq_regs[18]),
        .o_dc_seq_regs19(w_dc_seq_regs[19]),
        .o_dc_seq_regs20(w_dc_seq_regs[20]),
        .o_dc_seq_regs21(w_dc_seq_regs[21]),
        .o_dc_seq_regs22(w_dc_seq_regs[22]),
        .o_dc_seq_regs23(w_dc_seq_regs[23]),

        .o_dc_ctrl_regs0(w_dc_ctrl_regs[0]),
        .o_dc_ctrl_regs1(w_dc_ctrl_regs[1]),
        .o_dc_ctrl_regs2(w_dc_ctrl_regs[2]),
        .o_dc_ctrl_regs3(w_dc_ctrl_regs[3]),
        .o_dc_ctrl_regs4(w_dc_ctrl_regs[4]),
        .o_dc_ctrl_regs5(w_dc_ctrl_regs[5]),
        .o_dc_ctrl_regs6(w_dc_ctrl_regs[6]),
        .o_dc_ctrl_regs7(w_dc_ctrl_regs[7]),
        .o_dc_ctrl_regs8(w_dc_ctrl_regs[8]),
        .o_dc_ctrl_regs9(w_dc_ctrl_regs[9]),
        .o_dc_ctrl_regs10(w_dc_ctrl_regs[10]),
        .o_dc_ctrl_regs11(w_dc_ctrl_regs[11]),
        .o_dc_ctrl_regs12(w_dc_ctrl_regs[12]),
        .o_dc_ctrl_regs13(w_dc_ctrl_regs[13]),
        .o_dc_ctrl_regs14(w_dc_ctrl_regs[14]),
        .o_dc_ctrl_regs15(w_dc_ctrl_regs[15]),
        .o_dc_ctrl_regs16(w_dc_ctrl_regs[16]),
        .o_dc_ctrl_regs17(w_dc_ctrl_regs[17]),
        .o_dc_ctrl_regs18(w_dc_ctrl_regs[18]),
        .o_dc_ctrl_regs19(w_dc_ctrl_regs[19]),
        .o_dc_ctrl_regs20(w_dc_ctrl_regs[20]),
        .o_dc_ctrl_regs21(w_dc_ctrl_regs[21]),
        .o_dc_ctrl_regs22(w_dc_ctrl_regs[22]),
        .o_dc_ctrl_regs23(w_dc_ctrl_regs[23]),

        // rf x 6
        .o_rf_seq_regs0(w_rf_seq_regs[0]),
        .o_rf_seq_regs1(w_rf_seq_regs[1]),
        .o_rf_seq_regs2(w_rf_seq_regs[2]),
        .o_rf_seq_regs3(w_rf_seq_regs[3]),
        .o_rf_seq_regs4(w_rf_seq_regs[4]),
        .o_rf_seq_regs5(w_rf_seq_regs[5]),

        .o_rf_ctrl_regs0(w_rf_ctrl_regs[0]),
        .o_rf_ctrl_regs1(w_rf_ctrl_regs[1]),
        .o_rf_ctrl_regs2(w_rf_ctrl_regs[2]),
        .o_rf_ctrl_regs3(w_rf_ctrl_regs[3]),
        .o_rf_ctrl_regs4(w_rf_ctrl_regs[4]),
        .o_rf_ctrl_regs5(w_rf_ctrl_regs[5]),

        // nco update regs
        .o_nco_update_regs_0(w_dac_nco_regs[0]),
        .o_nco_update_regs_1(w_dac_nco_regs[1]),
        .o_nco_update_regs_2(w_dac_nco_regs[2]),
        .o_nco_update_regs_3(w_dac_nco_regs[3]),
        .o_nco_update_regs_4(w_adc_nco_regs[0]),

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

        // rf dac tile 228 nco update
        .dac0_nco_0_converter0_nco_freq(w_dac_nco_freq[0][0]),
        .dac0_nco_0_converter0_nco_phase(w_dac_nco_phase[0][0]),
        .dac0_nco_0_converter0_phase_reset(w_dac_nco_phase_rst[0][0]),
        .dac0_nco_0_converter0_update_en(w_dac_nco_en[0][0]),
        .dac0_nco_0_converter2_nco_freq(w_dac_nco_freq[0][1]),
        .dac0_nco_0_converter2_nco_phase(w_dac_nco_phase[0][1]),
        .dac0_nco_0_converter2_phase_reset(w_dac_nco_phase_rst[0][1]),
        .dac0_nco_0_converter2_update_en(w_dac_nco_en[0][1]),
        .dac0_nco_0_nco_update_busy(w_dac_nco_busy[0]),
        .dac0_nco_0_nco_update_request(w_dac_nco_req[0]),

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

        // rf dac tile 229 nco update
        .dac1_nco_0_converter0_nco_freq(w_dac_nco_freq[1][0]),
        .dac1_nco_0_converter0_nco_phase(w_dac_nco_phase[1][0]),
        .dac1_nco_0_converter0_phase_reset(w_dac_nco_phase_rst[1][0]),
        .dac1_nco_0_converter0_update_en(w_dac_nco_en[1][0]),
        .dac1_nco_0_converter2_nco_freq(w_dac_nco_freq[1][1]),
        .dac1_nco_0_converter2_nco_phase(w_dac_nco_phase[1][1]),
        .dac1_nco_0_converter2_phase_reset(w_dac_nco_phase_rst[1][1]),
        .dac1_nco_0_converter2_update_en(w_dac_nco_en[1][1]),
        .dac1_nco_0_nco_update_busy(w_dac_nco_busy[1]),
        .dac1_nco_0_nco_update_request(w_dac_nco_req[1]),

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

        // rf dac tile 230 nco update
        .dac2_nco_0_converter0_nco_freq(w_dac_nco_freq[2][0]),
        .dac2_nco_0_converter0_nco_phase(w_dac_nco_phase[2][0]),
        .dac2_nco_0_converter0_phase_reset(w_dac_nco_phase_rst[2][0]),
        .dac2_nco_0_converter0_update_en(w_dac_nco_en[2][0]),
        .dac2_nco_0_converter2_nco_freq(w_dac_nco_freq[2][1]),
        .dac2_nco_0_converter2_nco_phase(w_dac_nco_phase[2][1]),
        .dac2_nco_0_converter2_phase_reset(w_dac_nco_phase_rst[2][1]),
        .dac2_nco_0_converter2_update_en(w_dac_nco_en[2][1]),
        .dac2_nco_0_nco_update_busy(w_dac_nco_busy[2]),
        .dac2_nco_0_nco_update_request(w_dac_nco_req[2]),
        
        // rf_dac tile 231-0/1/2/3
        .s30_axis_0_tdata(),
        .s30_axis_0_tready(),
        .s30_axis_0_tvalid(),
        .s31_axis_0_tdata(),
        .s31_axis_0_tready(),
        .s31_axis_0_tvalid(),
        .s32_axis_0_tdata(w_li_QIx8_bus[0]),
        .s32_axis_0_tready(),
        .s32_axis_0_tvalid(1'b1),
        .s33_axis_0_tdata(w_li_QIx8_bus[1]),
        .s33_axis_0_tready(),
        .s33_axis_0_tvalid(1'b1),

        // rf dac tile 231 nco update
        .dac3_nco_0_converter2_nco_freq(w_dac_nco_freq[3][0]),
        .dac3_nco_0_converter2_nco_phase(w_dac_nco_phase[3][0]),
        .dac3_nco_0_converter2_phase_reset(w_dac_nco_phase_rst[3][0]),
        .dac3_nco_0_converter2_update_en(w_dac_nco_en[3][0]),
        .dac3_nco_0_converter3_nco_freq(w_dac_nco_freq[3][1]),
        .dac3_nco_0_converter3_nco_phase(w_dac_nco_phase[3][1]),
        .dac3_nco_0_converter3_phase_reset(w_dac_nco_phase_rst[3][1]),
        .dac3_nco_0_converter3_update_en(w_dac_nco_en[3][1]),
        .dac3_nco_0_nco_update_busy(w_dac_nco_busy[3]),
        .dac3_nco_0_nco_update_request(w_dac_nco_req[3]),

        // li x 2
        .o_li_seq_regs0(w_li_seq_regs[0]),
        .o_li_ctrl_regs0(w_li_ctrl_regs[0]),
        .i_li_QIx4_0(w_li_QIx4_save_bus[0]),
        .i_li_validx4_0(w_li_validx4_bus[0]),
        .i_li_last_0(w_li_last_bus[0]),
        .i_li_ctrl_0(w_li_ctrl_bus[0]),

        .o_li_seq_regs1(w_li_seq_regs[1]),
        .o_li_ctrl_regs1(w_li_ctrl_regs[1]),
        .i_li_QIx4_1(w_li_QIx4_save_bus[1]),
        .i_li_validx4_1(w_li_validx4_bus[1]),
        .i_li_last_1(w_li_last_bus[1]),
        .i_li_ctrl_1(w_li_ctrl_bus[1]),

        // rf adc tile 225-0
        .m10_axis_0_tdata(w_li_QIx4_bus[0]),
        .m10_axis_0_tready(1'b1),
        .m10_axis_0_tvalid(w_li_valid_bus[0]),
        .vin10_0_v_n(i_vin10_n),
        .vin10_0_v_p(i_vin10_p),

        // rf adc tile 225-1
        .m11_axis_0_tdata(w_li_QIx4_bus[1]),
        .m11_axis_0_tready(1'b1),
        .m11_axis_0_tvalid(w_li_valid_bus[1]),
        .vin11_0_v_n(i_vin11_n),
        .vin11_0_v_p(i_vin11_p),

        .sysref_in_0_diff_n(i_sysref_n),
        .sysref_in_0_diff_p(i_sysref_p),

        // rf adc tile 225 nco update
        .adc1_nco_0_converter0_nco_freq(w_adc_nco_freq[0][0]),
        .adc1_nco_0_converter0_nco_phase(w_adc_nco_phase[0][0]),
        .adc1_nco_0_converter0_phase_reset(w_adc_nco_phase_rst[0][0]),
        .adc1_nco_0_converter0_update_en(w_adc_nco_en[0][0]),
        .adc1_nco_0_converter1_nco_freq(w_adc_nco_freq[0][1]),
        .adc1_nco_0_converter1_nco_phase(w_adc_nco_phase[0][1]),
        .adc1_nco_0_converter1_phase_reset(w_adc_nco_phase_rst[0][1]),
        .adc1_nco_0_converter1_update_en(w_adc_nco_en[0][1]),
        .adc1_nco_0_nco_update_busy(w_adc_nco_busy[0]),
        .adc1_nco_0_nco_update_request(w_adc_nco_req[0]),

        // launch x 1
        .o_lch_regs(w_lch_regs)

    );

    dcrfli_uart_btn #(
        .NUM_DC_CHANNEL(NUM_DC_CHANNEL),
        .NUM_RF_CHANNEL(NUM_RF_CHANNEL),
        .NUM_LI_CHANNEL(NUM_LI_CHANNEL),
        .NUM_DEBOUNCE_CYCLES(NUM_DEBOUNCE_CYCLES)
    ) DCRFLI (
        .i_clk(w_dcrfli_clk),
        .i_rst(!w_dcrfli_rst_n),

        // dc
        .i_dc_seq_regs(w_dc_seq_regs),
        .i_dc_ctrl_regs(w_dc_ctrl_regs),

        .i_dc_seq_uregs(w_uregs[U_DC_SEQ_START:U_DC_SEQ_END]),
        .i_dc_ctrl_uregs(w_uregs[U_DC_CTRL_START:U_DC_CTRL_END]),

        .o_dc_sclk_bus(w_dc_sclk_bus),
        .o_dc_mosi_bus(w_dc_mosi_bus),
        .i_dc_miso_bus(w_dc_miso_bus),
        .o_dc_cs_n_bus(w_dc_cs_n_bus),
        .o_dc_ldac_n_bus(w_dc_ldac_n_bus),

        .o_dc_armed_bus(w_dc_armed_bus),

        .o_dc_empty_bus(),

        .o_dc_eop_bus(),

        // rf
        .i_rf_seq_regs(w_rf_seq_regs),
        .i_rf_ctrl_regs(w_rf_ctrl_regs),

        .i_rf_seq_uregs(w_uregs[U_RF_SEQ_START:U_RF_SEQ_END]),
        .i_rf_ctrl_uregs(w_uregs[U_RF_CTRL_START:U_RF_CTRL_END]),

        .o_rf_QIx8_bus(w_rf_QIx8_bus),

        .o_rf_armed_bus(w_rf_armed_bus),

        .o_rf_empty_bus(),

        .o_rf_eop_bus(),

        // li
        .i_li_seq_regs(w_li_seq_regs),
        .i_li_ctrl_regs(w_li_ctrl_regs),

        .i_li_seq_uregs(w_uregs[U_LI_SEQ_START:U_LI_SEQ_END]),
        .i_li_ctrl_uregs(w_uregs[U_LI_CTRL_START:U_LI_CTRL_END]),

        .i_li_QIx4_bus(w_li_QIx4_bus),

        .o_li_armed_bus(w_li_armed_bus),

        .o_li_empty_bus(),

        .o_li_sample_mask_bus(w_li_sample_mask_bus),
        
        .o_li_QIx4_bus(w_li_QIx4_save_bus),
        .o_li_validx4_bus(w_li_validx4_bus),
        .o_li_last_bus(w_li_last_bus),

        .o_li_ctrl_bus(w_li_ctrl_bus),

        .o_li_eop_bus(),


        // launch
        .i_lch_regs(w_lch_regs),

        .i_lch_uregs(w_uregs[U_LCH_START:U_LCH_END]),
        
        // button
        .i_btn(i_btn_w)
    );

    assign w_li_QIx8_bus[0] = {
        w_li_ctrl_bus[0].w_default_Q, PAD, w_li_ctrl_bus[0].w_default_I, PAD,
        w_li_ctrl_bus[0].w_default_Q, PAD, w_li_ctrl_bus[0].w_default_I, PAD,
        w_li_ctrl_bus[0].w_default_Q, PAD, w_li_ctrl_bus[0].w_default_I, PAD,
        w_li_ctrl_bus[0].w_default_Q, PAD, w_li_ctrl_bus[0].w_default_I, PAD,
        w_li_ctrl_bus[0].w_default_Q, PAD, w_li_ctrl_bus[0].w_default_I, PAD,
        w_li_ctrl_bus[0].w_default_Q, PAD, w_li_ctrl_bus[0].w_default_I, PAD,
        w_li_ctrl_bus[0].w_default_Q, PAD, w_li_ctrl_bus[0].w_default_I, PAD,
        w_li_ctrl_bus[0].w_default_Q, PAD, w_li_ctrl_bus[0].w_default_I, PAD
    };

    assign w_li_QIx8_bus[1] = {
        w_li_ctrl_bus[1].w_default_Q, PAD, w_li_ctrl_bus[1].w_default_I, PAD,
        w_li_ctrl_bus[1].w_default_Q, PAD, w_li_ctrl_bus[1].w_default_I, PAD,
        w_li_ctrl_bus[1].w_default_Q, PAD, w_li_ctrl_bus[1].w_default_I, PAD,
        w_li_ctrl_bus[1].w_default_Q, PAD, w_li_ctrl_bus[1].w_default_I, PAD,
        w_li_ctrl_bus[1].w_default_Q, PAD, w_li_ctrl_bus[1].w_default_I, PAD,
        w_li_ctrl_bus[1].w_default_Q, PAD, w_li_ctrl_bus[1].w_default_I, PAD,
        w_li_ctrl_bus[1].w_default_Q, PAD, w_li_ctrl_bus[1].w_default_I, PAD,
        w_li_ctrl_bus[1].w_default_Q, PAD, w_li_ctrl_bus[1].w_default_I, PAD
    };

    nco_update_tiles #(
        .NUM_DAC_TILE(NUM_DAC_TILE),
        .NUM_ADC_TILE(NUM_ADC_TILE),
        .NCO_PER_DAC_TILE(NCO_PER_DAC_TILE),
        .NCO_PER_ADC_TILE(NCO_PER_ADC_TILE)
    ) NCO (
        .i_clk(w_pl_clk),
        .i_rst(!w_pl_rst_n),

        // dac nco tile 228/229/230/231
        .i_dac_nco_regs(w_dac_nco_regs),
        .i_dac_nco_uregs('h0),

        .o_dac_nco_freq(w_dac_nco_freq),
        .o_dac_nco_phase(w_dac_nco_phase),
        .o_dac_nco_phase_rst(w_dac_nco_phase_rst),
        .o_dac_nco_en(w_dac_nco_en),
        .o_dac_nco_update_req(w_dac_nco_req),
        .o_dac_nco_update_busy(w_dac_nco_busy),

        // adc nco tile 225
        .i_adc_nco_regs(w_adc_nco_regs),
        .i_adc_nco_uregs('h0),

        .o_adc_nco_freq(w_adc_nco_freq),
        .o_adc_nco_phase(w_adc_nco_phase),
        .o_adc_nco_phase_rst(w_adc_nco_phase_rst),
        .o_adc_nco_en(w_adc_nco_en),
        .o_adc_nco_update_req(w_adc_nco_req),
        .o_adc_nco_update_busy(w_adc_nco_busy)
    );
    
    assign w_dc_clr = 1'b1;
    assign w_dc_rst = 1'b1;

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
