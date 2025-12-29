`timescale 1ns / 1ps

module zcu216_dac
    (input  logic i_clk, i_dac_clk,
     input  logic [255:0] i_QIx8,
     output logic [13:0] o_I, o_Q,
     output real  o_vrf);

    // simulate DUC
    // if i_clk is 250MHz, simulated nco is 10MHz
    int dac_cycle;
    initial begin
        @(posedge i_clk);
        dac_cycle = 0;
        forever begin
            @(posedge i_dac_clk);
            dac_cycle = (dac_cycle == 7) ? 0 : (dac_cycle + 1);
        end
    end

    localparam IQ_WIDTH=RF_IQ_WIDTH;

    function automatic real iq2real(input int N, input logic [IQ_WIDTH-1:0] iq);
        return $itor($signed(iq)) / (1.0 * (1 << (N-1)));
    endfunction

    logic [7:0][IQ_WIDTH-1:0] w_Ix8, w_Qx8;
    for (genvar i = 0; i < 8; i++) begin : QIx8_ASSIGN
        assign w_Ix8[i] = i_QIx8[32*i+2+IQ_WIDTH-1:32*i+2];
        assign w_Qx8[i] = i_QIx8[32*i+16+2+IQ_WIDTH-1:32*i+16+2];
    end

    real I, Q;
    real deg, rad;
    initial begin
        deg = 0;
        @(posedge i_clk);
        forever begin
            @(negedge i_dac_clk);
            o_I = w_Ix8[dac_cycle];
            o_Q = w_Qx8[dac_cycle];
            I = iq2real(IQ_WIDTH, o_I);
            Q = iq2real(IQ_WIDTH, o_Q);
            deg = deg + 1.8;
            rad = deg * 3.14159265358979323846 / 180.0;
            o_vrf = I * $cos(rad) - Q * $sin(rad);
        end
    end
endmodule
