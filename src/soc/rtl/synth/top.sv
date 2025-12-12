`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/10/2025 02:20:10 PM
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top (

    input  logic i_adc1_clk_n, i_adc1_clk_p,
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

    output logic o_la01_p, o_la00_p, o_la06_p, o_la01_n,
    output logic o_la03_p, o_la06_n, o_la05_p, o_la13_p,
    output logic o_la09_n, o_la09_p, o_la05_n, o_la10_n,
    output logic o_la13_n, o_la10_p, o_la14_p, o_la17_p,
    output logic o_la33_n, o_la33_p, o_la29_n, o_la29_p,
    output logic o_la25_n, o_la25_p, o_la27_n, o_la27_p,
    output logic o_la26_p, o_la26_n, o_la23_n, o_la23_p,
    
    output logic o_la31_n, o_la31_p, o_la28_n, o_la28_p,
    output logic o_la24_n, o_la24_p, o_la21_n, o_la21_p,
    output logic o_la22_n, o_la22_p, o_la19_n, o_la19_p,
    output logic o_la20_n, o_la20_p, o_la15_n, o_la15_p,
    output logic o_la00_n, o_la02_p, o_la02_n, o_la03_n,
    output logic o_la04_p, o_la04_n, o_la08_p, o_la08_n,
    output logic o_la07_p, o_la07_n, o_la12_p, o_la12_n,
    output logic o_la11_p, o_la11_n, o_la16_p, o_la16_n,

    output logic o_dacio00, o_dacio01, o_dacio02, o_dacio03,
    output logic o_dacio04, o_dacio05, o_dacio06, o_dacio07,
    output logic o_dacio08, o_dacio09, o_dacio10, o_dacio11,
    output logic o_dacio12, o_dacio13, o_dacio14, o_dacio15,

    output logic o_adcio00, o_adcio01, o_adcio02, o_adcio03,
    output logic o_adcio04, o_adcio05, o_adcio06, o_adcio07,
    output logic o_adcio08, o_adcio09, o_adcio10, o_adcio11,
    output logic o_adcio12, o_adcio13, o_adcio14, o_adcio15,

    output logic o_pmod00, o_pmod01, o_pmod02, o_pmod03,
    
    output logic o_gled0, o_gled1, o_gled2, o_gled3,
    output logic o_gled4, o_gled5, o_gled6, o_gled7,
    
    output logic o_bled0, o_bled1, o_bled2, o_bled3,
    output logic o_bled4, o_bled5, o_bled6, o_bled7,
    
    input  logic i_btn_w

);

    // dc parameters
    localparam DC_DAC_WIDTH=16;
    
    localparam DC_CYCLE_WIDTH=30;
    localparam DC_STREAM_ITER_WIDTH=10;
    localparam DC_CORE_ITER_WIDTH=10;
    localparam DC_STREAM_DEPTH=10;
    localparam DC_INSN_WIDTH=DC_DAC_WIDTH*2+DC_CORE_ITER_WIDTH+DC_CYCLE_WIDTH;
    localparam DC_TOTAL_REGS=DC_STREAM_DEPTH*3+2;

    //rf parameters
    localparam RF_KBC_WIDTH=36;
    localparam RF_NUM_SAMPLE_WIDTH=30;
    localparam RF_CORE_ITER_WIDTH=10;
    localparam RF_INSN_WIDTH=RF_KBC_WIDTH*3+RF_CORE_ITER_WIDTH+RF_NUM_SAMPLE_WIDTH*4;
    localparam RF_IQ_WIDTH=14;
    localparam RF_DAC_WIDTH=16;
    localparam RF_PHASE_WIDTH=18;
    localparam RF_CORDIC_STAGES=15;
    localparam RF_CORDIC_PAD_ZEROS=8;

    localparam RF_INSN_BUF_DEPTH=4;
    localparam RF_IPTR_WIDTH=$clog2(RF_INSN_BUF_DEPTH);
    localparam RF_IPTR_BUF_DEPTH=512;
    localparam RF_INSN_REGS=(RF_INSN_WIDTH+31)/32*RF_INSN_BUF_DEPTH;
    localparam RF_IPTR_REGS=(RF_IPTR_BUF_DEPTH+32/RF_IPTR_WIDTH-1)/(32/RF_IPTR_WIDTH);
    localparam RF_STREAM_ITER_WIDTH=10;
    localparam RF_TOTAL_REGS=RF_INSN_REGS+RF_IPTR_REGS+2;

    localparam RF_REG_PER_INSN = (RF_INSN_WIDTH + 31) / 32;
    localparam RF_IPTR_PER_REG = 32 / RF_IPTR_WIDTH;

    // li parameters
    localparam LI_ADC_WIDTH = 16;

    // define number of dc/rf/li channels
    localparam NUM_DC_CHANNEL=24;
    localparam NUM_RF_CHANNEL=6;
    localparam NUM_LI_CHANNEL=2;

    logic w_clk;

    logic [NUM_DC_CHANNEL-1:0][DC_TOTAL_REGS-1:0][31:0] w_dc_regs;
    logic [NUM_RF_CHANNEL-1:0][RF_TOTAL_REGS-1:0][31:0] w_rf_regs;
    logic [3:0][31:0] w_launch_regs;

    logic [NUM_DC_CHANNEL-1:0] w_dc_sclk_bus;
    logic [NUM_DC_CHANNEL-1:0] w_dc_mosi_bus;
    logic [NUM_DC_CHANNEL-1:0] w_dc_cs_n_bus;
    logic [NUM_DC_CHANNEL-1:0] w_dc_ldac_n_bus;

    logic [NUM_DC_CHANNEL-1:0] w_dc_start_bus;
    logic [NUM_DC_CHANNEL-1:0] w_dc_armed_bus;

    logic [NUM_RF_CHANNEL-1:0][RF_DAC_WIDTH*16-1:0] w_rf_QIx8_bus;

    logic [NUM_RF_CHANNEL-1:0] w_rf_start_bus;
    logic [NUM_RF_CHANNEL-1:0] w_rf_armed_bus;
    logic [NUM_RF_CHANNEL-1:0] w_rf_dac_ready_bus;

    logic [NUM_LI_CHANNEL-1:0][LI_ADC_WIDTH*8-1:0] w_li_QIx4_bus;
    logic [NUM_LI_CHANNEL-1:0] w_li_adc_ready_bus;
    logic [NUM_LI_CHANNEL-1:0] w_li_adc_valid_bus;

    logic w_rst;

    design_3_wrapper PS_AXI_RF
       (
        .rf_axis_clk(w_clk),

        // dc regs
        .o_dc_regs_0(w_dc_regs[0]),
        .o_dc_regs_1(w_dc_regs[1]),
        .o_dc_regs_2(w_dc_regs[2]),
        .o_dc_regs_3(w_dc_regs[3]),
        .o_dc_regs_4(w_dc_regs[4]),
        .o_dc_regs_5(w_dc_regs[5]),
        .o_dc_regs_6(w_dc_regs[6]),
        .o_dc_regs_7(w_dc_regs[7]),
        .o_dc_regs_8(w_dc_regs[8]),
        .o_dc_regs_9(w_dc_regs[9]),
        .o_dc_regs_10(w_dc_regs[10]),
        .o_dc_regs_11(w_dc_regs[11]),
        .o_dc_regs_12(w_dc_regs[12]),
        .o_dc_regs_13(w_dc_regs[13]),
        .o_dc_regs_14(w_dc_regs[14]),
        .o_dc_regs_15(w_dc_regs[15]),
        .o_dc_regs_16(w_dc_regs[16]),
        .o_dc_regs_17(w_dc_regs[17]),
        .o_dc_regs_18(w_dc_regs[18]),
        .o_dc_regs_19(w_dc_regs[19]),
        .o_dc_regs_20(w_dc_regs[20]),
        .o_dc_regs_21(w_dc_regs[21]),
        .o_dc_regs_22(w_dc_regs[22]),
        .o_dc_regs_23(w_dc_regs[23]),

        // rf regs
        .o_rf_regs_0(w_rf_regs[0]),
        .o_rf_regs_1(w_rf_regs[1]),
        .o_rf_regs_2(w_rf_regs[2]),
        .o_rf_regs_3(w_rf_regs[3]),
        .o_rf_regs_4(w_rf_regs[4]),
        .o_rf_regs_5(w_rf_regs[5]),

        // launch regs
        .o_launch_regs_0(w_launch_regs),

        // adc0 dma
//        .S_AXIS_S2MM_0_tdata(w_li_QIx4_bus[0]),
//        .S_AXIS_S2MM_0_tkeep(16'hffff),
//        .S_AXIS_S2MM_0_tlast(1'b0),
//        .S_AXIS_S2MM_0_tready(w_li_adc_ready_bus[0]),
//        .S_AXIS_S2MM_0_tvalid(w_li_adc_valid_bus[0]),

        // adc1 dma
//        .S_AXIS_S2MM_1_tdata(w_li_QIx4_bus[1]),
//        .S_AXIS_S2MM_1_tkeep(16'hffff),
//        .S_AXIS_S2MM_1_tlast(1'b0),
//        .S_AXIS_S2MM_1_tready(w_li_adc_ready_bus[1]),
//        .S_AXIS_S2MM_1_tvalid(w_li_adc_valid_bus[1]),

        .adc1_clk_0_clk_n(i_adc1_clk_n),
        .adc1_clk_0_clk_p(i_adc1_clk_p),

        .dac1_clk_0_clk_n(i_dac1_clk_n),
        .dac1_clk_0_clk_p(i_dac1_clk_p),

        .m10_axis_0_tdata(w_li_QIx4_bus[0]),
        .m10_axis_0_tready(w_li_adc_ready_bus[0]),
        .m10_axis_0_tvalid(w_li_adc_valid_bus[0]),

        .m11_axis_0_tdata(w_li_QIx4_bus[1]),
        .m11_axis_0_tready(w_li_adc_ready_bus[1]),
        .m11_axis_0_tvalid(w_li_adc_valid_bus[1]),

        .peripheral_reset_0(w_rst),

        .s00_axis_0_tdata(w_rf_QIx8_bus[0]),
        .s00_axis_0_tready(w_rf_dac_ready_bus[0]),
        .s00_axis_0_tvalid(1'b1),

        .s02_axis_0_tdata(w_rf_QIx8_bus[1]),
        .s02_axis_0_tready(w_rf_dac_ready_bus[1]),
        .s02_axis_0_tvalid(1'b1),

        .s10_axis_0_tdata(w_rf_QIx8_bus[2]),
        .s10_axis_0_tready(w_rf_dac_ready_bus[2]),
        .s10_axis_0_tvalid(1'b1),

        .s12_axis_0_tdata(w_rf_QIx8_bus[3]),
        .s12_axis_0_tready(w_rf_dac_ready_bus[3]),
        .s12_axis_0_tvalid(1'b1),

        .s20_axis_0_tdata(w_rf_QIx8_bus[4]),
        .s20_axis_0_tready(w_rf_dac_ready_bus[4]),
        .s20_axis_0_tvalid(1'b1),

        .s22_axis_0_tdata(w_rf_QIx8_bus[5]),
        .s22_axis_0_tready(w_rf_dac_ready_bus[5]),
        .s22_axis_0_tvalid(1'b1),

        .sysref_in_0_diff_n(i_sysref_n),
        .sysref_in_0_diff_p(i_sysref_p),

        .vin10_0_v_n(i_vin10_n),
        .vin10_0_v_p(i_vin10_p),

        .vin11_0_v_n(i_vin11_n),
        .vin11_0_v_p(i_vin11_p),

        .vout00_0_v_n(o_vout00_n),
        .vout00_0_v_p(o_vout00_p),

        .vout01_0_v_n(o_vout01_n),
        .vout01_0_v_p(o_vout01_p),

        .vout02_0_v_n(o_vout02_n),
        .vout02_0_v_p(o_vout02_p),

        .vout03_0_v_n(o_vout03_n),
        .vout03_0_v_p(o_vout03_p),

        .vout10_0_v_n(o_vout10_n),
        .vout10_0_v_p(o_vout10_p),

        .vout11_0_v_n(o_vout11_n),
        .vout11_0_v_p(o_vout11_p),

        .vout12_0_v_n(o_vout12_n),
        .vout12_0_v_p(o_vout12_p),

        .vout13_0_v_n(o_vout13_n),
        .vout13_0_v_p(o_vout13_p),

        .vout20_0_v_n(o_vout20_n),
        .vout20_0_v_p(o_vout20_p),

        .vout21_0_v_n(o_vout21_n),
        .vout21_0_v_p(o_vout21_p),

        .vout22_0_v_n(o_vout22_n),
        .vout22_0_v_p(o_vout22_p),

        .vout23_0_v_n(o_vout23_n),
        .vout23_0_v_p(o_vout23_p)
    );

    for (genvar i = 0; i < NUM_DC_CHANNEL; i++) begin : DC_GEN

        dc #(
            .DAC_WIDTH(DC_DAC_WIDTH),
            .CYCLE_WIDTH(DC_CYCLE_WIDTH),
            .STREAM_ITER_WIDTH(DC_STREAM_ITER_WIDTH),
            .CORE_ITER_WIDTH(DC_CORE_ITER_WIDTH),
            .DEPTH(DC_STREAM_DEPTH)
        ) DC (
            .i_clk(w_clk),
            .i_rst(w_rst),
            .i_regs(w_dc_regs[i]),
            .o_sclk(w_dc_sclk_bus[i]),
            .o_mosi(w_dc_mosi_bus[i]),
            .o_cs_n(w_dc_cs_n_bus[i]),
            .o_ldac_n(w_dc_ldac_n_bus[i]),
            .i_start(w_dc_start_bus[i]),
            .o_armed(w_dc_armed_bus[i])
        );

    end

    for (genvar i = 0; i < NUM_RF_CHANNEL; i++) begin : RF_GEN

        rf #(
            .KBC_WIDTH(RF_KBC_WIDTH),
            .NUM_SAMPLE_WIDTH(RF_NUM_SAMPLE_WIDTH),
            .CORE_ITER_WIDTH(RF_CORE_ITER_WIDTH),
            .IQ_WIDTH(RF_IQ_WIDTH),
            .DAC_WIDTH(RF_DAC_WIDTH),
            .PHASE_WIDTH(RF_PHASE_WIDTH),
            .CORDIC_STAGES(RF_CORDIC_STAGES),
            .CORDIC_PAD_ZEROS(RF_CORDIC_PAD_ZEROS),
            .INSN_BUF_DEPTH(RF_INSN_BUF_DEPTH),
            .IPTR_BUF_DEPTH(RF_IPTR_BUF_DEPTH),
            .STREAM_ITER_WIDTH(RF_STREAM_ITER_WIDTH)
        ) RF (
            .i_clk(w_clk),
            .i_rst(w_rst),
            .i_regs(w_rf_regs[i]),
            .o_QIx8(w_rf_QIx8_bus[i]),
            .i_start(w_rf_start_bus[i]),
            .o_armed(w_rf_armed_bus[i])
        );

    end

    logic [NUM_LI_CHANNEL-1:0] w_li_start_bus;
    logic [NUM_LI_CHANNEL-1:0] w_li_armed_bus;
    assign w_li_armed_bus = 'h0;

    logic w_btn_c_steady;
    
    debouncer #(
        .NUM_CYCLES(25000000)
    ) DBC (
        .i_clk(w_clk),
        .i_rst(w_rst),
        .i_bouncy(i_btn_w),
        .o_steady(w_btn_c_steady)
    );
    
    logic w_btn_c_ff1;
    always_ff @(posedge w_clk) begin
        if (w_rst)
            w_btn_c_ff1 <= 1'b0;
        else
            w_btn_c_ff1 <= w_btn_c_steady;
    end
    
    logic w_launch_trigger;
    assign w_launch_trigger = w_btn_c_steady && !w_btn_c_ff1;
    
    launch #(
        .NUM_DC_CHANNEL(NUM_DC_CHANNEL),
        .NUM_RF_CHANNEL(NUM_RF_CHANNEL),
        .NUM_LI_CHANNEL(NUM_LI_CHANNEL)
    ) LCH (
        .i_clk(w_clk),
        .i_rst(w_rst),
        .i_regs(w_launch_regs),
        .i_dc_armed(w_dc_armed_bus),
        .i_rf_armed(w_rf_armed_bus),
        .i_li_armed(w_li_armed_bus),
        .i_trigger(w_launch_trigger),
        .o_dc_start(w_dc_start_bus),
        .o_rf_start(w_rf_start_bus),
        .o_li_start(w_li_start_bus)
    );

    always_comb begin

        {o_la01_p, o_la00_p, o_la06_p, o_la01_n} = 
            {w_dc_sclk_bus[0], w_dc_mosi_bus[0], w_dc_cs_n_bus[0], w_dc_ldac_n_bus[0]};
        {o_la03_p, o_la06_n, o_la05_p, o_la13_p} = 
            {w_dc_sclk_bus[1], w_dc_mosi_bus[1], w_dc_cs_n_bus[1], w_dc_ldac_n_bus[1]};
        {o_la09_n, o_la09_p, o_la05_n, o_la10_n} = 
            {w_dc_sclk_bus[2], w_dc_mosi_bus[2], w_dc_cs_n_bus[2], w_dc_ldac_n_bus[2]};
        {o_la13_n, o_la10_p, o_la14_p, o_la17_p} = 
            {w_dc_sclk_bus[3], w_dc_mosi_bus[3], w_dc_cs_n_bus[3], w_dc_ldac_n_bus[3]};
        {o_la33_n, o_la33_p, o_la29_n, o_la29_p} = 
            {w_dc_sclk_bus[4], w_dc_mosi_bus[4], w_dc_cs_n_bus[4], w_dc_ldac_n_bus[4]};
        {o_la25_n, o_la25_p, o_la27_n, o_la27_p} = 
            {w_dc_sclk_bus[5], w_dc_mosi_bus[5], w_dc_cs_n_bus[5], w_dc_ldac_n_bus[5]};
        {o_la26_p, o_la26_n, o_la23_n, o_la23_p} = 
            {w_dc_sclk_bus[6], w_dc_mosi_bus[6], w_dc_cs_n_bus[6], w_dc_ldac_n_bus[6]};

        {o_la31_n, o_la31_p, o_la28_n, o_la28_p} = 
            {w_dc_sclk_bus[7], w_dc_mosi_bus[7], w_dc_cs_n_bus[7], w_dc_ldac_n_bus[7]};
        {o_la24_n, o_la24_p, o_la21_n, o_la21_p} = 
            {w_dc_sclk_bus[8], w_dc_mosi_bus[8], w_dc_cs_n_bus[8], w_dc_ldac_n_bus[8]};
        {o_la22_n, o_la22_p, o_la19_n, o_la19_p} = 
            {w_dc_sclk_bus[9], w_dc_mosi_bus[9], w_dc_cs_n_bus[9], w_dc_ldac_n_bus[9]};
        {o_la20_n, o_la20_p, o_la15_n, o_la15_p} = 
            {w_dc_sclk_bus[10], w_dc_mosi_bus[10], w_dc_cs_n_bus[10], w_dc_ldac_n_bus[10]};
        {o_la00_n, o_la02_p, o_la02_n, o_la03_n} = 
            {w_dc_sclk_bus[11], w_dc_mosi_bus[11], w_dc_cs_n_bus[11], w_dc_ldac_n_bus[11]};
        {o_la04_p, o_la04_n, o_la08_p, o_la08_n} = 
            {w_dc_sclk_bus[12], w_dc_mosi_bus[12], w_dc_cs_n_bus[12], w_dc_ldac_n_bus[12]};
        {o_la07_p, o_la07_n, o_la12_p, o_la12_n} = 
            {w_dc_sclk_bus[13], w_dc_mosi_bus[13], w_dc_cs_n_bus[13], w_dc_ldac_n_bus[13]};
        {o_la11_p, o_la11_n, o_la16_p, o_la16_n} = 
            {w_dc_sclk_bus[14], w_dc_mosi_bus[14], w_dc_cs_n_bus[14], w_dc_ldac_n_bus[14]};

        {o_dacio00, o_dacio01, o_dacio02, o_dacio03} = 
            {w_dc_sclk_bus[15], w_dc_mosi_bus[15], w_dc_cs_n_bus[15], w_dc_ldac_n_bus[15]};
        {o_dacio04, o_dacio05, o_dacio06, o_dacio07} = 
            {w_dc_sclk_bus[16], w_dc_mosi_bus[16], w_dc_cs_n_bus[16], w_dc_ldac_n_bus[16]};
        {o_dacio08, o_dacio09, o_dacio10, o_dacio11} = 
            {w_dc_sclk_bus[17], w_dc_mosi_bus[17], w_dc_cs_n_bus[17], w_dc_ldac_n_bus[17]};
        {o_dacio12, o_dacio13, o_dacio14, o_dacio15} = 
            {w_dc_sclk_bus[18], w_dc_mosi_bus[18], w_dc_cs_n_bus[18], w_dc_ldac_n_bus[18]};

        {o_adcio00, o_adcio01, o_adcio02, o_adcio03} = 
            {w_dc_sclk_bus[19], w_dc_mosi_bus[19], w_dc_cs_n_bus[19], w_dc_ldac_n_bus[19]};
        {o_adcio04, o_adcio05, o_adcio06, o_adcio07} = 
            {w_dc_sclk_bus[20], w_dc_mosi_bus[20], w_dc_cs_n_bus[20], w_dc_ldac_n_bus[20]};
        {o_adcio08, o_adcio09, o_adcio10, o_adcio11} = 
            {w_dc_sclk_bus[21], w_dc_mosi_bus[21], w_dc_cs_n_bus[21], w_dc_ldac_n_bus[21]};
        {o_adcio12, o_adcio13, o_adcio14, o_adcio15} = 
            {w_dc_sclk_bus[22], w_dc_mosi_bus[22], w_dc_cs_n_bus[22], w_dc_ldac_n_bus[22]};

        {o_pmod00, o_pmod01, o_pmod02, o_pmod03} = 
            {w_dc_cs_n_bus[23], w_dc_mosi_bus[23], w_dc_ldac_n_bus[23], w_dc_sclk_bus[23]};

    end
    
    assign o_gled0 = w_rf_dac_ready_bus[0];
    assign o_gled1 = w_rf_dac_ready_bus[1];
    assign o_gled2 = w_rf_dac_ready_bus[2];
    assign o_gled3 = w_rf_dac_ready_bus[3];
    assign o_gled4 = w_rf_dac_ready_bus[4];
    assign o_gled5 = w_rf_dac_ready_bus[5];
    
    assign o_gled6 = w_li_adc_valid_bus[0];
    assign o_gled7 = w_li_adc_valid_bus[1];
    
    assign o_bled0 = w_dc_armed_bus[23];
    assign o_bled1 = w_dc_armed_bus[22];
    assign o_bled2 = w_rf_armed_bus[0];
    assign o_bled3 = w_rf_armed_bus[1];
    assign o_bled4 = w_rf_armed_bus[2];
    assign o_bled5 = w_rf_armed_bus[3];
    assign o_bled6 = w_rf_armed_bus[4];
    assign o_bled7 = w_rf_armed_bus[5];

endmodule
