`default_nettype none
`timescale 1ns / 1ps
`include "include/rf.svh"

module rf_tb;

    logic w_clk, w_rst;
    logic [RF_INSN_WIDTH-1:0] w_insn;
    logic [RF_INSN_WIDTH-1:0] w_insn_modified;
    logic w_next;
    logic w_empty;
    logic w_start;
    logic w_armed;
    logic [0:RF_TOTAL_REGS-1][31:0] w_regs;
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

    typedef struct {
        logic [$clog2(RF_DEPTH)-1:0] w_addr;
        logic [RF_NUM_SAMPLE_WIDTH-1:0] w_sample_start;
        logic [RF_NUM_SAMPLE_WIDTH-1:0] w_sample_end;
        logic [RF_DAC_WIDTH*16-1:0] w_QIx8;
    } rf_output_stg_t;

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
        .o_addr(o.w_addr),
        .o_sample_start(o.w_sample_start),
        .o_sample_end(o.w_sample_end),
        .o_QIx8(o.w_QIx8),
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
        .i_QIx8(o.w_QIx8),
        .o_vrf(vrf)
    );

    task rabi(
        logic [RF_NUM_SAMPLE_WIDTH-1:0] ctrl_samples, ctrl_dsamples,
        logic [RF_NUM_SAMPLE_WIDTH-1:0] idle_samples, idle_dsamples,
        logic [RF_ITER_WIDTH-1:0] iters
    );


        for (int i = 0; i < RF_TOTAL_REGS; i++) begin
            w_regs[i] = 'h0;
        end

        w_regs[0:RF_REG_PER_INSN-1] = {
            1'b1,
            2'b10,
            {(RF_KBC_WIDTH){1'b0}},
            {(RF_KBC_WIDTH){1'b0}},
            ctrl_samples,
            ctrl_dsamples
        };

        w_regs[RF_REG_PER_INSN:2*RF_REG_PER_INSN-1] = {
            1'b0,
            2'b11,
            {(RF_KBC_WIDTH){1'b0}},
            {(RF_KBC_WIDTH){1'b0}},
            idle_samples,
            idle_dsamples
        };

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

        wait(w_empty && CORE.p.r_samples_left == 'd0);
        repeat (RF_CORDIC_STAGES) @(posedge w_clk);

    endtask

    rf_insn_t rand_insn;
    localparam MAX_SAMPLES = 8192;
    localparam MAX_DSAMPLES = 64;
    localparam MAX_ITERS = 100;

    function logic [RF_DAC_WIDTH*16-1:0] get_golden_QI(
        input rf_kbc_mode_t kbc_mode,
        input logic [RF_KBC_WIDTH] kbc1, kbc2,
        input logic sample_start, sample_end
    );
        return 'h0;
    endfunction

    rf_output_stg_t golden_seq [$];
    int num_insns;
    int total_samples;
    rf_output_stg_t out;
    rf_output_stg_t golden_o;

    rf_insn_t [0:RF_DEPTH-1] insns;
    for (genvar i = 0; i < RF_DEPTH; i++) begin : INSNS_GEN
        assign {w_regs[i*RF_REG_PER_INSN:(i+1)*RF_REG_PER_INSN-1]} = 
            {{(RF_REG_PER_INSN*32-RF_INSN_WIDTH){1'b0}}, insns[i]};
    end
    
    logic [31:0] iters_reg;
    logic [31:0] start_reg;
    assign w_regs[RF_TOTAL_REGS-2] = iters_reg;
    assign w_regs[RF_TOTAL_REGS-1] = start_reg;

    task get_golden_seq;

        if (golden_seq.size() > 0)
            golden_seq.delete();

        for (int i = 0; i < iters_reg; i++) begin

            for (int j = 0; j < num_insns; j++) begin

                total_samples = insns[j].w_samples + insns[j].w_dsamples * i;

                for (int sample_start = 0; sample_start < total_samples; sample_start += 8) begin

                    out.w_addr = j;
                    out.w_sample_start = sample_start;
                    out.w_sample_end = (sample_start + 8 > total_samples) ? total_samples - 1 : 
                                        sample_start + 7;
                    out.w_QIx8 = get_golden_QI(insns[j].w_kbc_mode, insns[j].w_kbc1, insns[j].w_kbc2, 
                                               out.w_sample_start, out.w_sample_end);

                    golden_seq.push_back(out);

                end

            end

        end

    endtask

    function rf_kbc_mode_t rand_kbc_mode();
        int n = $urandom_range(1, 3);
        if (n == 1)
            return RF_KB;
        else if (n == 2)
            return RF_BC;
        else
            return RF_IDLE;
    endfunction

    task rand_insns;

        num_insns = $urandom_range(1, RF_DEPTH - 1);

        for (int i = 0; i < num_insns; i++) begin
            insns[i] = '{
                w_arm: (i == 0),
                w_kbc_mode: rand_kbc_mode(),
                w_kbc1: $urandom_range(0, {(RF_KBC_WIDTH){1'b1}}),
                w_kbc2: $urandom_range(0, {(RF_KBC_WIDTH){1'b1}}),
                w_samples: $urandom_range(0, MAX_SAMPLES),
                w_dsamples: $urandom_range(0, MAX_SAMPLES)
            };
        end

        iters_reg = $urandom_range(0, MAX_ITERS);
        start_reg = 32'h0;

        get_golden_seq;

        @(negedge w_clk);
        start_reg = 1'b1;

        wait(w_armed);
        repeat(3) @(negedge w_clk);
        start_reg = 'd0;
        w_start = 1'b1;
        @(negedge w_clk);
        w_start = 1'b0;

        for (int i = 0; i < golden_seq.size(); i++) begin
            assert (o.w_addr == golden_seq[i].w_addr &&
                    o.w_sample_start == golden_seq[i].w_sample_start &&
                    o.w_sample_end == golden_seq[i].w_sample_end)
            else $fatal(1, "At %0.3f ns: o = %p, golden_seq[%0d] = %p", $realtime,
                        o, i, golden_seq[i]);
            @(negedge w_clk);
        end

        $finish;

    endtask


    initial begin
        w_rst = 1'b1;
        w_start = 1'b0;
        for (int i = 0; i < RF_DEPTH; i++) begin
            insns[i] = 'h0;
        end
        iters_reg = 32'h0;
        start_reg = 32'h0;
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

        // rabi(.ctrl_samples('d0), .ctrl_dsamples('d8), .idle_samples('d16), .idle_dsamples('d0), .iters('d10));
        repeat(10) rand_insns;

        $finish;
    end

endmodule
