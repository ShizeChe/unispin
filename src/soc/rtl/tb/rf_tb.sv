`timescale 1ns / 1ps
`include "include/internal.svh"

module rf_tb;

    logic w_clk, w_rst;
    logic [RF_INSN_WIDTH-1:0] w_insn;
    logic [RF_INSN_WIDTH-1:0] w_insn_modified;
    logic w_next;
    logic w_empty;
    logic [RF_DAC_WIDTH*16-1:0] w_QIx8;
    logic w_start;
    logic w_armed;
    logic [RF_TOTAL_REGS-1:0][31:0] w_regs;
    logic [$clog2(RF_DEPTH)-1:0] w_addr;

    sequencer #(
        .INSN_WIDTH(RF_INSN_WIDTH),
        .ITER_WIDTH(RF_ITER_WIDTH),
        .DEPTH(RF_DEPTH)
    ) SEQ (
        .i_clk(w_clk),
        .i_rst(w_rst),
        .i_regs(w_regs),
        .o_addr(w_addr),
        .o_insn(w_insn),
        .i_next(w_next),
        .o_empty(w_empty),
        .i_insn_modified(w_insn_modified)
    );

    rf_output_stg_t o;

    rf_core #(
    	.KBC_WIDTH(RF_KBC_WIDTH),
    	.NUM_SAMPLE_WIDTH(RF_NUM_SAMPLE_WIDTH),
        .IQ_WIDTH(RF_IQ_WIDTH),
    	.DAC_WIDTH(RF_DAC_WIDTH),
    	.PHASE_WIDTH(RF_PHASE_WIDTH),
    	.CORDIC_STAGES(RF_CORDIC_STAGES),
    	.CORDIC_PAD_ZEROS(RF_CORDIC_PAD_ZEROS)
    ) CORE (
        .i_clk(w_clk),
        .i_rst(w_rst),
        .i_addr(w_addr),
        .i_insn(w_insn),
        .o_next(w_next),
        .i_empty(w_empty),
        .o_insn_modified(w_insn_modified),
        .o(o),
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

    real vrf;

    zcu216_dac RF_DAC (
        .i_clk(w_clk),
        .i_dac_clk(w_dac_clk),
        .i_QIx8(o.r_QIx8),
        .o_vrf(vrf)
    );

    // simulate DUC with 10MHz
    // int dac_cycle;
    // initial begin
    //     @(posedge w_clk);
    //     dac_cycle = 0;
    //     forever begin
//         @(posedge w_dac_clk);
    //         dac_cycle = (dac_cycle == 7) ? 0 : (dac_cycle + 1);
    //     end
    // end
    //
    // function automatic real iq2real(input int N, input logic [IQ_WIDTH-1:0] iq);
    //     return $itor($signed(iq)) / (1.0 * (1 << (N-1)));
    // endfunction
    //
    // logic [7:0][IQ_WIDTH-1:0] w_Ix8, w_Qx8;
    // logic [7:0][DAC_WIDTH-IQ_WIDTH-1:0] w_filler1, w_filler2;
    // for (genvar i = 0; i < 8; i++) begin
    //     assign {w_Qx8[i], w_filler1[i], w_Ix8[i], w_filler2[i]} = w_QIx8;
    // end
    //
    // real I, Q;
    // real deg, rad, out;
    // // logic [PHASE_WIDTH:0] w_phase;
    // // logic [PHASE_WIDTH*2-1:0] w_phase_full;
    // logic [IQ_WIDTH-1:0] w_I, w_Q;
    // initial begin
    //     deg = 0;
    //     @(posedge w_clk);
    //     forever begin
    //         @(negedge w_dac_clk);
    //         w_I = w_Ix8[dac_cycle];
    //         w_Q = w_Qx8[dac_cycle];
    //         // w_phase = w_phasex8[dac_cycle];
    //         // w_phase_full = phase_counter.r_p[dac_cycle];
    //         I = iq2real(IQ_WIDTH, w_I);
    //         Q = iq2real(IQ_WIDTH, w_Q);
    //         deg = deg + 1.8;
    //         rad = deg * 3.14159265358979323846 / 180.0;
    //         out = I * $cos(rad) - Q * $sin(rad);
    //     end
    // end

    task rabi(
        logic [RF_NUM_SAMPLE_WIDTH-1:0] ctrl_samples, ctrl_dsamples,
        logic [RF_NUM_SAMPLE_WIDTH-1:0] idle_samples, idle_dsamples,
        logic [RF_ITER_WIDTH-1:0] iters
    );

        w_regs[RF_REG_PER_INSN-1:0] = {
            1'b1,
            2'b10,
            {(RF_KBC_WIDTH){1'b0}},
            {(RF_KBC_WIDTH){1'b0}},
            ctrl_samples,
            ctrl_dsamples
        };

        w_regs[2*RF_REG_PER_INSN-1:RF_REG_PER_INSN] = {
            1'b0,
            2'b11,
            {(RF_KBC_WIDTH){1'b0}},
            {(RF_KBC_WIDTH){1'b0}},
            idle_samples,
            idle_dsamples
        };

        for (int i = 2 * RF_REG_PER_INSN; i <= RF_TOTAL_REGS - 3; i++) begin
            w_regs[i] = 'h0;
        end

        w_regs[RF_TOTAL_REGS-2] = iters;
        w_regs[RF_TOTAL_REGS-1] = 1'b0;

        @(posedge w_clk);
        w_regs[RF_TOTAL_REGS-1] = 1'b1;

        wait(w_armed);
        repeat(3) @(posedge w_clk);
        w_regs[RF_TOTAL_REGS - 1] = 'd0;
        w_start = 1'b1;
        @(posedge w_clk);
        w_start = 1'b0;

        wait(w_empty && CORE.x.r_samples_left == 'd0);
        repeat (RF_CORDIC_STAGES) @(posedge w_clk);

    endtask

    task rand_insns;
        

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

        rabi(.ctrl_samples('d0), .ctrl_dsamples('d8), .idle_samples('d16), .idle_dsamples('d0), .iters('d10));

        $finish;
    end

endmodule
