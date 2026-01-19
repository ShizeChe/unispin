`default_nettype none
`timescale 1ns / 1ps
`include "include/rf.svh"

module rf_tb;

    logic w_clk, w_dac_clk, w_rst;

    logic w_start;
    logic w_armed;

    logic [0:RF_SEQ_REGS-1][31:0] w_seq_regs;
    logic [0:RF_CTRL_REGS-1][31:0] w_ctrl_regs;

    typedef struct {
        logic [$clog2(RF_DEPTH)-1:0] w_addr;
        logic [RF_NUM_SAMPLE_WIDTH-1:0] w_sample_start;
        logic [RF_NUM_SAMPLE_WIDTH-1:0] w_sample_end;
        logic [RF_DAC_WIDTH*16-1:0] w_QIx8;
    } rf_output_t;

    rf_output_t o;

    logic w_empty;

    logic w_nco_wait;

    logic w_nco_req;
    logic w_nco_busy;
    logic [RF_NCO_FREQ_WIDTH-1:0] w_nco_freq;
    logic [RF_NCO_PHASE_WIDTH-1:0] w_nco_phase;
    logic [RF_NCO_EN_WIDTH-1:0] w_nco_en;

    rf #(
        .KBC_WIDTH(RF_KBC_WIDTH),
        .ITER_WIDTH(RF_ITER_WIDTH),
        .NUM_SAMPLE_WIDTH(RF_NUM_SAMPLE_WIDTH),
        .INSN_WIDTH(RF_INSN_WIDTH),
        .IQ_WIDTH(RF_IQ_WIDTH),
        .DAC_WIDTH(RF_DAC_WIDTH),
        .PHASE_WIDTH(RF_PHASE_WIDTH),
        .CORDIC_STAGES(RF_CORDIC_STAGES),
        .CORDIC_PAD_ZEROS(RF_CORDIC_PAD_ZEROS),
        .DEPTH(RF_DEPTH),
        .NCO_FREQ_WIDTH(RF_NCO_FREQ_WIDTH),
        .NCO_PHASE_WIDTH(RF_NCO_PHASE_WIDTH),
        .NCO_EN_WIDTH(RF_NCO_EN_WIDTH),
        .SEQ_REGS(RF_SEQ_REGS),
        .CTRL_REGS(RF_CTRL_REGS)
    ) RF (
        .i_clk(w_clk),
        .i_rst(w_rst),

        .i_seq_regs(w_seq_regs),
        .i_ctrl_regs(w_ctrl_regs),

        .o_QIx8(o.w_QIx8),

        .i_start(w_start),
        .o_armed(w_armed),

        .o_empty(w_empty),

        .i_nco_wait(1'b0),
        .o_nco_wait(w_nco_wait),

        .o_nco_req(w_nco_req),
        .i_nco_busy(w_nco_busy),
        .o_nco_freq(w_nco_freq),
        .o_nco_phase(w_nco_phase),
        .o_nco_en(w_nco_en),

        .o_addr(o.w_addr),
        .o_sample_start(o.w_sample_start),
        .o_sample_end(o.w_sample_end)
    );

    logic [13:0] w_I, w_Q;
    real vrf;

    zcu216_dac RF_DAC (
        .i_clk(w_clk),
        .i_dac_clk(w_dac_clk),
        .i_QIx8(o.w_QIx8),
        .o_I(w_I),
        .o_Q(w_Q),
        .o_vrf(vrf),
        .i_nco_req(w_nco_req),
        .o_nco_busy(w_nco_busy),
        .i_nco_freq(w_nco_freq),
        .i_nco_phase(w_nco_phase),
        .i_nco_en(w_nco_en)
    );

    initial begin
        w_clk = 1'b0;
        forever #2 w_clk = !w_clk;
    end

    initial begin
        w_dac_clk = 1'b1;
        forever #0.25 w_dac_clk = !w_dac_clk;
    end

    rf_insn_t rand_insn;
    localparam MAX_SAMPLES = 8192;
    localparam MAX_DSAMPLES = 64;
    localparam MAX_ITERS = 10;

    function logic [RF_DAC_WIDTH*16-1:0] get_golden_QI(
        input rf_kbc_mode_t kbc_mode,
        input logic [RF_KBC_WIDTH] kbc1, kbc2,
        input logic sample_start, sample_end
    );
        return 'h0;
    endfunction

    rf_output_t golden_seq [$];
    int num_insns;
    int total_samples;
    rf_output_t out;
    rf_output_t golden_o;

    rf_insn_t [0:RF_DEPTH-1] insns;
    for (genvar i = 0; i < RF_DEPTH; i++) begin : INSNS_GEN
        assign {w_seq_regs[i*RF_REG_PER_INSN:(i+1)*RF_REG_PER_INSN-1]} = 
            {{(RF_REG_PER_INSN*32-RF_INSN_WIDTH){1'b0}}, insns[i]};
    end
    
    logic [31:0] iters_reg;
    logic [31:0] start_reg;
    assign w_seq_regs[RF_SEQ_REGS-2] = iters_reg;
    assign w_seq_regs[RF_SEQ_REGS-1] = start_reg;

    logic [RF_NCO_FREQ_WIDTH-1:0] nco_freq_reg;
    logic [RF_NCO_PHASE_WIDTH-1:0] nco_phase_reg;
    logic [RF_IQ_WIDTH-1:0] default_I_reg;
    logic [RF_IQ_WIDTH-1:0] default_Q_reg;
    logic [31:0] new_ctrl_reg;
    assign {w_ctrl_regs[0], w_ctrl_regs[1]} = {{(64-RF_NCO_FREQ_WIDTH){1'b0}}, nco_freq_reg};
    assign w_ctrl_regs[2] = {{(32-RF_NCO_PHASE_WIDTH){1'b0}}, nco_phase_reg};
    assign w_ctrl_regs[3] = {{(32-RF_IQ_WIDTH){1'b0}}, default_I_reg};
    assign w_ctrl_regs[4] = {{(32-RF_IQ_WIDTH){1'b0}}, default_Q_reg};
    assign w_ctrl_regs[5] = new_ctrl_reg;

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

        for (int i = 0; i < RF_DEPTH; i++) begin
            insns[i] = 'h0;
        end

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
            $display("insn%0d", i);
            $display("w_arm=%0d", insns[i].w_arm);
            $display("w_kbc_mode=0x%0h", insns[i].w_kbc_mode);
            $display("w_kbc1=0x%0h", insns[i].w_kbc1);
            $display("w_kbc2=0x%0h", insns[i].w_kbc2);
            $display("w_samples=%0d", insns[i].w_samples);
            $display("w_dsamples=%0d\n", insns[i].w_dsamples);
        end

        iters_reg = $urandom_range(1, MAX_ITERS);
        start_reg = 32'h0;

        get_golden_seq;

        @(negedge w_clk);
        start_reg = 1'b1;

        $display("wait armed");
        wait(w_armed);
        $display("armed success");
        repeat(3) @(negedge w_clk);
        start_reg = 'd0;
        w_start = 1'b1;
        @(negedge w_clk);
        w_start = 1'b0;

        for (int i = 0; i < golden_seq.size(); i++) begin
            golden_o = golden_seq[i];
            assert (o.w_addr == golden_seq[i].w_addr &&
                    o.w_sample_start == golden_seq[i].w_sample_start &&
                    o.w_sample_end == golden_seq[i].w_sample_end)
            else $fatal(1, "At %0.3f ns: o = %p, golden_seq[%0d] = %p", $realtime,
                        o, i, golden_seq[i]);
            @(negedge w_clk);
        end

    endtask

    int test;

    initial begin
        w_rst = 1'b1;
        w_start = 1'b0;
        for (int i = 0; i < RF_DEPTH; i++) begin
            insns[i] = 'h0;
        end
        iters_reg = 32'h0;
        start_reg = 32'h0;
        nco_freq_reg = 'h0;
        nco_phase_reg = 'h0;
        default_I_reg = 'h0;
        default_Q_reg = 'h0;
        new_ctrl_reg = 'h0;
        @(negedge w_clk);
        w_rst = 1'b0;

        test = 0;
        repeat(10) begin
            $display("test%0d", test);
            rand_insns;
            test++;
        end

        $finish;
    end

endmodule
