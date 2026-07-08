`timescale 1ns / 1ps
`include "uvm_macros.svh"


import uvm_pkg::*;


// li interface
interface li_input_if(input i_clk, input i_rst);
    logic [0:LI_SEQ_REGS-1][31:0] i_seq_regs;
    logic [0:LI_CTRL_REGS-1][31:0] i_ctrl_regs;

    // ADC sample stream into li -- no VIP models real ADC data yet, so
    // this is just tied to a fixed value by li_driver.
    logic [LI_ADC_WIDTH*8-1:0] i_QIx4;

    logic i_start;
    logic o_armed;

    clocking cb @(posedge i_clk);
        default input #1step output #0;
        input o_armed;
        output i_rst, i_seq_regs, i_ctrl_regs, i_QIx4, i_start;
    endclocking
endinterface

interface li_output_if(input i_clk, input i_rst);
    logic o_empty;
    li_eop_t o_eop;

    clocking cb @(posedge i_clk);
        default input #1step output #0;
        input o_empty, o_eop;
        output i_rst;
    endclocking
endinterface


module li_tb;

    // 250 MHz clock
    logic clk = 0;
    always #2 clk = ~clk;

    logic rst;

    li_input_if  in_if  (.i_clk(clk), .i_rst(rst));
    li_output_if out_if (.i_clk(clk), .i_rst(rst));

    logic [LI_ITER_WIDTH-1:0]    iters;
    logic [LI_PC_ADDR_WIDTH-1:0] pcmem_depth;
    logic [$clog2(LI_DEPTH)-1:0] pc_rd;

    logic [3:0] sample_mask;

    logic [LI_ADC_WIDTH*8-1:0]        QIx4;
    logic [LI_SAMPLE_TAG_WIDTH*4-1:0] tagx4;
    logic [3:0]                      validx4;
    logic                            last;

    li_ctrl_t ctrl;

    li DUT (
        .i_clk         (clk),
        .i_rst         (rst),

        .i_seq_regs    (in_if.i_seq_regs),
        .i_ctrl_regs   (in_if.i_ctrl_regs),

        .o_insn_rd     (),

        .o_iters       (iters),
        .o_pcmem_depth (pcmem_depth),
        .o_pc_rd       (pc_rd),

        .i_QIx4        (in_if.i_QIx4),

        .o_sample_mask (sample_mask),

        .o_QIx4        (QIx4),
        .o_tagx4       (tagx4),
        .o_validx4     (validx4),
        .o_last        (last),

        .i_start       (in_if.i_start),
        .o_armed       (in_if.o_armed),

        .o_empty       (out_if.o_empty),

        .o_marker      (),

        .o_ctrl        (ctrl),

        .o_eop         (out_if.o_eop)
    );

    initial begin
        rst = 1;
        @(posedge clk);
        rst <= 0;
    end

    initial begin
        uvm_config_db #(virtual li_input_if)::set(null, "uvm_test_top.env.agt.drv", "vif", in_if);
        uvm_config_db #(virtual li_output_if)::set(null, "uvm_test_top.env.agt.mon", "vif", out_if);

        run_test();
    end
endmodule
