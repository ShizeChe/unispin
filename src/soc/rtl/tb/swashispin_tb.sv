`timescale 1ns / 1ps

module swashispin_tb;

    logic [31:0] regs [0:63];
    initial begin
        $readmemb("../../sw/board/dump/dc1.txt", regs);
        for (int i = 0; i < 64; i++) begin
            $display("%b", regs[i]);
        end
    end
endmodule
