`timescale 1ns / 1ps

module rf_core_tb;

    localparam KBC_WIDTH=36;
    localparam NUM_SAMPLE_WIDTH=30;
    localparam CORE_ITER_WIDTH=10;
    localparam INSN_WIDTH=KBC_WIDTH*3+CORE_ITER_WIDTH+NUM_SAMPLE_WIDTH*4;
    localparam IQ_WIDTH=14;
    localparam DAC_WIDTH=16;
    localparam PHASE_WIDTH=18;
    localparam CORDIC_STAGES=15;
    localparam CORDIC_PAD_ZEROS=8;

    localparam INSN_BUF_DEPTH=16;
    localparam IPTR_WIDTH=$clog2(INSN_BUF_DEPTH);
    localparam IPTR_BUF_DEPTH=1024;
    localparam INSN_REGS=(INSN_WIDTH+31)/32*INSN_BUF_DEPTH;
    localparam IPTR_REGS=(1024+32/IPTR_WIDTH-1)/(32/IPTR_WIDTH);
    localparam STREAM_ITER_WIDTH=10;
    localparam TOTAL_REGS=INSN_REGS+IPTR_REGS+2;

    localparam REG_PER_INSN = (INSN_WIDTH + 31) / 32;
    localparam IPTR_PER_REG = 32 / IPTR_WIDTH;

    logic w_clk, w_rst;
    logic [INSN_WIDTH-1:0] w_insn;
    logic w_next;
    logic w_empty;
    logic [DAC_WIDTH*16-1:0] w_QIx8;
    logic w_start;
    logic w_armed;
    logic [TOTAL_REGS-1:0][31:0] w_regs;

    rf_stream #(
        .INSN_WIDTH(INSN_WIDTH),
        .INSN_BUF_DEPTH(INSN_BUF_DEPTH),
        .IPTR_BUF_DEPTH(IPTR_BUF_DEPTH),
        .ITER_WIDTH(STREAM_ITER_WIDTH)
    ) stream (
        .i_clk(w_clk),
        .i_rst(w_rst),
        .i_regs(w_regs),
        .i_next(w_next),
        .o_empty(w_empty),
        .o_insn(w_insn)
    );

    rf_core #(
    	.KBC_WIDTH(KBC_WIDTH),
    	.NUM_SAMPLE_WIDTH(NUM_SAMPLE_WIDTH),
    	.ITER_WIDTH(CORE_ITER_WIDTH),
        .IQ_WIDTH(IQ_WIDTH),
    	.DAC_WIDTH(DAC_WIDTH),
    	.PHASE_WIDTH(PHASE_WIDTH),
    	.CORDIC_STAGES(CORDIC_STAGES),
    	.CORDIC_PAD_ZEROS(CORDIC_PAD_ZEROS)
    ) core (
        .i_clk(w_clk),
        .i_rst(w_rst),
        .i_insn(w_insn),
        .o_next(w_next),
        .i_empty(w_empty),
        .o_QIx8(w_QIx8),
        .i_start(w_start),
        .o_armed(w_armed)
    );

    initial begin
        w_clk = 1'b0;
        forever #2 w_clk = !w_clk;
    end

    logic w_dac_clk;

    initial begin
        w_dac_clk = 1'b1;
        forever #0.25 w_dac_clk = !w_dac_clk;
    end

    // simulate DUC with 10MHz
    int dac_cycle;
    initial begin
        @(posedge w_clk);
        dac_cycle = 0;
        forever begin
            @(posedge w_dac_clk);
            dac_cycle = (dac_cycle == 7) ? 0 : (dac_cycle + 1);
        end
    end

    function automatic real iq2real(input int N, input logic [IQ_WIDTH-1:0] iq);
        return $itor($signed(iq)) / (1.0 * (1 << (N-1)));
    endfunction

    logic [7:0][IQ_WIDTH-1:0] w_Ix8, w_Qx8;
    for (genvar i = 0; i < 8; i++) begin
        assign w_Ix8[i] = w_QIx8[
            DAC_WIDTH*2*i+IQ_WIDTH-1:DAC_WIDTH*2*i
        ];
        assign w_Qx8[i] = w_QIx8[
            DAC_WIDTH*(2*i+1)+IQ_WIDTH-1:DAC_WIDTH*(2*i+1)
        ];
    end

    real I, Q;
    real deg, rad, out;
    // logic [PHASE_WIDTH:0] w_phase;
    // logic [PHASE_WIDTH*2-1:0] w_phase_full;
    logic [IQ_WIDTH-1:0] w_I, w_Q;
    initial begin
        deg = 0;
        @(posedge w_clk);
        forever begin
            @(negedge w_dac_clk);
            w_I = w_Ix8[dac_cycle];
            w_Q = w_Qx8[dac_cycle];
            // w_phase = w_phasex8[dac_cycle];
            // w_phase_full = phase_counter.r_p[dac_cycle];
            I = iq2real(IQ_WIDTH, w_I);
            Q = iq2real(IQ_WIDTH, w_Q);
            deg = deg + 1.8;
            rad = deg * 3.14159265358979323846 / 180.0;
            out = I * $cos(rad) - Q * $sin(rad);
        end
    end

    task kbc0(
        input logic [CORE_ITER_WIDTH] iters,
        input logic [NUM_SAMPLE_WIDTH-1:0] kbcs, dkbcs,
        input logic [NUM_SAMPLE_WIDTH-1:0] zeros, dzeros);

        w_regs[REG_PER_INSN-1:0] = {
            {(REG_PER_INSN * 32 - INSN_WIDTH){1'b0}},
            {(KBC_WIDTH * 3){1'b0}},
            iters,
            dkbcs, kbcs,
            dzeros, zeros
        };

        for (int i = REG_PER_INSN; i < TOTAL_REGS - 2; i++)
            w_regs[i] = 'h0;

        w_regs[TOTAL_REGS - 2] = {
            {(32 - STREAM_ITER_WIDTH - $clog2(INSN_BUF_DEPTH)){1'b0}},
            $clog2(INSN_BUF_DEPTH)'('d0),
            STREAM_ITER_WIDTH'('d1)
        };
        w_regs[TOTAL_REGS - 1] = 'd1;

        wait(w_armed);
        repeat(3) @(negedge w_clk);
        w_regs[TOTAL_REGS - 1] = 'd0;
        w_start = 1'b1;
        @(negedge w_clk);
        w_start = 1'b0;

    endtask

    task phase_shift;
        w_regs[REG_PER_INSN-1:0] = {
            {(REG_PER_INSN * 32 - INSN_WIDTH){1'b0}},
            {(KBC_WIDTH * 3){1'b0}},
            CORE_ITER_WIDTH'('d0),
            NUM_SAMPLE_WIDTH'(1024), NUM_SAMPLE_WIDTH'(1024),
            NUM_SAMPLE_WIDTH'(0), NUM_SAMPLE_WIDTH'(0) 
        };
        w_regs[REG_PER_INSN*2-1:REG_PER_INSN] = {
            {(REG_PER_INSN * 32 - INSN_WIDTH){1'b0}},
            {(KBC_WIDTH){1'b0}},
            {(KBC_WIDTH){1'b0}},
            2'b00,
            {(KBC_WIDTH-2){1'b1}},
            CORE_ITER_WIDTH'('d0),
            NUM_SAMPLE_WIDTH'(1024), NUM_SAMPLE_WIDTH'(1024),
            NUM_SAMPLE_WIDTH'(0), NUM_SAMPLE_WIDTH'(0) 
        };

        for (int i = 2 * REG_PER_INSN; i < INSN_REGS; i++)
            w_regs[i] = 'h0;

        w_regs[INSN_REGS] = 32'h0010;
        for (int i = INSN_REGS + 1; i < TOTAL_REGS - 2; i++)
            w_regs[i] = 'h0;

        w_regs[TOTAL_REGS - 2] = {
            {(32 - STREAM_ITER_WIDTH - $clog2(INSN_BUF_DEPTH)){1'b0}},
            $clog2(INSN_BUF_DEPTH)'('d1),
            STREAM_ITER_WIDTH'('d1)
        };
        w_regs[TOTAL_REGS - 1] = 'd1;

        wait(w_armed);
        repeat(3) @(negedge w_clk);
        w_regs[TOTAL_REGS - 1] = 'd0;
        w_start = 1'b1;
        @(negedge w_clk);
        w_start = 1'b0;

    endtask

    initial begin
        w_rst = 1'b1;
        w_regs = 'h0;
        w_start = 1'b0;
        @(negedge w_clk);
        w_rst = 1'b0;

        // kbc0('d3, 'd9, 'd0, 'd7, 'd0);
        // repeat (25) @(posedge w_clk);
        //
        // kbc0('d3, 'd7, 'd0, 'd9, 'd0);
        // repeat (25) @(posedge w_clk);
        //
        // kbc0('d3, 'd8, 'd0, 'd0, 'd0);
        // repeat (25) @(posedge w_clk);
        //
        // kbc0('d3, 'd0, 'd0, 'd8, 'd0);
        // repeat (25) @(posedge w_clk);

        // kbc0('d10, 'd64, 'd64, 'd512, 'd64);
        // wait(core.w_propagate_bubble);
        // repeat (3) @(posedge w_clk);

        phase_shift;
        wait(core.w_propagate_bubble);
        repeat (3) @(posedge w_clk);

        $finish;
    end

endmodule
