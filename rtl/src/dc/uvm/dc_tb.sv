`timescale 1ns / 1ps
`include "uvm_macros.svh"


import uvm_pkg::*;


// dc interface
interface dc_input_if(input i_clk, input i_rst);
    logic [0:DC_SEQ_REGS-1][31:0] i_seq_regs;
    logic [0:DC_CTRL_REGS-1][31:0] i_ctrl_regs;

    logic i_start;
    logic o_armed;

    clocking cb @(posedge i_clk);
        default input #1step output #0;
        input o_armed;
        output i_rst, i_seq_regs, i_ctrl_regs, i_start;
    endclocking
endinterface

interface dc_output_if(input i_clk, input i_rst);
    logic o_empty;
    dc_eop_t o_eop;

    clocking cb @(posedge i_clk);
        default input #1step output #0;
        input o_empty, o_eop;
        output i_rst;
    endclocking
endinterface

interface dc_dac_output_if();
    logic [DC_DAC_WIDTH-1:0] vdigital;
endinterface


module dc_tb;

    // 250 MHz clock
    logic clk = 0;
    always #2 clk = ~clk;

    logic rst;

    dc_input_if      in_if  (.i_clk(clk), .i_rst(rst));
    dc_output_if     out_if (.i_clk(clk), .i_rst(rst));
    dc_dac_output_if dac_if ();

    logic [DC_SEQ_ITER_WIDTH-1:0] iters;
    logic [DC_PC_ADDR_WIDTH-1:0]  pcmem_depth;
    logic [$clog2(DC_DEPTH)-1:0]  pc_rd;

    logic sclk, mosi, miso, cs_n, ldac_n;

    dc DUT (
        .i_clk         (clk),
        .i_rst         (rst),

        .i_seq_regs    (in_if.i_seq_regs),
        .i_ctrl_regs   (in_if.i_ctrl_regs),

        .o_insn_rd     (),

        .o_iters       (iters),
        .o_pcmem_depth (pcmem_depth),
        .o_pc_rd       (pc_rd),

        .o_sclk        (sclk),
        .o_mosi        (mosi),
        .i_miso        (miso),
        .o_cs_n        (cs_n),
        .o_ldac_n      (ldac_n),

        .o_marker      (),

        .i_start       (in_if.i_start),
        .o_armed       (in_if.o_armed),

        .o_empty       (out_if.o_empty),

        .o_eop         (out_if.o_eop)
    );

    ad5791 DAC (
        .SCLK     (sclk),
        .SDIN     (mosi),
        .SYNC_N   (cs_n),
        .SDO      (miso),
        .LDAC_N   (ldac_n),
        .CLR_N    (1'b1),
        .RESET_N  (1'b1),

        .VDIGITAL (dac_if.vdigital),
        .VOUT     ()
    );

    initial begin
        rst = 1;
        @(posedge clk);
        rst <= 0;
    end

    initial begin
        uvm_config_db #(virtual dc_input_if)::set(null, "uvm_test_top.env.agt.drv", "vif", in_if);
        uvm_config_db #(virtual dc_output_if)::set(null, "uvm_test_top.env.agt.mon", "vif", out_if);
        uvm_config_db #(virtual dc_dac_output_if)::set(null, "uvm_test_top.env.agt.mon", "vif_dac", dac_if);

        run_test();
    end
endmodule
