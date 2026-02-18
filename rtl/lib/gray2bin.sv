module gray2bin
   #(parameter WIDTH=8)
    (input  logic [WIDTH-1:0] i_gray,
     output logic [WIDTH-1:0] o_bin);

    assign o_bin[WIDTH-1] = i_gray[WIDTH-1];
    for (genvar i = WIDTH-2; i >= 0; i--) begin : B2G_GEN
        assign o_bin[i] = o_bin[i+1] ^ i_gray[i];
    end

endmodule
