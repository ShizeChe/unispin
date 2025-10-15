`timescale 1ns / 1ps

module launch_tb;

    localparam NUM_DC_CHANNEL = 24;
    localparam NUM_RF_CHANNEL = 7;
    localparam NUM_LI_CHANNEL = 2;

    logic w_clk, w_rst;

    logic [3:0][31:0] w_regs;

    logic [NUM_DC_CHANNEL-1:0] w_dc_armed;
    logic [NUM_RF_CHANNEL-1:0] w_rf_armed;
    logic [NUM_LI_CHANNEL-1:0] w_li_armed;

    logic [NUM_DC_CHANNEL-1:0] w_dc_start;
    logic [NUM_RF_CHANNEL-1:0] w_rf_start;
    logic [NUM_LI_CHANNEL-1:0] w_li_start;

    launch #(
        .NUM_DC_CHANNEL(NUM_DC_CHANNEL),
        .NUM_RF_CHANNEL(NUM_RF_CHANNEL),
        .NUM_LI_CHANNEL(NUM_LI_CHANNEL)
    ) dut (
        .i_clk(w_clk),
        .i_rst(w_rst),
        .i_regs(w_regs),
        .i_dc_armed(w_dc_armed),
        .i_rf_armed(w_rf_armed),
        .i_li_armed(w_li_armed),
        .o_dc_start(w_dc_start),
        .o_rf_start(w_rf_start),
        .o_li_start(w_li_start)
    );

    initial begin
        w_clk = 1'b0;
        forever #5 w_clk = !w_clk;
    end

    // dc
    for (genvar i = 0; i < NUM_DC_CHANNEL; i++) begin

        initial begin

            forever begin

                @(negedge w_clk);

                if (dut.w_new_stream && w_regs[0][i]) begin

                    repeat($urandom_range(0, 100)) @(negedge w_clk);

                    w_dc_armed[i] = 1'b1;
                    wait(w_dc_start[i]);

                    assert(w_dc_start == w_dc_armed)
                    else $fatal(0, "At %0.3f ns, dc%d found w_dc_armed=%b, w_dc_start=%b\n", 
                                $realtime, i, w_dc_armed, w_dc_start);

                    @(posedge w_clk);
                    w_dc_armed[i] = 1'b0;

                    @(negedge w_clk);
                    assert(w_dc_start == 'h0)
                    else $fatal(0, "At %0.3f ns, dc%d found w_dc_start=%b, should be 0\n", 
                                $realtime, i, w_dc_start);

                end

            end

        end

    end

    // rf
    for (genvar i = 0; i < NUM_RF_CHANNEL; i++) begin

        initial begin

            forever begin

                @(negedge w_clk);

                if (dut.w_new_stream && w_regs[1][i]) begin

                    repeat($urandom_range(0, 100)) @(negedge w_clk);

                    w_rf_armed[i] = 1'b1;
                    wait(w_rf_start[i]);

                    assert(w_rf_start == w_rf_armed)
                    else $fatal(0, "At %0.3f ns, rf%d found w_rf_armed=%b, w_rf_start=%b\n", 
                                $realtime, i, w_rf_armed, w_rf_start);

                    @(posedge w_clk);
                    w_rf_armed[i] = 1'b0;

                    @(negedge w_clk);
                    assert(w_rf_start == 'h0)
                    else $fatal(0, "At %0.3f ns, rf%d found w_rf_start=%b, should be 0\n", 
                                $realtime, i, w_rf_start);

                end

            end

        end

    end

    // li
    for (genvar i = 0; i < NUM_LI_CHANNEL; i++) begin

        initial begin

            forever begin

                @(negedge w_clk);

                if (dut.w_new_stream && w_regs[2][i]) begin

                    repeat($urandom_range(0, 100)) @(negedge w_clk);

                    w_li_armed[i] = 1'b1;
                    wait(w_li_start[i]);

                    assert(w_li_start == w_li_armed)
                    else $fatal(0, "At %0.3f ns, li%d found w_li_armed=%b, w_li_start=%b\n", 
                                $realtime, i, w_li_armed, w_li_start);

                    @(posedge w_clk);
                    w_li_armed[i] = 1'b0;

                    @(negedge w_clk);
                    assert(w_li_start == 'h0)
                    else $fatal(0, "At %0.3f ns, li%d found w_li_start=%b, should be 0\n", 
                                $realtime, i, w_li_start);

                end

            end

        end

    end

    logic [NUM_DC_CHANNEL-1:0] rand_dc_mask;
    logic [NUM_RF_CHANNEL-1:0] rand_rf_mask;
    logic [NUM_LI_CHANNEL-1:0] rand_li_mask;

    int NUM_ITERS = 10000;

    initial begin
        w_rst = 1'b1;
        w_regs = 'h0;
        w_dc_armed = 'h0;
        w_rf_armed = 'h0;
        w_li_armed = 'h0;
        @(negedge w_clk);
        w_rst = 1'b0;

        repeat (NUM_ITERS) begin

            rand_dc_mask = $urandom;
            rand_rf_mask = $urandom;
            rand_li_mask = $urandom;
            w_regs[0][NUM_DC_CHANNEL-1:0] = rand_dc_mask;
            w_regs[1][NUM_RF_CHANNEL-1:0] = rand_rf_mask;
            w_regs[2][NUM_LI_CHANNEL-1:0] = rand_li_mask;
            w_regs[3] = 'd1;

            wait(dut.w_new_stream);
            @(posedge w_clk);
            @(negedge w_clk);
            assert(dut.r_state == dut.LAUNCH)
            else $fatal(0, "At 0.3f ns, state should be LAUNCH\n", $realtime);

            wait(dut.r_state == dut.IDLE);
            w_regs[3] = 'h0;

            repeat ($urandom_range(2, 10)) @(negedge w_clk);

        end

        $finish;

    end


endmodule
