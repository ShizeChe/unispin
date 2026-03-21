`default_nettype none
`timescale 1ns / 1ps
`include "include/ex.svh"

module ex_tb;

    logic w_clk;
    logic w_rst;

    logic [0:EX_SEQ_REGS-1][31:0] w_seq_regs;

    logic [EX_DAC_WIDTH*16-1:0] w_realx16;

    logic w_start;
    logic w_armed;
    logic w_empty;

    ex_eop_t w_eop;

    ex #(
        .NUM_SAMPLE_WIDTH(EX_NUM_SAMPLE_WIDTH),
        .ITER_WIDTH(EX_ITER_WIDTH),
        .INSN_WIDTH(EX_INSN_WIDTH),
        .REAL_WIDTH(EX_REAL_WIDTH),
        .DAC_WIDTH(EX_DAC_WIDTH),
        .DEPTH(EX_DEPTH),
        .SEQ_REGS(EX_SEQ_REGS)
    ) EX (
        .i_clk(w_clk),
        .i_rst(w_rst),
        .i_seq_regs(w_seq_regs),
        .i_seq_uregs({(EX_SEQ_REGS*32){1'b0}}),
        .o_realx16(w_realx16),
        .i_start(w_start),
        .o_armed(w_armed),
        .o_empty(w_empty),
        .o_eop(w_eop)
    );

    initial begin
        w_clk = 1'b0;
        forever #2 w_clk = !w_clk;
    end

    ex_insn_t rand_insn;
    localparam MAX_SAMPLES = 8192;
    localparam MAX_DSAMPLES = 64;
    localparam MAX_ITERS = 10;

    ex_eop_t golden_seq [$];
    int num_insns;
    int total_samples;
    ex_eop_t eop;
    ex_eop_t golden_eop;

    ex_insn_t [0:EX_DEPTH-1] insns;
    for (genvar i = 0; i < EX_DEPTH; i++) begin : INSNS_GEN
        assign {w_seq_regs[i*EX_REG_PER_INSN:(i+1)*EX_REG_PER_INSN-1]} = 
            {{(EX_REG_PER_INSN*32-EX_INSN_WIDTH){1'b0}}, insns[i]};
    end
    
    logic [31:0] iters_reg;
    logic [31:0] start_reg;
    assign w_seq_regs[EX_SEQ_REGS-2] = iters_reg;
    assign w_seq_regs[EX_SEQ_REGS-1] = start_reg;

    task get_golden_seq;

        if (golden_seq.size() > 0)
            golden_seq.delete();

        for (int i = 0; i < iters_reg; i++) begin

            for (int j = 0; j < num_insns; j++) begin

                total_samples = insns[j].w_samples + insns[j].w_dsamples * i;

                for (int sample_start = 0; sample_start < total_samples; sample_start += 16) begin
                    eop.w_addr = j;
                    if (sample_start + 16 > total_samples) begin
                        for (int k = 0; k < total_samples - sample_start; k++) begin
                            eop.w_realx16[k*16 +: 16] = {insns[j].w_real, 2'b00};
                        end
                        for (int k = total_samples - sample_start; k < 16; k++) begin
                            eop.w_realx16[k*16 +: 16] = 16'h0;
                        end
                    end
                    else begin
                        eop.w_realx16 = { 
                            {(16){insns[j].w_real, 2'b00}}
                        };
                    end
                    golden_seq.push_back(eop);
                end

            end

        end

    endtask

    task rand_insns;

        for (int i = 0; i < EX_DEPTH; i++) begin
            insns[i] = 'h0;
        end

        num_insns = $urandom_range(1, EX_DEPTH - 1);

        for (int i = 0; i < num_insns; i++) begin
            insns[i] = '{
                w_arm: (i == 0),
                w_real: $urandom_range(0, 14'h3FFF),
                w_samples: $urandom_range(0, MAX_SAMPLES),
                w_dsamples: $urandom_range(0, MAX_SAMPLES)
            };
            $display("insn%0d", i);
            $display("w_arm=%0d", insns[i].w_arm);
            $display("w_real=0x%0h", insns[i].w_real);
            $display("w_samples=%0d", insns[i].w_samples);
            $display("w_dsamples=%0d\n", insns[i].w_dsamples);
        end

        iters_reg = $urandom_range(1, MAX_ITERS);
        $display("iters_reg=%0d\n", iters_reg);
        start_reg = 'h0;

        get_golden_seq;

        @(negedge w_clk);
        start_reg = 'h1;

        $display("wait armed");
        wait(w_armed);
        $display("armed success\n\n\n\n\n\n");
        repeat(3) @(negedge w_clk);
        start_reg = 'd0;
        w_start = 1'b1;
        @(negedge w_clk);
        w_start = 1'b0;

        for (int i = 0; i < golden_seq.size(); i++) begin
            golden_eop = golden_seq[i];
            assert (w_eop.w_addr == golden_seq[i].w_addr &&
                    w_eop.w_realx16 == golden_seq[i].w_realx16)
            else $fatal(1, "At %0.3f ns: o = %p, golden_seq[%0d] = %p", $realtime,
                        w_eop, i, golden_seq[i]);
            @(negedge w_clk);
        end

    endtask

    int test;

    initial begin
        w_rst = 1'b1;
        w_start = 1'b0;
        for (int i = 0; i < EX_DEPTH; i++) begin
            insns[i] = 'h0;
        end
        iters_reg = 32'h0;
        start_reg = 32'h0;
        @(negedge w_clk);
        w_rst = 1'b0;

        test = 0;
        repeat(100) begin
            repeat(100) @(negedge w_clk);
            $display("test%0d", test);
            rand_insns;
            test++;
        end

        $finish;
    end

endmodule
