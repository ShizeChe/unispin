// `default_nettype none
`timescale 1ns / 1ps
`include "dc.svh"
`include "rf.svh"

module io
   #(parameter NUM_DC_CHANNEL=24,
     parameter NUM_RF_CHANNEL=6,
     parameter NUM_LI_CHANNEL=1)
    (input  logic i_clk, i_rst,

     input  logic [0:NUM_DC_CHANNEL-1] i_dc_sclk_bus,
     input  logic [0:NUM_DC_CHANNEL-1] i_dc_mosi_bus,
     output logic [0:NUM_DC_CHANNEL-1] o_dc_miso_bus,
     input  logic [0:NUM_DC_CHANNEL-1] i_dc_cs_n_bus,
     input  logic [0:NUM_DC_CHANNEL-1] i_dc_ldac_n_bus,
     input  logic i_dc_clr, i_dc_rst,

     input  logic [0:NUM_DC_CHANNEL-1] i_dc_armed_bus,

     input  logic [0:NUM_RF_CHANNEL-1] i_rf_armed_bus,
     input  logic [0:NUM_RF_CHANNEL-1] i_rf_ready_bus,

     input  logic [0:1] i_li_valid_bus,

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

    logic w_sclk0,  w_mosi0,  w_miso0,  w_cs_n0,  w_ldac_n0;
    logic w_sclk1,  w_mosi1,  w_miso1,  w_cs_n1,  w_ldac_n1;
    logic w_sclk2,  w_mosi2,  w_miso2,  w_cs_n2,  w_ldac_n2;
    logic w_sclk3,  w_mosi3,  w_miso3,  w_cs_n3,  w_ldac_n3;
    logic w_sclk4,  w_mosi4,  w_miso4,  w_cs_n4,  w_ldac_n4;
    logic w_sclk5,  w_mosi5,  w_miso5,  w_cs_n5,  w_ldac_n5;
    logic w_sclk6,  w_mosi6,  w_miso6,  w_cs_n6,  w_ldac_n6;
    logic w_sclk7,  w_mosi7,  w_miso7,  w_cs_n7,  w_ldac_n7;
    logic w_sclk8,  w_mosi8,  w_miso8,  w_cs_n8,  w_ldac_n8;
    logic w_sclk9,  w_mosi9,  w_miso9,  w_cs_n9,  w_ldac_n9;
    logic w_sclk10, w_mosi10, w_miso10, w_cs_n10, w_ldac_n10;
    logic w_sclk11, w_mosi11, w_miso11, w_cs_n11, w_ldac_n11;
    logic w_sclk12, w_mosi12, w_miso12, w_cs_n12, w_ldac_n12;
    logic w_sclk13, w_mosi13, w_miso13, w_cs_n13, w_ldac_n13;
    logic w_sclk14, w_mosi14, w_miso14, w_cs_n14, w_ldac_n14;
    logic w_sclk15, w_mosi15, w_miso15, w_cs_n15, w_ldac_n15;
    logic w_sclk16, w_mosi16, w_miso16, w_cs_n16, w_ldac_n16;
    logic w_sclk17, w_mosi17, w_miso17, w_cs_n17, w_ldac_n17;
    logic w_sclk18, w_mosi18, w_miso18, w_cs_n18, w_ldac_n18;
    logic w_sclk19, w_mosi19, w_miso19, w_cs_n19, w_ldac_n19;
    logic w_sclk20, w_mosi20, w_miso20, w_cs_n20, w_ldac_n20;
    logic w_sclk21, w_mosi21, w_miso21, w_cs_n21, w_ldac_n21;
    logic w_sclk22, w_mosi22, w_miso22, w_cs_n22, w_ldac_n22;
    logic w_sclk23, w_mosi23, w_miso23, w_cs_n23, w_ldac_n23;

    assign w_sclk1  = i_dc_sclk_bus[0];
    assign w_mosi1  = i_dc_mosi_bus[0];
    assign w_miso1  = o_dc_miso_bus[0];
    assign w_cs1    = i_dc_cs_n_bus[0];
    assign w_ldac1  = i_dc_ldac_n_bus[0];

    assign w_sclk2  = i_dc_sclk_bus[1];
    assign w_mosi2  = i_dc_mosi_bus[1];
    assign w_miso2  = o_dc_miso_bus[1];
    assign w_cs2    = i_dc_cs_n_bus[1];
    assign w_ldac2  = i_dc_ldac_n_bus[1];

    assign w_sclk3  = i_dc_sclk_bus[2];
    assign w_mosi3  = i_dc_mosi_bus[2];
    assign w_miso3  = o_dc_miso_bus[2];
    assign w_cs3    = i_dc_cs_n_bus[2];
    assign w_ldac3  = i_dc_ldac_n_bus[2];

    assign w_sclk4  = i_dc_sclk_bus[3];
    assign w_mosi4  = i_dc_mosi_bus[3];
    assign w_miso4  = o_dc_miso_bus[3];
    assign w_cs4    = i_dc_cs_n_bus[3];
    assign w_ldac4  = i_dc_ldac_n_bus[3];

    assign w_sclk5  = i_dc_sclk_bus[4];
    assign w_mosi5  = i_dc_mosi_bus[4];
    assign w_miso5  = o_dc_miso_bus[4];
    assign w_cs5    = i_dc_cs_n_bus[4];
    assign w_ldac5  = i_dc_ldac_n_bus[4];

    assign w_sclk6  = i_dc_sclk_bus[5];
    assign w_mosi6  = i_dc_mosi_bus[5];
    assign w_miso6  = o_dc_miso_bus[5];
    assign w_cs6    = i_dc_cs_n_bus[5];
    assign w_ldac6  = i_dc_ldac_n_bus[5];

    assign w_sclk7  = i_dc_sclk_bus[6];
    assign w_mosi7  = i_dc_mosi_bus[6];
    assign w_miso7  = o_dc_miso_bus[6];
    assign w_cs7    = i_dc_cs_n_bus[6];
    assign w_ldac7  = i_dc_ldac_n_bus[6];

    assign w_sclk8  = i_dc_sclk_bus[7];
    assign w_mosi8  = i_dc_mosi_bus[7];
    assign w_miso8  = o_dc_miso_bus[7];
    assign w_cs8    = i_dc_cs_n_bus[7];
    assign w_ldac8  = i_dc_ldac_n_bus[7];

    assign w_sclk9  = i_dc_sclk_bus[8];
    assign w_mosi9  = i_dc_mosi_bus[8];
    assign w_miso9  = o_dc_miso_bus[8];
    assign w_cs9    = i_dc_cs_n_bus[8];
    assign w_ldac9  = i_dc_ldac_n_bus[8];

    assign w_sclk10 = i_dc_sclk_bus[9];
    assign w_mosi10 = i_dc_mosi_bus[9];
    assign w_miso10 = o_dc_miso_bus[9];
    assign w_cs10   = i_dc_cs_n_bus[9];
    assign w_ldac10 = i_dc_ldac_n_bus[9];

    assign w_sclk11 = i_dc_sclk_bus[10];
    assign w_mosi11 = i_dc_mosi_bus[10];
    assign w_miso11 = o_dc_miso_bus[10];
    assign w_cs11   = i_dc_cs_n_bus[10];
    assign w_ldac11 = i_dc_ldac_n_bus[10];

    assign w_sclk12 = i_dc_sclk_bus[11];
    assign w_mosi12 = i_dc_mosi_bus[11];
    assign w_miso12 = o_dc_miso_bus[11];
    assign w_cs12   = i_dc_cs_n_bus[11];
    assign w_ldac12 = i_dc_ldac_n_bus[11];

    assign w_sclk13 = i_dc_sclk_bus[12];
    assign w_mosi13 = i_dc_mosi_bus[12];
    assign w_miso13 = o_dc_miso_bus[12];
    assign w_cs13   = i_dc_cs_n_bus[12];
    assign w_ldac13 = i_dc_ldac_n_bus[12];

    assign w_sclk14 = i_dc_sclk_bus[13];
    assign w_mosi14 = i_dc_mosi_bus[13];
    assign w_miso14 = o_dc_miso_bus[13];
    assign w_cs14   = i_dc_cs_n_bus[13];
    assign w_ldac14 = i_dc_ldac_n_bus[13];

    assign w_sclk15 = i_dc_sclk_bus[14];
    assign w_mosi15 = i_dc_mosi_bus[14];
    assign w_miso15 = o_dc_miso_bus[14];
    assign w_cs15   = i_dc_cs_n_bus[14];
    assign w_ldac15 = i_dc_ldac_n_bus[14];

    assign w_sclk16 = i_dc_sclk_bus[15];
    assign w_mosi16 = i_dc_mosi_bus[15];
    assign w_miso16 = o_dc_miso_bus[15];
    assign w_cs16   = i_dc_cs_n_bus[15];
    assign w_ldac16 = i_dc_ldac_n_bus[15];

    assign w_sclk17 = i_dc_sclk_bus[16];
    assign w_mosi17 = i_dc_mosi_bus[16];
    assign w_miso17 = o_dc_miso_bus[16];
    assign w_cs17   = i_dc_cs_n_bus[16];
    assign w_ldac17 = i_dc_ldac_n_bus[16];

    assign w_sclk18 = i_dc_sclk_bus[17];
    assign w_mosi18 = i_dc_mosi_bus[17];
    assign w_miso18 = o_dc_miso_bus[17];
    assign w_cs18   = i_dc_cs_n_bus[17];
    assign w_ldac18 = i_dc_ldac_n_bus[17];

    assign w_sclk19 = i_dc_sclk_bus[18];
    assign w_mosi19 = i_dc_mosi_bus[18];
    assign w_miso19 = o_dc_miso_bus[18];
    assign w_cs19   = i_dc_cs_n_bus[18];
    assign w_ldac19 = i_dc_ldac_n_bus[18];

    assign w_sclk20 = i_dc_sclk_bus[19];
    assign w_mosi20 = i_dc_mosi_bus[19];
    assign w_miso20 = o_dc_miso_bus[19];
    assign w_cs20   = i_dc_cs_n_bus[19];
    assign w_ldac20 = i_dc_ldac_n_bus[19];

    assign w_sclk21 = i_dc_sclk_bus[20];
    assign w_mosi21 = i_dc_mosi_bus[20];
    assign w_miso21 = o_dc_miso_bus[20];
    assign w_cs21   = i_dc_cs_n_bus[20];
    assign w_ldac21 = i_dc_ldac_n_bus[20];

    assign w_sclk22 = i_dc_sclk_bus[21];
    assign w_mosi22 = i_dc_mosi_bus[21];
    assign w_miso22 = o_dc_miso_bus[21];
    assign w_cs22   = i_dc_cs_n_bus[21];
    assign w_ldac22 = i_dc_ldac_n_bus[21];

    assign w_sclk23 = i_dc_sclk_bus[22];
    assign w_mosi23 = i_dc_mosi_bus[22];
    assign w_miso23 = o_dc_miso_bus[22];
    assign w_cs23   = i_dc_cs_n_bus[22];
    assign w_ldac23 = i_dc_ldac_n_bus[22];

    assign w_sclk24 = i_dc_sclk_bus[23];
    assign w_mosi24 = i_dc_mosi_bus[23];
    assign w_miso24 = o_dc_miso_bus[23];
    assign w_cs24   = i_dc_cs_n_bus[23];
    assign w_ldac24 = i_dc_ldac_n_bus[23];

    // J2
    assign o_la01_p = w_ldac18; // 1
    assign o_la00_p = w_miso6; // 3
    assign o_la06_p = i_dc_clr; // 5
    assign o_la01_n = w_cs6; // 7
    assign o_la03_p = w_sclk6; // 9
    assign o_la06_n = w_mosi6; // 11
    assign o_la05_p = w_ldac6; // 13
    assign o_la13_p = w_miso5; // 15
    assign o_la09_n = w_cs5; // 17
    assign o_la09_p = w_sclk5; // 19
    assign o_la05_n = w_mosi5; // 21
    assign o_la10_n = w_ldac5; // 23
    assign o_la13_n = w_miso4; // 25
    assign o_la10_p = w_cs4; // 27
    assign o_la14_p = w_sclk4; // 29
    assign o_la17_p = w_mosi4; // 31

    assign o_la33_n = w_miso19; // 2
    assign o_la33_p = w_mosi18; // 4
    assign o_la29_n = w_sclk18; // 6
    assign o_la29_p = w_cs18; // 8
    assign o_la25_n = w_miso18; // 10
    assign o_la25_p = w_ldac17; // 12
    assign o_la27_n = w_mosi17; // 14
    assign o_la27_p = w_sclk17; // 16
    assign o_la26_p = w_cs17; // 18
    assign o_la26_n = w_miso17; // 20
    assign o_la23_n = w_ldac16; // 22
    assign o_la23_p = w_mosi16; // 24
    assign o_la18_n = w_sclk16; // 26
    assign o_la18_p = w_cs16; // 28

    // J3
    assign o_la31_n = w_miso13; // 1
    assign o_la31_p = w_cs13; // 3
    assign o_la28_n = w_sclk13; // 5
    assign o_la28_p = w_mosi13; // 7
    assign o_la24_n = w_ldac13; // 9
    assign o_la24_p = w_miso14; // 11
    assign o_la21_n = w_cs14; // 13
    assign o_la21_p = w_sclk14; // 17
    assign o_la22_n = w_mosi14; // 19
    assign o_la22_p = w_ldac14; // 20
    assign o_la19_n = w_miso15; // 21
    assign o_la19_p = w_cs15; // 23
    assign o_la20_n = w_sclk15; // 25
    assign o_la20_p = w_mosi15; // 27
    assign o_la15_n = w_ldac15; // 29
    assign o_la15_p = w_miso16; // 31

    assign o_la00_n = w_ldac1; // 2
    assign o_la02_p = w_mosi1; // 4
    assign o_la02_n = w_sclk1; // 6
    assign o_la03_n = w_cs1; // 8
    assign o_la04_p = w_miso1; // 10
    assign o_la04_n = w_ldac2; // 12
    assign o_la08_p = w_mosi2; // 14
    assign o_la08_n = w_sclk2; // 16
    assign o_la07_p = w_cs2; // 18
    assign o_la07_n = w_miso2; // 20
    assign o_la12_p = w_ldac3; // 22
    assign o_la12_n = w_mosi3; // 24
    assign o_la11_p = w_sclk3; // 26
    assign o_la11_n = w_cs3; // 28
    assign o_la16_p = w_miso3; // 30
    assign o_la16_n = w_ldac4; // 32

    // J4
    assign o_clk0_m2c_p = w_miso12; // 11
    assign o_clk0_m2c_n = w_ldac24; // 13
    assign o_clk1_m2c_p = w_miso11; // 27
    assign o_clk1_m2c_n = w_cs11; // 29

    // J6
    assign o_sync_c2m_p = w_mosi24;
    assign o_sync_c2m_n = w_cs12;
    assign o_sync_m2c_p = w_sclk24;
    assign o_sync_m2c_n = w_sclk12;
    assign o_la30_p = w_cs24;
    assign o_la30_n = w_mosi12;
    assign o_la32_p = w_miso24;
    assign o_la32_n = w_ldac12;
    assign o_la14_n = w_ldac21;
    assign o_la17_n = w_miso9;

    // DACIO
    assign o_dacio00 = w_mosi21; // 1
    assign o_dacio01 = w_cs9; // 3
    assign o_dacio02 = w_cs21; // 7
    assign o_dacio03 = w_mosi19; // 9
    assign o_dacio04 = w_ldac20; // 13
    assign o_dacio05 = w_miso8; // 15
    assign o_dacio06 = w_sclk20; // 1
    assign o_dacio07 = w_sclk8; // 3
    assign o_dacio08 = w_miso22; // 4
    assign o_dacio09 = w_cs22; // 6
    assign o_dacio10 = w_sclk21; // 10
    assign o_dacio11 = w_sclk9; // 12
    assign o_dacio12 = w_miso21; // 16
    assign o_dacio13 = w_ldac9; // 18
    assign o_dacio14 = w_mosi20; // 22
    assign o_dacio15 = w_cs8; // 24

    // ADCIO
    assign o_adcio00 = w_cs20; // 1
    assign o_adcio01 = w_mosi8; // 3
    assign o_adcio02 = w_ldac19; // 7
    assign o_adcio03 = w_miso7; // 9
    assign o_adcio04 = w_sclk19; // 13
    assign o_adcio05 = w_sclk7; // 15
    assign o_adcio06 = i_dc_rst; // 1
    assign o_adcio07 = w_ldac7; // 3
    assign o_adcio08 = 1'b1; // 4
    assign o_adcio09 = 1'b1; // 6
    assign o_adcio10 = w_miso20; // 10
    assign o_adcio11 = w_ldac8; // 12
    assign o_adcio12 = w_mosi19; // 16
    assign o_adcio13 = w_cs7; // 18
    assign o_adcio14 = w_cs19; // 22
    assign o_adcio15 = w_mosi7; // 24

    // PMOD0
    assign o_pmod00 = w_ldac23; // 1
    assign o_pmod01 = w_sclk11; // 2
    assign o_pmod02 = w_mosi23; // 3
    assign o_pmod03 = w_mosi11; // 4
    assign o_pmod04 = w_sclk23; // 5
    assign o_pmod05 = w_ldac11; // 6
    assign o_pmod06 = w_cs23; // 7
    assign o_pmod07 = w_miso10; // 8

    // PMOD1
    assign o_pmod10 = w_miso23; // 1
    assign o_pmod11 = w_cs10; // 2
    assign o_pmod12 = w_ldac22; // 3
    assign o_pmod13 = w_sclk10; // 4
    assign o_pmod14 = w_mosi22; // 5
    assign o_pmod15 = w_mosi10; // 6
    assign o_pmod16 = w_sclk22; // 7
    assign o_pmod17 = w_ldac10; // 8

    // LED
    assign {
        o_gled0, o_gled1, o_gled2, o_gled3,
        o_gled4, o_gled5, o_gled6, o_gled7
    } = {i_rf_ready_bus, i_li_valid_bus};

    assign {
        o_bled0, o_bled1, o_bled2, o_bled3,
        o_bled4, o_bled5, o_bled6, o_bled7
    } = {
        i_dc_armed_bus[0], i_dc_armed_bus[2],
        i_dc_armed_bus[4], i_dc_armed_bus[6],
        i_dc_armed_bus[8], i_dc_armed_bus[10],
        i_dc_armed_bus[12], i_dc_armed_bus[14],
    };

    assign {
        o_rled0, o_rled1, o_rled2, o_rled3,
        o_rled4, o_rled5, o_rled6, o_rled7
    } = {
        i_dc_armed_bus[16], i_dc_armed_bus[18],
        i_dc_armed_bus[20], i_dc_armed_bus[22],
        i_rf_armed_bus[0], i_rf_armed_bus[1],
        i_rf_armed_bus[2], i_rf_armed_bus[3],
    };

endmodule
