`timescale 1ns / 1ps

module bin2gray_tb;

    localparam WIDTH=4;

    logic [WIDTH-1:0] w_bin_in, w_gray, w_bin_out;

    bin2gray #(
        .WIDTH(WIDTH)
    ) DUT_B2G (
        .i_bin(w_bin_in),
        .o_gray(w_gray)
    );

    gray2bin #(
        .WIDTH(WIDTH)
    ) DUT_G2B (
        .o_bin(w_bin_out),
        .i_gray(w_gray)
    );

    initial begin
        for (int i = 0; i < 2 ** WIDTH; i++) begin
            w_bin_in = i;
            #10 $display("w_bin_in: %b, w_gray: %b, w_bin_out: %b", w_bin_in, w_gray, w_bin_out);
        end
        $finish;
    end

endmodule
