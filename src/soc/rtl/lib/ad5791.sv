`timescale

module ad5791
    (input  logic i_sclk,
     input  logic i_mosi,
     input  logic i_cs_n,
     input  logic i_ldac_n,

     output logic [20:0] o_vdc);

    // mimic ad5791
    logic [19:0] ad5791a_spi_reg;
    logic [19:0] ad5791a_dac_reg;

    always_ff @(negedge i_ldac_n) begin
        ad5791a_dac_reg <= ad5791a_spi_reg;
    end

    initial begin
        forever begin
            @(negedge i_cs_n);
            for (int i = 19; i >= 0; i--) begin
                @(posedge i_sclk);
                ad5791a_spi_reg[i] = i_mosi;
            end
        end
    end

    assign o_vdc = ad5791a_dac_reg;

endmodule
