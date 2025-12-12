`timescale 1ns / 1ps

module dc_core_tb;

    localparam CHANNELS = 2;

    localparam DAC_WIDTH=20;
    localparam CYCLE_WIDTH=30;
    localparam ITER_WIDTH=10;
    localparam INSN_WIDTH=DAC_WIDTH*2+ITER_WIDTH+CYCLE_WIDTH;
    localparam DEPTH=20;
    localparam NUM_REG=DEPTH*3+2;

    logic w_clk, w_rst;

    logic [NUM_REG-1:0][31:0] w_regs [0:CHANNELS-1];
    logic [INSN_WIDTH-1:0] w_insn [0:CHANNELS-1];
    logic [CHANNELS-1:0] w_next;
    logic [CHANNELS-1:0] w_empty;
    logic [CHANNELS-1:0] w_valid;

    logic [CHANNELS-1:0] w_sclk;
    logic [CHANNELS-1:0] w_mosi;
    logic [CHANNELS-1:0] w_cs_n;
    logic [CHANNELS-1:0] w_ldac_n;

    logic [CHANNELS-1:0] w_core_start;
    logic [CHANNELS-1:0] w_core_armed;

    for (genvar i = 0; i < CHANNELS; i++) begin
        dc_stream #(
            .INSN_WIDTH(INSN_WIDTH),
            .ITER_WIDTH(ITER_WIDTH),
            .DEPTH(DEPTH)
        ) stream (
            .i_clk(w_clk),
            .i_rst(w_rst),
            .i_regs(w_regs[i]),
            .i_next(w_next[i]),
            .o_empty(w_empty[i]),
            .o_insn(w_insn[i])
        );

        dc_core #(
            .DAC_WIDTH(DAC_WIDTH),
            .CYCLE_WIDTH(CYCLE_WIDTH),
            .ITER_WIDTH(ITER_WIDTH)
        ) core (
            .i_clk(w_clk),
            .i_rst(w_rst),
            .i_insn(w_insn[i]),
            .o_next(w_next[i]),
            .i_empty(w_empty[i]),
            .o_sclk(w_sclk[i]),
            .o_mosi(w_mosi[i]),
            .o_cs_n(w_cs_n[i]),
            .o_ldac_n(w_ldac_n[i]),
            .i_start(w_core_start[i]),
            .o_armed(w_core_armed[i])
        );
    end

    // mimic ad5791
    logic [DAC_WIDTH-1:0] ad5791_spi_reg [0:CHANNELS-1];
    logic [DAC_WIDTH-1:0] ad5791_dac_reg [0:CHANNELS-1];

    for (genvar i = 0; i < CHANNELS; i++) begin

        always_ff @(negedge w_ldac_n[i]) begin
            ad5791_dac_reg[i] <= ad5791_spi_reg[i];
        end

        initial begin
            forever begin
                @(negedge w_cs_n[i]);
                for (int j = DAC_WIDTH-1; j >= 0; j--) begin
                    @(posedge w_sclk[i]);
                    ad5791_spi_reg[i][j] = w_mosi[i];
                end
            end
        end

    end

    initial begin
        w_clk = 1'b0;
        forever #5 w_clk = !w_clk;
    end

    task clear;
        for (int ch = 0; ch < CHANNELS; ch++) begin
            w_regs[ch] = 'h0;
            w_core_start[ch] = 1'b0;
        end
    endtask

    logic [DAC_WIDTH-1:0] v[CHANNELS];

    int ch;
    logic [INSN_WIDTH-1:0] insn;

    task sweep_1d(
        input int ch_arr[],
        input logic [DAC_WIDTH-1:0] vstart_arr[],
        input logic [DAC_WIDTH-1:0] dv_arr[],
        input logic [ITER_WIDTH-1:0] steps,
        input logic [DAC_WIDTH-1:0] step_cycles);

        @(negedge w_clk);

        for (int i = 0; i < ch_arr.size(); i++) begin

            ch = ch_arr[i];

            insn = {dv_arr[i], steps, vstart_arr[i], step_cycles - CYCLE_WIDTH'('d1)};

            {w_regs[ch][2], w_regs[ch][1], w_regs[ch][0]} = {{(96-INSN_WIDTH){1'b0}}, insn};

            for (int j = 3; j < DEPTH*3; j++)
                w_regs[ch][j] = 'h0;

            w_regs[ch][DEPTH*3] = 'd1;
            w_regs[ch][DEPTH*3+1] = 'd1;

        end

        repeat (3) @(negedge w_clk);

        @(negedge w_clk);
        clear;

        for (int i = 0; i < ch_arr.size(); i++) begin
            ch = ch_arr[i];
            wait(w_core_armed[ch]);
        end

        @(negedge w_clk);
        for (int i = 0; i < ch_arr.size(); i++) begin
            ch = ch_arr[i];
            w_core_start[ch] = 1'b1;
        end
        @(negedge w_clk);
        for (int i = 0; i < ch_arr.size(); i++) begin
            ch = ch_arr[i];
            w_core_start[ch] = 1'b0;
        end

        @(posedge w_clk);

        // dac sweep should start here
        for (int i = 0; i < ch_arr.size(); i++) begin
            ch = ch_arr[i];
            v[ch] = vstart_arr[i];
        end

        repeat (steps) begin
            repeat (step_cycles) begin
                @(negedge w_clk);
                for (int i = 0; i < ch_arr.size(); i++) begin
                    ch = ch_arr[i];
                    assert (ad5791_dac_reg[ch] == v[ch])
                    else $fatal(1, "ad5791_dac_reg[%0d]=%0h, v=%0h", ch, ad5791_dac_reg[ch], v[ch]);
                end
            end
            for (int i = 0; i < ch_arr.size(); i++) begin
                ch = ch_arr[i];
                v[ch] = v[ch] + dv_arr[i];
            end
        end

        for (int i = 0; i < ch_arr.size(); i++) begin
            ch = ch_arr[i];
            v[ch] = v[ch] - dv_arr[i];
        end

        repeat(10) @(posedge w_clk);

        for (int i = 0; i < ch_arr.size(); i++) begin
            ch = ch_arr[i];
            assert (ad5791_dac_reg[ch] == v[ch])
            else $fatal(1, "ad5791_dac_reg[%0d]=%0h, v=%0h", ch, ad5791_dac_reg[ch], v[ch]);
        end

    endtask

    task sweep_2d(
        input int ch_arr1[],
        input logic [DAC_WIDTH-1:0] vstart_arr1[],
        input logic [DAC_WIDTH-1:0] dv_arr1[],
        input int ch_arr2[],
        input logic [DAC_WIDTH-1:0] vstart_arr2[],
        input logic [DAC_WIDTH-1:0] dv_arr2[],
        input logic [ITER_WIDTH-1:0] steps1, steps2,
        input logic [CYCLE_WIDTH-1:0] step_cycles2);

        @(negedge w_clk);

        for (int i = 0; i < ch_arr1.size(); i++) begin

            ch = ch_arr1[i];

            insn = {dv_arr1[i], steps1, vstart_arr1[i], step_cycles2 * steps2 - CYCLE_WIDTH'('d1)};

            {w_regs[ch][2], w_regs[ch][1], w_regs[ch][0]} = {{(96-INSN_WIDTH){1'b0}}, insn};

            for (int j = 3; j < DEPTH*3; j++)
                w_regs[ch][j] = 'h0;

            w_regs[ch][DEPTH*3] = 'd1;
            w_regs[ch][DEPTH*3+1] = 'd1;

        end
        for (int i = 0; i < ch_arr2.size(); i++) begin

            ch = ch_arr2[i];

            insn = {dv_arr2[i], steps2, vstart_arr2[i], step_cycles2 - CYCLE_WIDTH'('d1)};

            {w_regs[ch][2], w_regs[ch][1], w_regs[ch][0]} = {{(96-INSN_WIDTH){1'b0}}, insn};

            for (int j = 3; j < DEPTH*3; j++)
                w_regs[ch][j] = 'h0;

            w_regs[ch][DEPTH*3] = steps1;
            w_regs[ch][DEPTH*3+1] = 'd1;

        end

        repeat (3) @(negedge w_clk);

        @(negedge w_clk);
        clear;

        for (int i = 0; i < ch_arr1.size(); i++) begin
            ch = ch_arr1[i];
            $display("wait ch=%0d armed", ch);
            wait(w_core_armed[ch]);
        end
        for (int i = 0; i < ch_arr2.size(); i++) begin
            ch = ch_arr2[i];
            $display("wait ch=%0d armed", ch);
            wait(w_core_armed[ch]);
        end

        @(negedge w_clk);
        for (int i = 0; i < ch_arr1.size(); i++) begin
            ch = ch_arr1[i];
            w_core_start[ch] = 1'b1;
        end
        for (int i = 0; i < ch_arr2.size(); i++) begin
            ch = ch_arr2[i];
            w_core_start[ch] = 1'b1;
        end
        @(negedge w_clk);
        for (int i = 0; i < ch_arr1.size(); i++) begin
            ch = ch_arr1[i];
            w_core_start[ch] = 1'b0;
        end
        for (int i = 0; i < ch_arr2.size(); i++) begin
            ch = ch_arr2[i];
            w_core_start[ch] = 1'b0;
        end

        @(posedge w_clk);

        // dac sweep should start here
        for (int i = 0; i < ch_arr1.size(); i++) begin
            ch = ch_arr1[i];
            v[ch] = vstart_arr1[i];
        end

        repeat (steps1) begin

            for (int i = 0; i < ch_arr2.size(); i++) begin
                ch = ch_arr2[i];
                v[ch] = vstart_arr2[i];
            end

            repeat (steps2) begin

                repeat (step_cycles2) begin

                    @(negedge w_clk);
                    for (int i = 0; i < ch_arr1.size(); i++) begin
                        ch = ch_arr1[i];
                        assert (ad5791_dac_reg[ch] == v[ch])
                        else $fatal(1, "ad5791_dac_reg[%0d]=%0h, v=%0h", ch, ad5791_dac_reg[ch], v[ch]);
                    end
                    for (int i = 0; i < ch_arr2.size(); i++) begin
                        ch = ch_arr2[i];
                        assert (ad5791_dac_reg[ch] == v[ch])
                        else $fatal(1, "ad5791_dac_reg[%0d]=%0h, v=%0h", ch, ad5791_dac_reg[ch], v[ch]);
                    end

                end

                for (int i = 0; i < ch_arr2.size(); i++) begin
                    ch = ch_arr2[i];
                    v[ch] = v[ch] + dv_arr2[i];
                end

            end

            for (int i = 0; i < ch_arr1.size(); i++) begin
                ch = ch_arr1[i];
                v[ch] = v[ch] + dv_arr1[i];
            end

        end


        for (int i = 0; i < ch_arr1.size(); i++) begin
            ch = ch_arr1[i];
            v[ch] = v[ch] - dv_arr1[i];
        end
        for (int i = 0; i < ch_arr2.size(); i++) begin
            ch = ch_arr2[i];
            v[ch] = v[ch] - dv_arr2[i];
        end

        repeat(10) @(posedge w_clk);

        for (int i = 0; i < ch_arr1.size(); i++) begin
            ch = ch_arr1[i];
            assert (ad5791_dac_reg[ch] == v[ch])
            else $fatal(1, "ad5791_dac_reg[%0d]=%0h, v=%0h", ch, ad5791_dac_reg[ch], v[ch]);
        end
        for (int i = 0; i < ch_arr2.size(); i++) begin
            ch = ch_arr2[i];
            assert (ad5791_dac_reg[ch] == v[ch])
            else $fatal(1, "ad5791_dac_reg[%0d]=%0h, v=%0h", ch, ad5791_dac_reg[ch], v[ch]);
        end

    endtask

    int chx2_arr[];

    int ch_arr1[];
    logic [DAC_WIDTH-1:0] vstart_arr1[];
    logic [DAC_WIDTH-1:0] dv_arr1[];
    logic [ITER_WIDTH-1:0] steps1;
    logic [DAC_WIDTH-1:0] step_cycles1;

    int ch_arr2[];
    logic [DAC_WIDTH-1:0] vstart_arr2[];
    logic [DAC_WIDTH-1:0] dv_arr2[];
    logic [ITER_WIDTH-1:0] steps2;
    logic [DAC_WIDTH-1:0] step_cycles2;

    function automatic void rand_ch_arr(int n, int m, output int subset[]);
        int arr[];
        arr = new[n];
        foreach (arr[i]) arr[i] = i;

        // shuffle (Fisher–Yates)
        for (int i = n-1; i > 0; i--) begin
        int j = $urandom_range(0, i);
        int tmp = arr[i];
        arr[i] = arr[j];
        arr[j] = tmp;
        end

        // take first m
        subset = new[m];
        for (int i = 0; i < m; i++) subset[i] = arr[i];
    endfunction

    localparam NUM_ITERS = 10;

    int m;

    task random_sweep_1d;
        repeat (NUM_ITERS) begin
            m = $urandom_range(1, CHANNELS);

            rand_ch_arr(CHANNELS, m, ch_arr1);
            vstart_arr1 = new[m];
            dv_arr1 = new[m];

            for (int i = 0; i < m; i++) begin
                vstart_arr1[i] = $urandom_range(0, 16'hffff);
                dv_arr1[i] = $urandom_range(0, 16'hffff);
            end

            steps1 = $urandom_range(1, 10'h3ff);
            step_cycles1 = $urandom_range(16'd70, 16'hfff);

            $display("ch_arr1: %p", ch_arr1);
            $display("vstart_arr1: %p", vstart_arr1);
            $display("dv_arr1: %p", dv_arr1);
            $display("steps1: %0h", steps1);
            $display("step_cycles1: %0h\n", step_cycles1);

            sweep_1d(ch_arr1, vstart_arr1, dv_arr1, steps1, step_cycles1);

            repeat ($urandom_range(0, 'd1000)) @(posedge w_clk);
        end
    endtask

    task random_sweep_2d;
        repeat (NUM_ITERS) begin
            m = $urandom_range(2, CHANNELS);
            $display("m: %0d", m);

            rand_ch_arr(CHANNELS, m, chx2_arr);
            $display("chx2_arr: %p", chx2_arr);

            ch_arr1 = new[m/2];
            for (int i = 0; i < m / 2; i++) begin
                ch_arr1[i] = chx2_arr[i];
            end
            ch_arr2 = new[m/2];
            for (int i = m / 2; i < m; i++) begin
                ch_arr2[i - m/2] = chx2_arr[i];
            end

            vstart_arr1 = new[m/2];
            dv_arr1 = new[m/2];
            vstart_arr2 = new[m/2];
            dv_arr2 = new[m/2];

            for (int i = 0; i < m; i++) begin
                vstart_arr1[i] = $urandom_range(0, 16'hffff);
                dv_arr1[i] = $urandom_range(0, 16'hffff);
                vstart_arr2[i] = $urandom_range(0, 16'hffff);
                dv_arr2[i] = $urandom_range(0, 16'hffff);
            end

            steps1 = $urandom_range(1, 10'd100);
            steps2 = $urandom_range(1, 10'd100);
            step_cycles2 = $urandom_range(30'd70, 30'd10000);

            $display("ch_arr1: %p", ch_arr1);
            $display("vstart_arr1: %p", vstart_arr1);
            $display("dv_arr1: %p", dv_arr1);
            $display("ch_arr2: %p", ch_arr2);
            $display("vstart_arr2: %p", vstart_arr2);
            $display("dv_arr2: %p", dv_arr2);
            $display("steps1: %0d", steps1);
            $display("steps2: %0d", steps2);
            $display("step_cycles2: %0d", step_cycles2);

            sweep_2d(ch_arr1, vstart_arr1, dv_arr1, 
                     ch_arr2, vstart_arr2, dv_arr2,
                     steps1, steps2, step_cycles2);

            repeat ($urandom_range(0, 'd1000)) @(posedge w_clk);
        end
    endtask

    // 1d sweep
    initial begin
        clear;
        w_rst = 1'b1;
        @(negedge w_clk);
        w_rst = 1'b0;

        random_sweep_1d;
        random_sweep_2d;
        // ch_arr1 = {0};
        // vstart_arr1 = {'h0};
        // dv_arr1 = {'h100};
        // ch_arr2 = {1};
        // vstart_arr2 = {'h0};
        // dv_arr2 = {'h100};
        // steps1 = 'd50;
        // steps2 = 'd50;
        // step_cycles2 = 'd100;
        // sweep_2d(ch_arr1, vstart_arr1, dv_arr1,
        //          ch_arr2, vstart_arr2, dv_arr2,
        //          steps1, steps2, step_cycles2);
        random_sweep_2d;
        $finish;
    end

endmodule
