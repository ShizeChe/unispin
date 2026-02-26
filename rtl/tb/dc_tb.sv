`default_nettype none
`timescale 1ns / 1ps
`include "include/dc.svh"

module dc_tb;

    logic w_clk, w_rst;

    logic w_sclk;
    logic w_mosi;
    logic w_miso;
    logic w_cs_n;
    logic w_ldac_n;

    logic [0:DC_SEQ_REGS-1][31:0] w_seq_regs;
    logic [0:DC_CTRL_REGS-1][31:0] w_ctrl_regs;

    dc_eop_t w_eop;

    logic w_start;
    logic w_armed;

    logic w_empty;

    dc #(
        .SPI_DATA_WIDTH(DC_SPI_DATA_WIDTH),
        .CYCLE_WIDTH(DC_CYCLE_WIDTH),
        .SEQ_ITER_WIDTH(DC_SEQ_ITER_WIDTH),
        .CORE_ITER_WIDTH(DC_CORE_ITER_WIDTH),
        .SPI_DVSR_WIDTH(DC_SPI_DVSR_WIDTH),
        .SPI_CS_UP_WIDTH(DC_SPI_CS_UP_WIDTH),
        .SPI_LDAC_WIDTH(DC_SPI_LDAC_WIDTH),
        .DEPTH(DC_DEPTH),
        .INSN_WIDTH(DC_INSN_WIDTH),
        .REG_PER_INSN(DC_REG_PER_INSN),
        .SEQ_REGS(DC_SEQ_REGS),
        .CTRL_REGS(DC_CTRL_REGS)
    ) DC (
        .i_clk(w_clk),
        .i_rst(w_rst),

        .i_seq_regs(w_seq_regs),
        .i_ctrl_regs(w_ctrl_regs),

        .i_seq_uregs((DC_SEQ_REGS*32)'('h0)),
        .i_ctrl_uregs((DC_CTRL_REGS*32)'('h0)),

        .o_sclk(w_sclk),
        .o_mosi(w_mosi),
        .i_miso(w_miso),
        .o_cs_n(w_cs_n),
        .o_ldac_n(w_ldac_n),

        .i_start(w_start),
        .o_armed(w_armed),

        .o_empty(w_empty),

        .o_eop(w_eop)
    );

    logic [19:0] w_vout;
    real vdc;

    ad5791 DC_DAC (
        .SCLK(w_sclk),
        .SDIN(w_mosi),
        .SYNC_N(w_cs_n),
        .SDO(w_miso),
        .LDAC_N(w_ldac_n),
        .CLR_N(1'b1),
        .RESET_N(1'b1),
        .VDIGITAL(w_vout),
        .VOUT(vdc)
    );

    localparam MAX_SEQ_ITERS = 10;
    localparam MAX_CORE_ITERS = 100;
    localparam MAX_CYCLES = 2000;

    dc_eop_t golden_seq [$];
    int num_insns;
    int total_samples;
    dc_eop_t eop;
    dc_eop_t golden_eop;

    dc_insn_t [0:DC_DEPTH-1] insns;
    for (genvar i = 0; i < DC_DEPTH; i++) begin : INSNS_GEN
        assign {w_seq_regs[i*DC_REG_PER_INSN:(i+1)*DC_REG_PER_INSN-1]} = 
            {{(DC_REG_PER_INSN*32-DC_INSN_WIDTH){1'b0}}, insns[i]};
    end
    
    logic [31:0] iters_reg;
    logic [31:0] start_reg;
    assign w_seq_regs[DC_SEQ_REGS-2] = iters_reg;
    assign w_seq_regs[DC_SEQ_REGS-1] = start_reg;

    logic [DC_SPI_DVSR_WIDTH-1:0] dvsr_reg;
    logic [DC_SPI_DELAY_WIDTH-1:0] delay_reg;
    logic [DC_SPI_CS_UP_WIDTH-1:0] cs_up_reg;
    logic [DC_SPI_LDAC_WIDTH-1:0] ldac_reg;
    logic [31:0] new_ctrl_reg;
    assign w_ctrl_regs[0] = {{(32-DC_SPI_DVSR_WIDTH){1'b0}}, dvsr_reg};
    assign w_ctrl_regs[1] = {{(32-DC_SPI_DELAY_WIDTH){1'b0}}, delay_reg};
    assign w_ctrl_regs[2] = {{(32-DC_SPI_CS_UP_WIDTH){1'b0}}, cs_up_reg};
    assign w_ctrl_regs[3] = {{(32-DC_SPI_LDAC_WIDTH){1'b0}}, ldac_reg};
    assign w_ctrl_regs[4] = new_ctrl_reg;

    task get_golden_seq;

        if (golden_seq.size() > 0)
            golden_seq.delete();

        for (int i = 0; i < iters_reg; i++) begin

            for (int j = 0; j < num_insns; j++) begin

                for (int iter = insns[j].w_iters; iter >= 0; iter--) begin

                    for (int cycle = ldac_reg; cycle >= 0; cycle--) begin

                        eop.w_addr = j;
                        eop.w_iter = iter;
                        eop.w_spi_din = {insns[j].w_spi_din[DC_SPI_DATA_WIDTH-1:DC_DAC_WIDTH], insns[j].w_spi_din[DC_DAC_WIDTH-1:0] + 20'(insns[j].w_dspi_din * (insns[j].w_iters - iter))};
                        eop.w_spi_rd = insns[j].w_spi_rd;
                        eop.w_spi_dout = 'h0;
                        eop.w_ldac_cycles = cycle;
                        eop.w_cycles_left = insns[j].w_hold_cycles;

                        golden_seq.push_back(eop);

                    end

                    for (int cycle = insns[j].w_hold_cycles; cycle >= 0; cycle--) begin

                        eop.w_addr = j;
                        eop.w_iter = iter;
                        eop.w_spi_din = {insns[j].w_spi_din[DC_SPI_DATA_WIDTH-1:DC_DAC_WIDTH], insns[j].w_spi_din[DC_DAC_WIDTH-1:0] + 20'(insns[j].w_dspi_din * (insns[j].w_iters - iter))};
                        eop.w_spi_rd = insns[j].w_spi_rd;
                        eop.w_spi_dout = 'h0;
                        eop.w_ldac_cycles = 'h0;
                        eop.w_cycles_left = cycle;

                        golden_seq.push_back(eop);

                    end

                end

            end

        end

    endtask

    task init;
        $display("init");
        insns[0] = '{
            w_iters: 'd0,
            w_spi_din: {1'b0, 3'b010, 10'b0, 4'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0},
            w_dspi_din: 'h0,
            w_spi_rd: 1'b0,
            w_strb_ldac: 1'b0,
            w_hold_cycles: 'h0,
            w_modify: 1'b0,
            w_arm: 1'b1,
            w_idle: 1'b0
        };
        iters_reg = 32'h1;
        start_reg = 32'h0;
        dvsr_reg = 'd1;
        delay_reg = 'd10;
        cs_up_reg = 'd10;
        ldac_reg = 'd10;
        @(negedge w_clk);
        start_reg = 1'b1;
        new_ctrl_reg = 1'b1;
        wait(w_armed);
        repeat(3) @(negedge w_clk);
        start_reg = 'd0;
        w_start = 1'b1;
        @(negedge w_clk);
        w_start = 1'b0;
    endtask

    int min_hold_cycles;

    task rand_insns;

        dvsr_reg = $urandom_range(6, 20);
        delay_reg = $urandom_range(10, 20);
        cs_up_reg = $urandom_range(10, 20);
        ldac_reg = $urandom_range(2, 10);
        $display("dvsr_reg=%0d", dvsr_reg);
        $display("delay_reg=%0d", delay_reg);
        $display("cs_up_reg=%0d", cs_up_reg);
        $display("ldac_reg=%0d", ldac_reg);

        min_hold_cycles = (dvsr_reg + 1) * 48 + delay_reg + cs_up_reg + 10;
        $display("min_hold_cycles=%0d", min_hold_cycles);

        for (int i = 0; i < DC_DEPTH; i++) begin
            insns[i] = 'h0;
        end

        num_insns = $urandom_range(1, DC_DEPTH - 1);

        for (int i = 0; i < num_insns; i++) begin
            insns[i] = '{
                w_iters: $urandom_range(0, MAX_CORE_ITERS),
                w_spi_din: {1'b0, 3'b001, 20'($urandom_range(0, 20'hfffff))},
                w_dspi_din: $urandom_range(0, 20'hfffff),
                w_spi_rd: 1'b0,
                w_strb_ldac: 1'b1,
                w_hold_cycles: $urandom_range(min_hold_cycles, MAX_CYCLES),
                w_modify: 1'b0,
                w_arm: (i == 0),
                w_idle: 1'b0
            };
            $display("insn%0d", i);
            $display("w_iters=%0d", insns[i].w_iters);
            $display("w_spi_din=0x%0h", insns[i].w_spi_din);
            $display("w_dspi_din=0x%0h", insns[i].w_dspi_din);
            $display("w_spi_rd=0x%0h", insns[i].w_spi_rd);
            $display("w_strb_ldac=0x%0h", insns[i].w_strb_ldac);
            $display("w_hold_cycles=%0d", insns[i].w_hold_cycles);
            $display("w_modify=0x%0h", insns[i].w_modify);
            $display("w_arm=0x%0h\n", insns[i].w_arm);
        end

        iters_reg = $urandom_range(1, MAX_SEQ_ITERS);
        start_reg = 32'h0;
        new_ctrl_reg = 32'h0;

        get_golden_seq;

        @(negedge w_clk);
        start_reg = 32'b1;
        new_ctrl_reg = 32'b1;

        wait(w_armed);
        $display("armed");
        repeat(3) @(negedge w_clk);
        start_reg = 'd0;
        new_ctrl_reg = 'd0;
        w_start = 1'b1;
        @(negedge w_clk);
        w_start = 1'b0;

        for (int i = 0; i < golden_seq.size(); i++) begin
            golden_eop = golden_seq[i];
            assert (w_eop.w_addr == golden_seq[i].w_addr &&
                    w_eop.w_iter == golden_seq[i].w_iter &&
                    w_eop.w_cycles_left == golden_seq[i].w_cycles_left &&
                    w_eop.w_spi_din == golden_seq[i].w_spi_din &&
                    w_vout == w_eop.w_spi_din[DC_DAC_WIDTH-1:0])
            else $fatal(1, "At %0.3f ns: o = %p, golden_seq[%0d] = %p, vout = %0h", $realtime,
                        w_eop, i, golden_seq[i], w_vout);
            @(negedge w_clk);
        end

    endtask

    task fixed_insns;

        dvsr_reg = 'd6;
        delay_reg = 'd10;
        cs_up_reg = 'd10;
        ldac_reg = 'd2;

        insns[0] = '{
            w_iters: 'd0,
            w_spi_din: 'h0,
            w_dspi_din: 'h0,
            w_spi_rd: 1'b0,
            w_strb_ldac: 1'b0,
            w_hold_cycles: 'd2,
            w_modify: 1'b0,
            w_arm: 1'b1,
            w_idle: 1'b1
        };

        insns[1] = '{
            w_iters: 'd0,
            w_spi_din: {4'b0001, 20'h2000},
            w_dspi_din: 'h0,
            w_spi_rd: 1'b0,
            w_strb_ldac: 1'b1,
            w_hold_cycles: 'd500,
            w_modify: 1'b0,
            w_arm: 1'b0,
            w_idle: 1'b0
        };

        insns[2] = '{
            w_iters: 'd0,
            w_spi_din: 'h0,
            w_dspi_din: 'h0,
            w_spi_rd: 1'b0,
            w_strb_ldac: 1'b0,
            w_hold_cycles: 'd2,
            w_modify: 1'b0,
            w_arm: 1'b0,
            w_idle: 1'b1
        };

        insns[3] = '{
            w_iters: 'd0,
            w_spi_din: {4'b0001, 20'h4000},
            w_dspi_din: 'h0,
            w_spi_rd: 1'b0,
            w_strb_ldac: 1'b1,
            w_hold_cycles: 'd500,
            w_modify: 1'b0,
            w_arm: 1'b0,
            w_idle: 1'b0
        };

        insns[4] = '{
            w_iters: 'd0,
            w_spi_din: {4'b0001, 20'h6000},
            w_dspi_din: 'h0,
            w_spi_rd: 1'b0,
            w_strb_ldac: 1'b1,
            w_hold_cycles: 'd500,
            w_modify: 1'b0,
            w_arm: 1'b0,
            w_idle: 1'b0
        };

        insns[5] = '{
            w_iters: 'd0,
            w_spi_din: 'h0,
            w_dspi_din: 'h0,
            w_spi_rd: 1'b0,
            w_strb_ldac: 1'b0,
            w_hold_cycles: 'd2,
            w_modify: 1'b0,
            w_arm: 1'b0,
            w_idle: 1'b1
        };

        insns[6] = '{
            w_iters: 'd0,
            w_spi_din: 'h0,
            w_dspi_din: 'h0,
            w_spi_rd: 1'b0,
            w_strb_ldac: 1'b0,
            w_hold_cycles: 'd10,
            w_modify: 1'b0,
            w_arm: 1'b0,
            w_idle: 1'b1
        };

        insns[7] = '{
            w_iters: 'd0,
            w_spi_din: {4'b0001, 20'h8000},
            w_dspi_din: 'h0,
            w_spi_rd: 1'b0,
            w_strb_ldac: 1'b1,
            w_hold_cycles: 'd500,
            w_modify: 1'b0,
            w_arm: 1'b0,
            w_idle: 1'b0
        };

        iters_reg = 3;
        start_reg = 32'h0;
        new_ctrl_reg = 32'h0;

        @(negedge w_clk);
        start_reg = 32'b1;
        new_ctrl_reg = 32'b1;

        wait(w_armed);
        $display("armed");
        repeat(3) @(negedge w_clk);
        start_reg = 'd0;
        new_ctrl_reg = 'd0;
        w_start = 1'b1;
        @(negedge w_clk);
        w_start = 1'b0;

    endtask

    initial begin
        w_clk = 1'b0;
        forever #2 w_clk = !w_clk;
    end

    int test;

    initial begin
        w_rst = 1'b1;
        w_start = 1'b0;
        for (int i = 0; i < DC_DEPTH; i++) begin
            insns[i] = 'h0;
        end
        iters_reg = 32'h0;
        start_reg = 32'h0;
        new_ctrl_reg = 32'h0;
        @(negedge w_clk);
        w_rst = 1'b0;

        init;
        $display("init finished");

        // test = 0;
        // repeat (10) begin
        //     $display("test%0d", test);
        //     rand_insns;
        //     test++;
        // end
        fixed_insns;
        wait(w_empty);
        $finish;
    end

endmodule
