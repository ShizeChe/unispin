module spi_master_tb;
    logic w_clk, w_rst;

    logic [15:0] w_din;
    logic [15:0] w_dout;
    logic w_start;
    logic w_done;

    logic [15:0] w_dvsr;

    logic w_miso;
    logic w_mosi;
    logic w_sclk;

    spi_master #(
        .DATA_WIDTH(16),
        .SCLK_POLARITY(0),
        .SCLK_PHASE(0)
    ) dut (
        .i_clk(w_clk),
        .i_rst(w_rst),
        .i_din(w_din),
        .o_dout(w_dout),
        .i_start(w_start),
        .o_done(w_done),
        .i_dvsr('d868),
        .i_miso(w_miso),
        .o_mosi(w_mosi),
        .o_sclk(w_sclk)
    );

    initial begin
        w_clk = 1'b0;
        forever #5 w_clk = !w_clk;
    end

    logic [15:0] master_send, slave_recv, slave_send;
    initial begin

        forever begin

            slave_send = $urandom_range(0, 16'hFFFF);

            for (int i = 15; i >= 0; i--) begin

                w_miso = slave_send[i];

                @(posedge w_sclk);
                @(negedge w_clk);
                slave_recv[i] = w_mosi;

                @(negedge w_sclk);
                @(negedge w_clk);

            end

        end

    end

    int NUM_ITERS = 10000;
    initial begin

        w_rst = 1'b1;
        @(negedge w_clk);
        w_rst = 1'b0;

        repeat (NUM_ITERS) begin

            master_send = $urandom_range(0, 16'hFFFF);

            @(negedge w_clk);
            w_din = master_send;
            w_start = 1'b1;
            @(negedge w_clk);
            w_din = 'd0;
            w_start = 1'b0;

            wait(w_done == 1'b1);
            @(negedge w_clk);

            assert (master_send == slave_recv) else
            $fatal("At %0.3f ns: master_send = %0h, slave_recv = %0h, wrong",
                   $realtime, master_send, slave_recv);
            assert (slave_send == w_dout) else
            $fatal("At %0.3f ns: slave_send = %0h, w_dout = %0h, wrong",
                   $realtime, slave_send, w_dout);
                   
            /* $display("At %0.3f ns: master_send = %0h, slave_recv = %0h, correct",
                     $realtime, master_send, slave_recv);
            $display("At %0.3f ns: slave_send = %0h, w_dout = %0h, correct",
                     $realtime, slave_send, w_dout); */

        end

        $finish;

    end

endmodule
