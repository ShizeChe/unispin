`timescale 1ns / 1ps

module ad4451a
    (input  logic i_sclk,
     input  logic i_mosi,
     input  logic i_cs_n,
     input  logic i_ldac_n,

     output logic [15:0] o_vdc);

    // mimic ad4451a
    logic [15:0] ad4451a_spi_reg;
    logic [15:0] ad4451a_dac_reg;

    always_ff @(negedge i_ldac_n) begin
        ad4451a_dac_reg <= ad4451a_spi_reg;
    end

    initial begin
        forever begin
            @(negedge i_cs_n);
            for (int i = 15; i >= 0; i--) begin
                @(posedge i_sclk);
                ad4451a_spi_reg[i] = i_mosi;
            end
        end
    end

    assign o_vdc = ad4451a_dac_reg;

endmodule
