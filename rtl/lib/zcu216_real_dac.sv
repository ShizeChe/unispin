`timescale 1ns / 1ps

module zcu216_real_dac
    (input  logic i_clk, i_dac_clk,
     input  logic [255:0] i_realx16,
     output logic [13:0] o_vex);

    int dac_cycle;
    initial begin
        @(posedge i_clk);
        dac_cycle = 0;
        forever begin
            @(posedge i_dac_clk);
            dac_cycle = (dac_cycle == 15) ? 0 : (dac_cycle + 1);
        end
    end

    localparam REAL_WIDTH=14;

    logic [15:0][REAL_WIDTH-1:0] w_realx16;

    for (genvar i = 0; i < 16; i++) begin : REALx16_ASSIGN
        assign w_realx16[i] = i_realx16[16*i+2+REAL_WIDTH-1:16*i+2];
    end

    initial begin
        o_vex = 'h0;
        forever begin
            @(negedge i_dac_clk);
            o_vex = w_realx16[dac_cycle];
        end
    end

endmodule
