`default_nettype none
`timescale 1ns / 1ps
`include "include/li.svh"

module li_tb;

    logic w_clk, w_rst, w_adc_clk;

    logic [0:LI_SEQ_REGS-1][31:0] w_seq_regs;

    logic [LI_ADC_WIDTH*8-1:0] w_QIx4_in;

    logic [3:0] w_sample_mask;

    logic [LI_ADC_WIDTH*8-1:0] w_QIx4_out;
    logic [3:0] w_validx4;
    logic w_last;

    logic w_start;
    logic w_armed;
     
    logic w_empty;

    li_eop_t w_eop;

    li #(
        .NUM_SAMPLE_WIDTH(LI_NUM_SAMPLE_WIDTH),
        .STRIDE_WIDTH(LI_STRIDE_WIDTH),
        .INSN_WIDTH(LI_INSN_WIDTH),
        .DEPTH(LI_DEPTH),
        .ADC_WIDTH(LI_ADC_WIDTH),
        .SEQ_REGS(LI_SEQ_REGS),
        .CTRL_REGS(LI_CTRL_REGS)
    ) LI (
        .i_clk(w_clk),
        .i_rst(w_rst),

        .i_seq_regs(w_seq_regs),
        .i_ctrl_regs({(LI_CTRL_REGS*32){1'b0}}),

        .i_seq_uregs({(LI_SEQ_REGS*32){1'b0}}),
        .i_ctrl_uregs({(LI_CTRL_REGS*32){1'b0}}),

        .i_QIx4(w_QIx4_in),
        
        .o_sample_mask(w_sample_mask),

        .o_QIx4(w_QIx4_out),
        .o_validx4(w_validx4),
        .o_last(w_last),

        .i_start(w_start),
        .o_armed(w_armed),

        .o_empty(w_empty),

        .o_ctrl(),
        
        .o_eop(w_eop)
    );

    initial begin
        w_clk = 1'b0;
        forever #2 w_clk = !w_clk;
    end

    initial begin
        w_adc_clk = 1'b1;
        forever #0.5 w_adc_clk = !w_adc_clk;
    end

    int adc_cycle;
    initial begin
        @(posedge w_clk);
        adc_cycle = 0;
        forever begin
            @(posedge w_adc_clk);
            adc_cycle = (adc_cycle == 3) ? 0 : (adc_cycle + 1);
        end
    end

    li_insn_t [0:LI_DEPTH-1] insns;
    for (genvar i = 0; i < LI_DEPTH; i++) begin : INSNS_GEN
        assign {w_seq_regs[i*LI_REG_PER_INSN:(i+1)*LI_REG_PER_INSN-1]} = 
            {{(LI_REG_PER_INSN*32-LI_INSN_WIDTH){1'b0}}, insns[i]};
    end
    
    logic [31:0] iters_reg;
    logic [31:0] start_reg;
    assign w_seq_regs[LI_SEQ_REGS-2] = iters_reg;
    assign w_seq_regs[LI_SEQ_REGS-1] = start_reg;

    localparam MAX_SAMPLES = 8192;
    localparam MAX_ITERS = 10;

    logic [31:0] golden_samples [$];
    logic [31:0] got_samples [$];

    function automatic bit queues_equal(
        input logic [31:0] a[$],
        input logic [31:0] b[$]
    );
        if (a.size() != b.size())
            return 0;

        for (int i = 0; i < a.size(); i++)
            if (a[i] !== b[i])
                return 0;

        return 1;
    endfunction

    function automatic bit compare_queues
    (
        input logic [31:0] golden_q[$],
        input logic [31:0] got_q[$]
    );
        bit match;
        int min_sz;

        match = 1;
        min_sz = (golden_q.size() < got_q.size()) ? golden_q.size() : got_q.size();

        if (golden_q.size() != got_q.size()) begin
            $display("Queue size mismatch: golden=%0d, got=%0d",
                     golden_q.size(), got_q.size());
            match = 0;
        end

        for (int i = 0; i < min_sz; i++) begin
            if (golden_q[i] !== got_q[i]) begin
                $display("Mismatch at index %0d: golden=0x%08x, got=0x%08x",
                         i, golden_q[i], got_q[i]);
                match = 0;
            end
        end

        if (golden_q.size() > got_q.size()) begin
            for (int i = got_q.size(); i < golden_q.size(); i++) begin
                $display("Missing entry at index %0d: golden=0x%08x, got=<none>",
                         i, golden_q[i]);
            end
        end
        else if (got_q.size() > golden_q.size()) begin
            for (int i = golden_q.size(); i < got_q.size(); i++) begin
                $display("Extra entry at index %0d: golden=<none>, got=0x%08x",
                         i, got_q[i]);
            end
        end

        return match;
    endfunction

    int total_samples;
    int num_insns;
    int sample;
    int step;

    logic [31:0] rand_sample;

    task rand_insns; 

        for (int i = 0; i < LI_DEPTH; i++) begin
            insns[i] = 'h0;
        end

        num_insns = $urandom_range(1, LI_DEPTH - 1);

        total_samples = 0;

        for (int i = 0; i < num_insns; i++) begin
            insns[i].w_arm = (i == 0);
            insns[i].w_idle = $urandom_range(0, 1);
            insns[i].w_samples = $urandom_range(1, 1024);
            insns[i].w_dsamples = $urandom_range(0, 256);
            insns[i].w_stride = $urandom_range(1, 128);
            $display("insn%0d", i);
            $display("w_arm=%0d", insns[i].w_arm);
            $display("w_idle=%0d", insns[i].w_idle);
            $display("w_samples=%0d", insns[i].w_samples);
            $display("w_dsamples=%0d\n", insns[i].w_dsamples);
            $display("w_stride=%0d\n", insns[i].w_stride);
        end

        iters_reg = $urandom_range(1, MAX_ITERS);
        $display("iters_reg=%0d\n", iters_reg);
        start_reg = 'h0;

        @(negedge w_clk);
        start_reg = 'h1;

        $display("wait armed");
        wait(w_armed);
        $display("armed success");
        repeat(3) @(negedge w_clk);
        start_reg = 'd0;
        w_start = 1'b1;
        @(posedge w_clk);
        golden_samples.delete();

        // serve samples
        for (int i = 0; i < iters_reg; i++) begin

            for (int j = 0; j < num_insns; j++) begin

                if (insns[j].w_idle) begin

                    @(negedge w_adc_clk);
                    w_start = 1'b0;

                    assert (LI.CORE.s.r_samples == insns[j].w_samples + i * insns[j].w_dsamples)
                    else $fatal(1, "At %0.3f ns: LI.CORE.s.r_samples=%0d, should be %0d", $realtime, LI.CORE.s.r_samples, 
                        insns[j].w_samples + i * insns[j].w_dsamples);

                    repeat (insns[j].w_samples + i * insns[j].w_dsamples - 1) begin
                        @(negedge w_adc_clk);
                        assert (w_sample_mask[adc_cycle] == 1'b0)
                        else $fatal(1, "At %0.3f ns: w_sample_mask[%0d]=%0b, should be 0", $realtime, adc_cycle, w_sample_mask[adc_cycle]);
                    end

                    assert (LI.CORE.s.w_done)
                    else $fatal(1, "At %0.3f ns: LI.CORE.s.w_done=%0b, should be 1", $realtime, LI.CORE.s.w_done);

                end
                else begin

                    @(negedge w_adc_clk);
                    w_start = 1'b0;

                    assert (LI.CORE.s.r_samples == insns[j].w_samples + i * insns[j].w_dsamples)
                    else $fatal(1, "At %0.3f ns: LI.CORE.s.r_samples=%0d, should be %0d", $realtime, LI.CORE.s.r_samples, 
                        insns[j].w_samples + i * insns[j].w_dsamples);

                    assert (w_sample_mask[0] == 1'b1)
                    else $fatal(1, "At %0.3f ns: w_sample_mask[0]=%0b, should be 1", $realtime, w_sample_mask[0]);

                    w_QIx4_in = 'h0;
                    rand_sample = $urandom;
                    golden_samples.push_back(rand_sample);
                    w_QIx4_in[31:0] = rand_sample;

                    sample = 1;
                    step = 1;

                    repeat (insns[j].w_samples + i * insns[j].w_dsamples - 1) begin
                        // $display("sample%0d", sample);
                        repeat (insns[j].w_stride - 1) begin
                            // $display("step%0d", step);
                            @(negedge w_adc_clk);
                            step++;
                            assert (w_sample_mask[adc_cycle] == 1'b0)
                            else $fatal(1, "At %0.3f ns: w_sample_mask[%0d]=%0b, should be 0", $realtime, adc_cycle, w_sample_mask[adc_cycle]);
                        end
                        @(negedge w_adc_clk);
                        step = 1;
                        assert (w_sample_mask[adc_cycle] == 1'b1)
                        else $fatal(1, "At %0.3f ns: w_sample_mask[%0d]=%0b, should be 1", $realtime, adc_cycle, w_sample_mask[adc_cycle]);
                        sample++;

                        rand_sample = $urandom;
                        golden_samples.push_back(rand_sample);
                        if (adc_cycle == 0)
                            w_QIx4_in[31:0] = rand_sample;
                        else if (adc_cycle == 1)
                            w_QIx4_in[63:32] = rand_sample;
                        else if (adc_cycle == 2)
                            w_QIx4_in[95:64] = rand_sample;
                        else
                            w_QIx4_in[127:96] = rand_sample;

                    end

                    while (step + 4 <= insns[j].w_stride) begin
                        // $display("step%0d", step);
                        @(negedge w_adc_clk);
                        step++;
                        assert (w_sample_mask[adc_cycle] == 1'b0)
                        else $fatal(1, "At %0.3f ns: w_sample_mask[%0d]=%0b, should be 0", $realtime, adc_cycle, w_sample_mask[adc_cycle]);
                    end

                end

                $display("At %0.03f ns: assert w_done", $realtime);
                assert (LI.CORE.s.w_done)
                else $fatal(1, "At %0.3f ns: LI.CORE.s.w_done=%0b, should be 1", $realtime, LI.CORE.s.w_done);

                @(posedge w_clk);

            end
        end

        wait(w_empty);

        assert (queues_equal(golden_samples, got_samples))
        else begin 
            compare_queues(golden_samples, got_samples);
            $fatal(1, "At %0.3f ns: golden_samples and got_samples don't match", $realtime);
        end

        $display("At %0.03f ns: check golden_samples/got_samples passed, clear queues", $realtime);
        golden_samples.delete();
        got_samples.delete();

    endtask

    initial begin
        forever begin
            @(negedge w_clk);
            if (w_validx4 == 4'b1111) begin
                got_samples.push_back(w_QIx4_out[31:0]);
                got_samples.push_back(w_QIx4_out[63:32]);
                got_samples.push_back(w_QIx4_out[95:64]);
                got_samples.push_back(w_QIx4_out[127:96]);
            end
            else if (w_last) begin
                if (w_validx4 == 4'b1) begin
                    got_samples.push_back(w_QIx4_out[31:0]);
                end
                else if (w_validx4 == 4'b11) begin
                    got_samples.push_back(w_QIx4_out[31:0]);
                    got_samples.push_back(w_QIx4_out[63:32]);
                end
                else if (w_validx4 == 4'b111) begin
                    got_samples.push_back(w_QIx4_out[31:0]);
                    got_samples.push_back(w_QIx4_out[63:32]);
                    got_samples.push_back(w_QIx4_out[95:64]);
                end
                else if (w_validx4 == 4'b1111) begin
                    got_samples.push_back(w_QIx4_out[31:0]);
                    got_samples.push_back(w_QIx4_out[63:32]);
                    got_samples.push_back(w_QIx4_out[95:64]);
                    got_samples.push_back(w_QIx4_out[127:96]);
                end
                else
                    $fatal(1, "At %0.3f ns: w_validx4=%0b when w_last=1", $realtime, w_validx4);
            end
            else begin
                assert (w_validx4 === 4'b0000)
                else $fatal(1, "At %0.3f ns: w_validx4=%0b", $realtime, w_validx4);
            end
        end
    end

    initial begin

        w_rst = 1'b1;
        for (int i = 0; i < LI_DEPTH; i++) begin
            insns[i] = 'h0;
        end
        num_insns = 0;
        w_QIx4_in = 'h0;
        w_start = 1'b0;
        @(negedge w_clk);
        w_rst = 1'b0;

        repeat (100) begin
            rand_insns;
        end
        $finish;

    end

endmodule
