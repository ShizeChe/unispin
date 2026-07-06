`timescale 1ns/1ps
`include "dc.svh"
`include "components/dc_if.sv"
`include "dc_uvm_pkg.sv"

module dc_tb;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // 250 MHz clock
    logic clk = 0;
    always #2 clk = ~clk;

    logic rst;

    dc_input_if  in_if  (.i_clk(clk), .i_rst(rst));
    dc_output_if out_if (.i_clk(clk), .i_rst(rst));

    logic [DC_SEQ_ITERS_WIDTH-1:0] iters;
    logic [DC_PC_ADDR_WIDTH-1:0]   pcmem_depth;
    logic [$clog2(DEPTH)-1:0]      pc_rd;

    logic sclk, mosi, miso, cs_n, ldac_n;

    dc_eop_t eop;

    dc DUT (
        .i_clk         (clk),
        .i_rst         (rst),

        .i_seq_regs    (in_if.i_seq_regs),
        .i_ctrl_regs   (in_if.i_ctrl_regs),

        .o_iters       (iters),
        .o_pcmem_depth (pcmem_depth),
        .o_pc_rd       (pc_rd),

        .o_sclk        (sclk),
        .o_mosi        (mosi),
        .i_miso        (miso),
        .o_cs_n        (cs_n),
        .o_ldac_n      (ldac_n),

        .i_start       (in_if.i_start),
        .o_armed       (in_if.o_armed),

        .o_empty       (empty),

        .o_eop         (eop)
    );

    ad5791 DAC (
    );

    initial begin
        rst = 1;
        @(posedge clk);
        rst <= 0;
    end

    initial begin
        uvm_config_db #(virtual dc_input_if)::set(null, "*", "vif", in_if);
        uvm_config_db #(virtual dc_input_if)::set(null, "*", "in_vif", in_if);
        uvm_config_db #(virtual dc_output_if)::set(null, "*", "out_vif", out_if);

        run_test();
    end
endmodule
