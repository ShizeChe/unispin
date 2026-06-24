`timescale 1ns / 1ps

module phase_observe
    (input  logic i_clk, i_dac_clk,
     input  logic [7:0][17:0] i_phasex8,
     output logic [17:0] o_phase);

    int dac_cycle;
    initial begin
        @(posedge i_clk);
        dac_cycle = 0;
        forever begin
            @(posedge i_dac_clk);
            dac_cycle = (dac_cycle == 7) ? 0 : (dac_cycle + 1);
        end
    end

    initial begin
        forever begin
            @(negedge i_dac_clk);
            o_phase = i_phasex8[dac_cycle];
        end
    end

endmodule
