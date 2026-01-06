`default_nettype none
`timescale 1ns / 1ps
`include "dc.svh"
`include "rf.svh"

module io
   #(parameter NUM_DC_CHANNEL=24,
     parameter NUM_RF_CHANNEL=6,
     parameter NUM_LI_CHANNEL=1)
    (input  logic [0:NUM_DC_CHANNEL-1] i_dc_sclk_bus,
     input  logic [0:NUM_DC_CHANNEL-1] i_dc_mosi_bus,
     output logic [0:NUM_DC_CHANNEL-1] o_dc_miso_bus,
     input  logic [0:NUM_DC_CHANNEL-1] i_dc_cs_n_bus,
     input  logic [0:NUM_DC_CHANNEL-1] i_dc_ldac_n_bus,

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

endmodule
