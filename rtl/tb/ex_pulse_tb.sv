`default_nettype none
`timescale 1ns / 1ps
`include "include/ex.svh"

// Verifies EX channel against a shortened exchange.asm ex0 program:
//   .repeat 4
//       idl t=180ns (arm)         ; insn0 - was 19us arm gate
//       idl t=180ns               ; insn1
//       lvl v=1 t=4ns (t+4ns)     ; insn2
//       idl t=240ns               ; insn3
//       lvl v=1 t=4ns (t+4ns)     ; insn4
//       idl t=60ns                ; insn5
//       idl t=180ns               ; insn6 - was 12us trailing idle
// Encoding matches ex_lvl2insn / ex_idl2insn in asm/src/ex.c.
// Outer-idle times shrunk only on insn0 and insn6 for sim speed.

module ex_pulse_tb;

    localparam BRAM_PCST_ADDR  = 0;
    localparam BRAM_PCST       = 1;
    localparam BRAM_PCST_STRB  = 2;
    localparam BRAM_IST_ADDR   = 3;
    localparam BRAM_IST_LO     = 4;
    localparam BRAM_IST_STRB   = 4 + EX_REG_PER_INSN;
    localparam BRAM_ITERS      = 5 + EX_REG_PER_INSN;
    localparam BRAM_DEPTH      = 6 + EX_REG_PER_INSN;
    localparam BRAM_START      = 7 + EX_REG_PER_INSN;

    // #2 half-period -> 4 ns clk -> 16 samples/eop * 4 ns = 0.25 ns/sample.
    // Must match EX_NS_PER_SAMPLE from asm/include/ex.h.
    localparam real CLK_PERIOD_NS = 4.0;
    localparam real NS_PER_SAMPLE = 0.25;

    // Pinned regression values.
    //   real2twos(EX_VMIN=-1, EX_VMAX=1, 14, 1.0, 0) -> x>=max -> kmax = (1<<13)-1
    //   -> 14'h1FFF; DAC lane = {14'h1FFF, 2'b00} = 16'h7FFC.
    localparam logic [EX_DAC_WIDTH-1:0] LVL_DAC_WORD = 16'h7FFC;
    // Per lvl insn, eops per outer iter i = (16 + 16*i)/16 = i+1.
    // sum over i=0..3 = 1+2+3+4 = 10.
    localparam int LVL_EOPS_PER_INSN = 10;
    // Total eops per outer iter:
    //   45 (idl 720) + 45 (idl 720) + 60 (idl 960) + 15 (idl 240) + 45 (idl 720)
    //   + 2*(i+1) for the two lvl insns = 210 + 2(i+1) = 212 + 2*i
    // Sum i=0..3: 212+214+216+218 = 860.
    localparam int TOTAL_GOLDEN_EOPS = 860;

    logic w_clk, w_rst;

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
        .o_realx16(w_realx16),
        .i_start(w_start),
        .o_armed(w_armed),
        .o_empty(w_empty),
        .o_eop(w_eop)
    );

    ex_eop_t golden_seq [$];
    int num_insns;
    int total_samples;
    ex_eop_t eop;
    ex_eop_t golden_eop;

    ex_insn_t insns [0:EX_DEPTH-1];

    task automatic pack_insn_to_ist(input ex_insn_t insn);
        w_seq_regs[BRAM_IST_LO][EX_INSN_WIDTH - (EX_REG_PER_INSN - 1) * 32 - 1:0] =
            insn[(EX_REG_PER_INSN - 1) * 32 +: EX_INSN_WIDTH - (EX_REG_PER_INSN - 1) * 32];
        for (int i = 1; i < EX_REG_PER_INSN; i++) begin
            w_seq_regs[BRAM_IST_LO + i] =
                insn[(EX_REG_PER_INSN - 1 - i) * 32 +: 32];
        end
    endtask

    task load_insn(input logic [$clog2(EX_DEPTH)-1:0] addr, input ex_insn_t insn);
        @(negedge w_clk);
        w_seq_regs[BRAM_IST_ADDR]      = '0;
        pack_insn_to_ist('0);
        w_seq_regs[BRAM_IST_STRB]      = '0;

        w_seq_regs[BRAM_IST_ADDR][$clog2(EX_DEPTH)-1:0] = addr;
        pack_insn_to_ist(insn);

        w_seq_regs[BRAM_IST_STRB][0] = 1'b1;
        @(negedge w_clk);
        w_seq_regs[BRAM_IST_STRB][0] = 1'b0;
        // Hold addr/data stable for one more cycle so the bram write commits
        // (edge detector fires posedge 2 cycles after signal rose; bram samples
        // i_wr the cycle AFTER, so a back-to-back call would change addr first).
        @(negedge w_clk);
    endtask

    task load_pc(
        input logic [EX_PC_ADDR_WIDTH-1:0] pc_addr,
        input logic [$clog2(EX_DEPTH)-1:0] pc
    );
        @(negedge w_clk);
        w_seq_regs[BRAM_PCST_ADDR] = '0;
        w_seq_regs[BRAM_PCST]      = '0;
        w_seq_regs[BRAM_PCST_STRB] = '0;

        w_seq_regs[BRAM_PCST_ADDR][EX_PC_ADDR_WIDTH-1:0] = pc_addr;
        w_seq_regs[BRAM_PCST][$clog2(EX_DEPTH)-1:0]      = pc;

        w_seq_regs[BRAM_PCST_STRB][0] = 1'b1;
        @(negedge w_clk);
        w_seq_regs[BRAM_PCST_STRB][0] = 1'b0;
        // Hold addr/data stable for one more cycle so the bram write commits
        // before a back-to-back call changes the address.
        @(negedge w_clk);
    endtask

    task load_iters(input logic [EX_ITER_WIDTH-1:0] iters);
        @(negedge w_clk);
        w_seq_regs[BRAM_ITERS] = '0;
        w_seq_regs[BRAM_ITERS][EX_ITER_WIDTH-1:0] = iters;
    endtask

    task load_depth(input logic [EX_PC_ADDR_WIDTH-1:0] depth);
        @(negedge w_clk);
        w_seq_regs[BRAM_DEPTH] = '0;
        w_seq_regs[BRAM_DEPTH][EX_PC_ADDR_WIDTH-1:0] = depth;
    endtask

    task start_seq;
        @(negedge w_clk);
        w_seq_regs[BRAM_START][0] = 1'b1;
        @(negedge w_clk);
        w_seq_regs[BRAM_START][0] = 1'b0;
    endtask

    // Mirrors ex_tb.sv get_golden_seq: idl produces ceil(samples/16) zero-payload
    // eops, lvl produces ceil((samples + dsamples*i)/16) eops with {real, 2'b00}
    // packed into each 16-sample lane (zero-padded on the tail chunk).
    task get_golden_seq;
        if (golden_seq.size() > 0)
            golden_seq.delete();

        for (int i = 0; i < w_seq_regs[BRAM_ITERS][EX_ITER_WIDTH-1:0]; i++) begin

            for (int j = 0; j < num_insns; j++) begin

                total_samples = insns[j].w_samples + insns[j].w_dsamples * i;

                for (int sample_start = 0; sample_start < total_samples;
                     sample_start += 16) begin
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
                        eop.w_realx16 = {(16){insns[j].w_real, 2'b00}};
                    end
                    eop.w_marker = 1'b0;
                    golden_seq.push_back(eop);
                end

            end

        end
    endtask

    task run_ex_pulse;

        for (int i = 0; i < EX_DEPTH; i++)
            insns[i] = 'h0;

        // ex_idl2insn: real=0, samples=t_ns/0.25, dsamples=tplus_ns/0.25
        // ex_lvl2insn: real=real2twos(EX_VMIN,EX_VMAX,14,v,0), samples/dsamples likewise
        insns[0] = '{w_arm: 1'b1, w_sticky_arm: 1'b0, w_real: 'h0,
                     w_samples: 'd720, w_dsamples: 'd0,  w_marker: 1'b0};
        insns[1] = '{w_arm: 1'b0, w_sticky_arm: 1'b0, w_real: 'h0,
                     w_samples: 'd720, w_dsamples: 'd0,  w_marker: 1'b0};
        insns[2] = '{w_arm: 1'b0, w_sticky_arm: 1'b0, w_real: 14'h1FFF,
                     w_samples: 'd16,  w_dsamples: 'd16, w_marker: 1'b0};
        insns[3] = '{w_arm: 1'b0, w_sticky_arm: 1'b0, w_real: 'h0,
                     w_samples: 'd960, w_dsamples: 'd0,  w_marker: 1'b0};
        insns[4] = '{w_arm: 1'b0, w_sticky_arm: 1'b0, w_real: 14'h1FFF,
                     w_samples: 'd16,  w_dsamples: 'd16, w_marker: 1'b0};
        insns[5] = '{w_arm: 1'b0, w_sticky_arm: 1'b0, w_real: 'h0,
                     w_samples: 'd240, w_dsamples: 'd0,  w_marker: 1'b0};
        insns[6] = '{w_arm: 1'b0, w_sticky_arm: 1'b0, w_real: 'h0,
                     w_samples: 'd720, w_dsamples: 'd0,  w_marker: 1'b0};

        num_insns = 7;

        for (int i = 0; i < num_insns; i++)
            load_insn(i[$clog2(EX_DEPTH)-1:0], insns[i]);

        for (int i = 0; i < num_insns; i++)
            load_pc(i[EX_PC_ADDR_WIDTH-1:0], i[$clog2(EX_DEPTH)-1:0]);

        load_iters('d4);
        load_depth('d6);  // num_insns - 1

        get_golden_seq;

        $display("golden eop count = %0d", golden_seq.size());
        if (golden_seq.size() != TOTAL_GOLDEN_EOPS)
            $fatal(1, "golden eop count %0d != expected %0d",
                   golden_seq.size(), TOTAL_GOLDEN_EOPS);

        // Sanity: each lvl insn's first-iter eop must carry LVL_DAC_WORD in all lanes.
        for (int lane = 0; lane < 16; lane++) begin
            if (golden_seq[45+45].w_realx16[lane*16 +: 16] != LVL_DAC_WORD)
                $fatal(1, "golden lvl insn2 iter0 lane%0d=0x%0h, expected 0x%0h",
                       lane, golden_seq[45+45].w_realx16[lane*16 +: 16], LVL_DAC_WORD);
        end

        @(negedge w_clk);
        start_seq;

        wait(w_armed);
        $display("armed");
        repeat(3) @(negedge w_clk);

        w_start = 1'b1;
        @(negedge w_clk);
        w_start = 1'b0;

        for (int i = 0; i < golden_seq.size(); i++) begin
            golden_eop = golden_seq[i];
            assert (w_eop.w_addr == golden_seq[i].w_addr &&
                    w_eop.w_realx16 == golden_seq[i].w_realx16)
            else $fatal(1, "At %0.3f ns: w_eop = %p, golden_seq[%0d] = %p",
                        $realtime, w_eop, i, golden_seq[i]);
            @(negedge w_clk);
        end

        wait(w_empty);
        $display("TEST PASSED: ex_pulse_tb (exchange.asm ex0 shortened)");

    endtask

    initial begin
        w_clk = 1'b0;
        forever #2 w_clk = !w_clk;
    end

    initial begin
        // compile-time sanity: half-period * 2 / 16 lanes must equal sample period
        if (CLK_PERIOD_NS / 16.0 != NS_PER_SAMPLE)
            $fatal(1, "clk/sample-rate mismatch: %0f vs %0f",
                   CLK_PERIOD_NS / 16.0, NS_PER_SAMPLE);

        w_rst = 1'b1;
        w_start = 1'b0;
        w_seq_regs = '{default:'0};

        @(negedge w_clk);
        w_rst = 1'b0;

        run_ex_pulse;
        $finish;
    end

endmodule
