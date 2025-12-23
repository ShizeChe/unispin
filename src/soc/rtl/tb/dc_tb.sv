`default_nettype none
`timescale 1ns / 1ps
`include "include/dc.svh"

module dc_tb;

    logic w_clk, w_rst;

    logic [$clog2(DC_DEPTH)-1:0] w_addr;
    logic [DC_INSN_WIDTH-1:0] w_insn;
    logic w_next;
    logic w_empty;
    dc_insn_t w_insn_modified;

    logic w_sclk;
    logic w_mosi;
    logic w_miso;
    logic w_cs_n;
    logic w_ldac_n;

    logic [0:DC_TOTAL_REGS-1][31:0] w_regs;

    typedef struct {
        logic [$clog2(DC_DEPTH)-1:0] w_addr;
        logic [DC_CORE_ITER_WIDTH-1:0] w_iter;
        logic [DC_SPI_DATA_WIDTH-1:0] w_spi_din;
        logic w_spi_rd;
        logic [DC_SPI_DATA_WIDTH-1:0] w_spi_dout;
        logic [DC_CYCLE_WIDTH-1:0] w_cycles_left;
    } dc_output_stg_t;

    dc_output_stg_t o;

    logic w_start;
    logic w_armed;

    sequencer #(
        .INSN_WIDTH(DC_INSN_WIDTH),
        .ITER_WIDTH(DC_SEQ_ITER_WIDTH),
        .DEPTH(DC_DEPTH)
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

    dc_core #(
        .SPI_DATA_WIDTH(DC_SPI_DATA_WIDTH),
        .CYCLE_WIDTH(DC_CYCLE_WIDTH),
        .ITER_WIDTH(DC_CORE_ITER_WIDTH),
        .INSN_WIDTH(DC_INSN_WIDTH),
        .DEPTH(DC_DEPTH)
    ) CORE (
        .i_clk(w_clk),
        .i_rst(w_rst),
        .i_addr(w_addr),
        .i_insn(w_insn),
        .o_next(w_next),
        .i_empty(w_empty),
        .o_insn_modified(w_insn_modified),
        .o_sclk(w_sclk),
        .o_mosi(w_mosi),
        .i_miso(w_miso),
        .o_cs_n(w_cs_n),
        .o_ldac_n(w_ldac_n),
        .o_addr(o.w_addr),
        .o_iter(o.w_iter),
        .o_spi_din(o.w_spi_din),
        .o_spi_rd(o.w_spi_rd),
        .o_spi_dout(o.w_spi_dout),
        .o_cycles_left(o.w_cycles_left),
        .i_start(w_start),
        .o_armed(w_armed)
    );

    logic [19:0] w_vout;
    ad5791 DC_DAC (
        .SCLK(w_sclk),
        .SDIN(w_mosi),
        .SYNC_N(w_cs_n),
        .SDO(w_miso),
        .LDAC_N(w_ldac_n),
        .CLR_N(1'b1),
        .RESET_N(1'b1),
        .VOUT(w_vout)
    );

    localparam MAX_SEQ_ITERS = 10;
    localparam MAX_CORE_ITERS = 100;
    localparam MAX_CYCLES = 1000;

    dc_output_stg_t golden_seq [$];
    int num_insns;
    int total_samples;
    dc_output_stg_t out;
    dc_output_stg_t golden_o;

    dc_insn_t [0:DC_DEPTH-1] insns;
    for (genvar i = 0; i < DC_DEPTH; i++) begin : INSNS_GEN
        assign {w_regs[i*DC_REG_PER_INSN:(i+1)*DC_REG_PER_INSN-1]} = 
            {{(DC_REG_PER_INSN*32-DC_INSN_WIDTH){1'b0}}, insns[i]};
    end
    
    logic [31:0] iters_reg;
    logic [31:0] start_reg;
    assign w_regs[DC_TOTAL_REGS-2] = iters_reg;
    assign w_regs[DC_TOTAL_REGS-1] = start_reg;

    task get_golden_seq;

        if (golden_seq.size() > 0)
            golden_seq.delete();

        for (int i = 0; i < iters_reg; i++) begin

            for (int j = 0; j < num_insns; j++) begin

                for (int iter = insns[j].w_iters; iter >= 0; iter--) begin

                    for (int cycle = insns[j].w_hold_cycles; cycle >= 0; cycle--) begin

                        out.w_addr = j;
                        out.w_iter = iter;
                        // out.w_spi_din = insns[j].w_spi_din + insns[j].w_dspi_din * (insns[j].w_iters - iter);
                        out.w_spi_din = {insns[j].w_spi_din[DC_SPI_DATA_WIDTH-1:DC_DAC_WIDTH], insns[j].w_spi_din[DC_DAC_WIDTH-1:0] + 20'(insns[j].w_dspi_din * (insns[j].w_iters - iter))};
                        out.w_spi_rd = insns[j].w_spi_rd;
                        out.w_spi_dout = 'h0;
                        out.w_cycles_left = cycle;

                        golden_seq.push_back(out);

                    end

                end



            end

        end

    endtask

    task init;
        insns[0] = '{
            w_iters: 'd0,
            w_spi_dvsr: 'd4,
            w_spi_din: {1'b0, 3'b010, 10'b0, 4'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0},
            w_dspi_din: 'h0,
            w_spi_rd: 1'b0,
            w_strb_ldac: 1'b0,
            w_hold_cycles: 'h0,
            w_modify: 1'b0,
            w_arm: 1'b1
        };
        iters_reg = 32'h1;
        start_reg = 32'h0;
        @(negedge w_clk);
        start_reg = 1'b1;
        wait(w_armed);
        repeat(3) @(negedge w_clk);
        start_reg = 'd0;
        w_start = 1'b1;
        @(negedge w_clk);
        w_start = 1'b0;
    endtask

    task rand_insns;

        for (int i = 0; i < DC_DEPTH; i++) begin
            insns[i] = 'h0;
        end

        num_insns = $urandom_range(1, DC_DEPTH - 1);

        for (int i = 0; i < num_insns; i++) begin
            insns[i] = '{
                w_iters: $urandom_range(0, MAX_CORE_ITERS),
                w_spi_dvsr: 'd4,
                w_spi_din: {1'b0, 3'b001, 20'($urandom_range(0, 20'hfffff))},
                w_dspi_din: $urandom_range(0, 20'hfffff),
                w_spi_rd: 1'b0,
                w_strb_ldac: 1'b1,
                w_hold_cycles: $urandom_range(250, MAX_CYCLES),
                w_modify: 1'b0,
                w_arm: (i == 0)
            };
        end

        iters_reg = $urandom_range(1, MAX_SEQ_ITERS);
        start_reg = 32'h0;

        get_golden_seq;

        @(negedge w_clk);
        start_reg = 1'b1;

        wait(w_armed);
        $display("armed");
        repeat(3) @(negedge w_clk);
        start_reg = 'd0;
        w_start = 1'b1;
        @(negedge w_clk);
        w_start = 1'b0;

        for (int i = 0; i < golden_seq.size(); i++) begin
            golden_o = golden_seq[i];
            assert (o.w_addr == golden_seq[i].w_addr &&
                    o.w_iter == golden_seq[i].w_iter &&
                    o.w_cycles_left == golden_seq[i].w_cycles_left &&
                    o.w_spi_din == golden_seq[i].w_spi_din &&
                    w_vout == o.w_spi_din[DC_DAC_WIDTH-1:0])
            else $fatal(1, "At %0.3f ns: o = %p, golden_seq[%0d] = %p, vout = %0h", $realtime,
                        o, i, golden_seq[i], w_vout);
            @(negedge w_clk);
        end

    endtask

    initial begin
        w_clk = 1'b0;
        forever #2 w_clk = !w_clk;
    end

    int test;

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

        init;

        test = 0;
        repeat (100) begin
            $display("test%0d", test);
            rand_insns;
            test++;
        end
        $finish;
    end


endmodule
