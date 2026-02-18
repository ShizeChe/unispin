module bin2gray
   #(parameter WIDTH=8)
    (input  logic [WIDTH-1:0] i_bin,
     output logic [WIDTH-1:0] o_gray);

    assign o_gray[WIDTH-1] = i_bin[WIDTH-1];
    for (genvar i = WIDTH-2; i >= 0; i--) begin : B2G_GEN
        assign o_gray[i] = i_bin[i+1] ^ i_bin[i];
    end

endmodule
