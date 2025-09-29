`timescale 1ns / 1ps

module parabolic_counter_tb;

    logic w_clk, w_rst;
    logic w_set;
    logic [31:0] w_k;
    logic [31:0] w_b;
    logic [31:0] w_c;

    parabolic_counterx8 dut (
        .i_clk(w_clk),
        .i_rst(w_rst),
        .i_set(w_set),
        .i_k(w_k),
        .i_b(w_b),
        .i_c(w_c),
        .o_p()
    );

    initial begin
        w_clk = 1'b0;
        forever #5 w_clk = !w_clk;
    end

    logic [31:0] n, m;

    initial begin

        w_rst = 1'b1;
        @(negedge w_clk)
        w_rst = 1'b0;

        m = 'd0;
        w_set = 1'b1;
        w_k = 'd2;
        w_b = 'd3;
        w_c = 'd4;
        @(negedge w_clk);
        w_set = 1'b0;

        repeat (100) begin
            for (int i = 0; i < 8; i++) begin
                n = m * 8 + i;
                assert (dut.r_p[i] == w_k * n * (n - 1) / 2 + w_b * n + w_c)
                else $display("dut.r_p[%0d] = %0d, w_k * n * (n - 1) / 2 + w_b * n + w_c = %0d", 
                              i, dut.r_p[i], w_k * n * (n - 1) / 2 + w_b * n + w_c);
            end
            m = m + 'd1;
            @(negedge w_clk);
        end
        $finish;

    end
    
endmodule
