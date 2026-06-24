`timescale 1ns / 1ps

module baudx16_generator
    (input  logic        i_clk, i_rst,
     input  logic [10:0] i_dvsr,
     output logic        o_sample_tick);

    logic [10:0] r_counter;
    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            r_counter <= 'd0;
        end
        else if (r_counter == i_dvsr) begin
            r_counter <= 'd0;
        end
        else begin
            r_counter <= r_counter + 'd1;
        end
    end

    assign o_sample_tick = (r_counter == 'd1);

endmodule
