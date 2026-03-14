`timescale 1ns / 1ps

module rf_phasor_tb;

    logic w_clk, w_rst;
    logic w_set;
    logic [RF_KBC_WIDTH-1:0] w_k;
    logic [RF_KBC_WIDTH-1:0] w_b;
    logic [RF_KBC_WIDTH-1:0] w_c;

    logic w_clkx8;

    rf_phasor DUT (
        .i_clk(w_clk),
        .i_rst(w_rst),
        .i_set(w_set),
        .i_k(w_k),
        .i_b(w_b),
        .i_c(w_c),
        .o_p(),
        .i_stall(1'b0)
    );

    initial begin
        w_clk = 1'b0;
        forever #2 w_clk = !w_clk;
    end

    initial begin
        w_clkx8 = 1'b1;
        forever #0.25 w_clkx8 = !w_clkx8;
    end

    int dac_cycle;
    initial begin
        @(posedge w_clk);
        dac_cycle = 0;
        forever begin
            @(posedge w_clkx8);
            dac_cycle = (dac_cycle == 7) ? 0 : (dac_cycle + 1);
        end
    end

    logic [RF_KBC_WIDTH-1:0] n;
    logic [RF_KBC_WIDTH-1:0] w_phase_golden;
    logic w_set_golden;

    int valid;

    logic [71:0] t_n;
    logic [71:0] t1, t2, t3, t_sum;

    initial begin
        n = 0;
        valid = 1;
        forever begin
            @(posedge w_clkx8);
            if (w_set_golden)
                n = 'd0;
            else
                n++;

            // w_phase_golden = w_k * n * (n - 1) / 2 + w_b * n + w_c;

            t_n   = 72'(n + 8);
            t1    = (72'(w_k) * t_n * (t_n - 72'd1)) / 72'd2;
            t2    = 72'(w_b) * t_n;
            t3    = 72'(w_c);
            t_sum = t1 + t2 + t3;

            w_phase_golden = t_sum[35:0];
            @(negedge w_clkx8);

            if (valid && !w_set)
                assert (DUT.r_p[dac_cycle] == w_phase_golden)
                else $fatal(1, "DUT.r_p[%0d] = %0d, w_phase_golden = %0d", 
                              dac_cycle, DUT.r_p[dac_cycle], w_phase_golden);
        end
    end

    initial begin
        w_set_golden = 1'b0;
        valid = 0;
        forever begin
            @(negedge w_clkx8);
            if (w_set) begin
                @(negedge w_clkx8);
                @(negedge w_clkx8);
                @(negedge w_clkx8);
                w_set_golden = 1'b1;
                @(negedge w_clkx8);
                w_set_golden = 1'b0;
                @(negedge w_clkx8);
                @(negedge w_clkx8);
                @(negedge w_clkx8);
                valid = 1;
            end
        end
    end


    initial begin

        w_rst = 1'b1;
        @(negedge w_clk)
        w_rst = 1'b0;

        repeat (100) begin

            w_set = 1'b1;
            w_k = $urandom_range(0, 36'hFFFFFFFFF);
            w_b = $urandom_range(0, 36'hFFFFFFFFF);
            w_c = $urandom_range(0, 36'hFFFFFFFFF);

            // w_k = 36'd3436;
            // w_b = 36'd68032283687;
            // w_c = 36'h0;
            @(negedge w_clk);
            w_set = 1'b0;
            repeat (10000) @(negedge w_clk);

            // repeat (10000) begin
            //     for (int i = 0; i < 8; i++) begin
            //         assert (DUT.r_p[i] == w_k * n * (n - 1) / 2 + w_b * n + w_c)
            //         else $fatal(1, "DUT.r_p[%0d] = %0d, w_k * n * (n - 1) / 2 + w_b * n + w_c = %0d", 
            //                       i, DUT.r_p[i], w_k * n * (n - 1) / 2 + w_b * n + w_c);
            //     end
            //     @(negedge w_clk);
            // end

        end

        // w_set = 1'b1;
        // @(negedge w_clk);
        // w_set = 1'b0;
        // repeat (100) @(posedge w_clk);
        $finish;

    end
    
endmodule
