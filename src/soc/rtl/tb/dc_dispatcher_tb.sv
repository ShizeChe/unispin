`timescale 1ns / 1ps

module dc_dispatcher_tb;

    // ==========================================================
    // Parameters
    // ==========================================================
    localparam integer DAC_CHANNEL = 24;
    localparam integer FRAME_WORDS = 62;

    // ==========================================================
    // DUT Interface Signals
    // ==========================================================
    logic        clk;
    logic        rst;

    logic [31:0] fifo_data;
    logic        fifo_empty;
    logic        fifo_deq;

    logic [FRAME_WORDS-1:0][31:0] o_dc_regs;
    logic [4:0]                   o_channel_sel;
    logic                         o_valid_frame;
    logic [3:0][31:0]             o_launch_cmd;
    logic                         o_launch_valid;

    // ==========================================================
    // DUT Instance
    // ==========================================================
    dc_dispatcher #(
        .DAC_CHANNEL(DAC_CHANNEL),
        .FRAME_WORDS(FRAME_WORDS)
    ) dut (
        .i_clk(clk),
        .i_rst(rst),
        .i_fifo_data(fifo_data),
        .i_fifo_empty(fifo_empty),
        .o_fifo_deq(fifo_deq),
        .o_dc_regs(o_dc_regs),
        .o_channel_sel(o_channel_sel),
        .o_valid_frame(o_valid_frame),
        .o_launch_cmd(o_launch_cmd),
        .o_launch_valid(o_launch_valid)
    );

    // ==========================================================
    // Clock generation (100 MHz)
    // ==========================================================
    initial clk = 0;
    always #5 clk = ~clk;

    // ==========================================================
    // Simple FIFO model
    // ==========================================================
    logic [0:8191][31:0] fifo_mem;
    int rd_ptr = 0;
    int wr_ptr = 0;

    assign fifo_data  = fifo_mem[rd_ptr];
    assign fifo_empty = (rd_ptr >= wr_ptr);

    always_ff @(posedge clk) begin
        if (fifo_deq && !fifo_empty)
            rd_ptr <= rd_ptr + 1;
    end

    // ==========================================================
    // Stimulus
    // ==========================================================
    initial begin
        // Reset
        rst = 0;
        #25;
        rst = 1;
        #25;

        $display("==== Start 24-channel DC Dispatcher Simulation ====");

        // ------------------------------------------------------
        //  24 channel frames
        // ------------------------------------------------------
        for (int ch = 0; ch < DAC_CHANNEL; ch++) begin
            // Header: bit[8+ch]=0
            fifo_mem[wr_ptr++] = ~(32'h1 << (8 + ch));

            // Payload: 61 words
            for (int i = 1; i < FRAME_WORDS; i++) begin
                fifo_mem[wr_ptr++] = {8'hAA, ch[7:0], i[7:0], 8'h55};
            end
        end

        // ------------------------------------------------------
        //  Launch sequence
        // ------------------------------------------------------
        fifo_mem[wr_ptr++] = 32'hFFFF_FFFF;  // trigger header
        fifo_mem[wr_ptr++] = 32'hDEAD_BEEF;  // cmd1
        fifo_mem[wr_ptr++] = 32'hCAFEBABE;   // cmd2
        fifo_mem[wr_ptr++] = 32'h1234_5678;  // cmd3
        fifo_mem[wr_ptr++] = 32'hA5A5_A5A5;  // cmd4

        $display("[%0t] FIFO loaded with %0d words", $time, wr_ptr);

        // Wait until launch valid
        wait (o_launch_valid);
        #100;

        $display("==== Simulation Complete ====");
        $finish;
    end

    // ==========================================================
    // Monitor
    // ==========================================================
    always_ff @(posedge clk) begin
        if (o_valid_frame) begin
            $display("[%0t] Channel %0d frame done", $time, o_channel_sel);
            $display("    First word = 0x%08h, Last word = 0x%08h",
                     o_dc_regs[0], o_dc_regs[FRAME_WORDS-1]);
        end

        if (o_launch_valid) begin
            $display("[%0t] Launch command detected", $time);
            for (int i = 0; i < 4; i++)
                $display("    CMD[%0d] = 0x%08h", i, o_launch_cmd[i]);
        end
    end

    // ==========================================================
    // Waveform dump
    // ==========================================================
    initial begin
        $dumpfile("dc_dispatcher_tb.vcd");
        $dumpvars(0, dc_dispatcher_tb);
    end

endmodule
