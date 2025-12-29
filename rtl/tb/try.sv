module try;
    logic [0:3][3:0] w_regs;
    initial begin
        w_regs[0] = 4'h1;
        w_regs[1] = 4'h2;
        w_regs[2] = 4'h3;
        w_regs[3] = 4'h4;
        $display("w_regs[0:3]=%0h", w_regs[0:3]);
        $display("{w_regs[0:3]}=%0h", {w_regs[0:3]});

        w_regs[0:3] = 16'hABCD;
        $display("w_regs[0:3]=%0h", w_regs[0:3]);
        $display("{w_regs[0:3]}=%0h", {w_regs[0:3]});
    end
endmodule
