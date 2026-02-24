// `default_nettype none
`timescale 1ns / 1ps

module zcu216_adc
    (input  logic i_clk, i_adc_clk,
     input  real i_vli,
     output logic [127:0] o_Ix8, o_Qx8,
     input  logic [7:0] i_sample_mask,
     output logic o_sample_spike);

    // if i_clk is 250MHz, simulated nco is 10MHz
    int adc_cycle;
    initial begin
        @(posedge i_clk);
        adc_cycle = 0;
        forever begin
            @(posedge i_adc_clk);
            adc_cycle = (adc_cycle == 7) ? 0 : (adc_cycle + 1);
        end
    end

    logic [7:0] r_sample_mask;

    always_ff @(posedge i_clk) begin
        r_sample_mask <= i_sample_mask;
    end

    initial begin
        forever begin
            @(negedge i_adc_clk);
            o_sample_spike = i_sample_mask[adc_cycle];
        end
    end

    logic [15:0] s;

    initial begin

        s = 16'd0;

        forever begin

            @(posedge i_clk);

            o_Ix8 = {
                16'(s + 16'd7),
                16'(s + 16'd6),
                16'(s + 16'd5),
                16'(s + 16'd4),
                16'(s + 16'd3),
                16'(s + 16'd2),
                16'(s + 16'd1),
                16'(s)
            };
            o_Qx8 = {
                16'(s + 16'd7),
                16'(s + 16'd6),
                16'(s + 16'd5),
                16'(s + 16'd4),
                16'(s + 16'd3),
                16'(s + 16'd2),
                16'(s + 16'd1),
                16'(s)
            };

            s += 8;

        end

    end

endmodule
