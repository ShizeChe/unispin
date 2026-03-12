// `default_nettype none
`timescale 1ns / 1ps

module nco_update_tiles
   #(parameter NUM_DAC_TILE=4,
     parameter NUM_ADC_TILE=1,
     parameter NCO_PER_DAC_TILE=2,
     parameter NCO_PER_ADC_TILE=2)
    (input  logic i_clk, i_rst,

     // nco update registers dac tile 228/229/230/231
     input  logic [0:NUM_DAC_TILE-1][0:NCO_PER_DAC_TILE*3][31:0] i_dac_nco_regs,
     input  logic [0:NUM_DAC_TILE-1][0:NCO_PER_DAC_TILE*3][31:0] i_dac_nco_uregs,

     output logic [0:NUM_DAC_TILE-1][0:NCO_PER_DAC_TILE-1][47:0] o_dac_nco_freq,
     output logic [0:NUM_DAC_TILE-1][0:NCO_PER_DAC_TILE-1][17:0] o_dac_nco_phase,
     output logic [0:NUM_DAC_TILE-1][0:NCO_PER_DAC_TILE-1] o_dac_nco_phase_rst,
     output logic [0:NUM_DAC_TILE-1][0:NCO_PER_DAC_TILE-1][5:0] o_dac_nco_en,
     output logic [0:NUM_DAC_TILE-1] o_dac_nco_update_req,
     input  logic [0:NUM_DAC_TILE-1] o_dac_nco_update_busy,

     // nco update registers adc tile 225
     input  logic [0:NUM_ADC_TILE-1][0:NCO_PER_ADC_TILE*3][31:0] i_adc_nco_regs,
     input  logic [0:NUM_ADC_TILE-1][0:NCO_PER_ADC_TILE*3][31:0] i_adc_nco_uregs,

     output logic [0:NUM_ADC_TILE-1][0:NCO_PER_ADC_TILE-1][47:0] o_adc_nco_freq,
     output logic [0:NUM_ADC_TILE-1][0:NCO_PER_ADC_TILE-1][17:0] o_adc_nco_phase,
     output logic [0:NUM_ADC_TILE-1][0:NCO_PER_ADC_TILE-1] o_adc_nco_phase_rst,
     output logic [0:NUM_ADC_TILE-1][0:NCO_PER_ADC_TILE-1][5:0] o_adc_nco_en,
     output logic [0:NUM_ADC_TILE-1] o_adc_nco_update_req,
     input  logic [0:NUM_ADC_TILE-1] o_adc_nco_update_busy);

    /************
    * nco update
    ************/

    for (genvar i = 0; i < NUM_DAC_TILE; i++) begin : DAC_NCO_UPDATE_GEN
        nco_update #(
            .NUM_NCO(NCO_PER_DAC_TILE)
        ) DAC_NCO_UPDATE (
            .i_clk(i_clk),
            .i_rst(i_rst),

            .i_regs(i_dac_nco_regs[i]),
            .i_uregs(i_dac_nco_uregs[i]),

            .o_freq(o_dac_nco_freq[i]),
            .o_phase(o_dac_nco_phase[i]),
            .o_phase_rst(o_dac_nco_phase_rst[i]),
            .o_en(o_dac_nco_en[i]),
            .o_req(o_dac_nco_update_req[i]),
            .i_busy(o_dac_nco_update_busy[i])
        );
    end

    for (genvar i = 0; i < NUM_ADC_TILE; i++) begin : ADC_NCO_UPDATE_GEN
        nco_update #(
            .NUM_NCO(NCO_PER_ADC_TILE)
        ) ADC_NCO_UPDATE (
            .i_clk(i_clk),
            .i_rst(i_rst),

            .i_regs(i_adc_nco_regs[i]),
            .i_uregs(i_adc_nco_uregs[i]),

            .o_freq(o_adc_nco_freq[i]),
            .o_phase(o_adc_nco_phase[i]),
            .o_phase_rst(o_adc_nco_phase_rst[i]),
            .o_en(o_adc_nco_en[i]),
            .o_req(o_adc_nco_update_req[i]),
            .i_busy(o_adc_nco_update_busy[i])
        );
    end

endmodule
