// `default_nettype none
`timescale 1ns / 1ps

module bram_sequencer
   #(parameter PC_ADDR_WIDTH=12,
     parameter PC_WIDTH=9,
     parameter INSN_WIDTH=115,
     parameter REG_PER_INSN=(INSN_WIDTH+31)/32,
     parameter ITER_WIDTH=16,
     parameter SEQ_REGS=REG_PER_INSN+3)
    (input  logic i_clk, i_rst,

     input  logic [0:SEQ_REGS-1][31:0] i_regs,

     output logic [PC_ADDR_WIDTH-1:0] o_pc_addr,
     output logic [PC_WIDTH-1:0] o_pc,
     output logic [INSN_WIDTH-1:0] o_insn,
     input  logic i_next,
     output logic o_empty,
     input  logic [INSN_WIDTH-1:0] i_insn_modified);

    /*************
    * pcmem store
    *************/

    logic [PC_ADDR_WIDTH-1:0] w_pc_addr;
    logic [PC_WIDTH-1:0] w_pc;
    logic w_wr_pc, w_pcmem_wr;

    assign w_pc_addr = i_regs[0][PC_ADDR_WIDTH-1:0];
    assign w_pc = i_regs[1][PC_WIDTH-1:0];
    assign w_wr_pc = i_regs[2][0];

    edge_detector ED (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_signal(w_wr_pc),
        .o_posedge(w_pcmem_wr),
        .o_negedge()
    );

    bram #(
        .DATA_WIDTH(PC_WIDTH),
        .ADDR_WIDTH(PC_ADDR_WIDTH),
    ) PCMEM (
        .i_clk_a(i_clk),
        .i_wr_a(w_pcmem_wr),
        .i_addr_a(w_pc_addr),
        .i_din_a(w_pc),
        .o_dout_a(),

        .i_clk_b(i_clk),
        .i_wr_b(),
        .i_addr_b(),
        .i_din_b(),
        .o_dout_b()
    );

    /************
    * imem store
    ************/

    logic [PC_WIDTH-1:0] w_insn_addr;
    logic [INSN_WIDTH-1:0] w_insn;
    logic w_wr_insn, w_imem_wr;

    assign w_insn_addr = i_regs[3][PC_WIDTH-1:0];
    assign w_insn = {i_regs[4:4+REG_PER_INSN-1]}[INSN_WIDTH-1:0];
    assign w_wr_insn = i_regs[4+REG_PER_INSN][0];

    edge_detector ED (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_signal(w_wr_insn),
        .o_posedge(w_imem_wr),
        .o_negedge()
    );

    bram #(
        .DATA_WIDTH(INSN_WIDTH),
        .ADDR_WIDTH(PC_WIDTH),
    ) IMEM (
        .i_clk_a(i_clk),
        .i_wr_a(w_imem_wr),
        .i_addr_a(w_insn_addr),
        .i_din_a(w_insn),
        .o_dout_a(),

        .i_clk_b(i_clk),
        .i_wr_b(),
        .i_addr_b(),
        .i_din_b(),
        .o_dout_b()
    );

    /**********
    * pc stage
    **********/

    typedef struct {
        logic [PC_ADDR_WIDTH-1:0] r_pc_addr;
        logic [ITER_WIDTH-1:0] r_iters;
        logic [DEPTH_WIDTH-1:0] r_depth;
    } pc_stg_t;

    pc_stg_t p;

    /************
    * insn stage
    ************/

    typedef struct {
        logic [PC_ADDR_WIDTH-1:0] r_pc_addr;
        logic [PC_WIDTH-1:0] w_pc;
        logic [PC_WIDTH-1:0] r_pc;
        logic r_pc_buffered;
    } insn_stg_t;

    insn_stg_t i;

    /***********
    * out stage
    ***********/

endmodule
