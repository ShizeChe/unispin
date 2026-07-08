`timescale 1ns / 1ps
`include "uvm_macros.svh"


import uvm_pkg::*;


// ex interface -- ex has no control register bank (no ex_ctrl_t), so
// ex_input_if carries only i_seq_regs (unlike dc/rf/li).
interface ex_input_if(input i_clk, input i_rst);
    logic [0:EX_SEQ_REGS-1][31:0] i_seq_regs;

    logic i_start;
    logic o_armed;

    clocking cb @(posedge i_clk);
        default input #1step output #0;
        input o_armed;
        output i_rst, i_seq_regs, i_start;
    endclocking
endinterface

interface ex_output_if(input i_clk, input i_rst);
    logic o_empty;
    ex_eop_t o_eop;

    clocking cb @(posedge i_clk);
        default input #1step output #0;
        input o_empty, o_eop;
        output i_rst;
    endclocking
endinterface


module ex_tb;

    // 250 MHz clock
    logic clk = 0;
    always #2 clk = ~clk;

    logic rst;

    ex_input_if  in_if  (.i_clk(clk), .i_rst(rst));
    ex_output_if out_if (.i_clk(clk), .i_rst(rst));

    logic [EX_ITER_WIDTH-1:0]    iters;
    logic [EX_PC_ADDR_WIDTH-1:0] pcmem_depth;
    logic [$clog2(EX_DEPTH)-1:0] pc_rd;

    logic [EX_DAC_WIDTH*16-1:0] realx16;

    ex DUT (
        .i_clk         (clk),
        .i_rst         (rst),

        .i_seq_regs    (in_if.i_seq_regs),

        .o_insn_rd     (),

        .o_iters       (iters),
        .o_pcmem_depth (pcmem_depth),
        .o_pc_rd       (pc_rd),

        .o_realx16     (realx16),

        .i_start       (in_if.i_start),
        .o_armed       (in_if.o_armed),

        .o_empty       (out_if.o_empty),

        .o_marker      (),

        .o_eop         (out_if.o_eop)
    );

    initial begin
        rst = 1;
        @(posedge clk);
        rst <= 0;
    end

    initial begin
        uvm_config_db #(virtual ex_input_if)::set(null, "uvm_test_top.env.agt.drv", "vif", in_if);
        uvm_config_db #(virtual ex_output_if)::set(null, "uvm_test_top.env.agt.mon", "vif", out_if);

        run_test();
    end
endmodule
