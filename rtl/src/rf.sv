// `default_nettype none
`timescale 1ns / 1ps
`include "rf.svh"

module rf
   #(parameter KBC_WIDTH=RF_KBC_WIDTH,
     parameter ITER_WIDTH=RF_ITER_WIDTH,
     parameter NUM_SAMPLE_WIDTH=RF_NUM_SAMPLE_WIDTH,
     parameter INSN_WIDTH=RF_INSN_WIDTH,
     parameter IQ_WIDTH=RF_IQ_WIDTH,
     parameter DAC_WIDTH=RF_DAC_WIDTH,
     parameter PHASE_WIDTH=RF_PHASE_WIDTH,
     parameter CORDIC_STAGES=RF_CORDIC_STAGES,
     parameter CORDIC_PAD_ZEROS=RF_CORDIC_PAD_ZEROS,
     parameter DEPTH=RF_DEPTH,
     parameter NCO_FREQ_WIDTH=RF_NCO_FREQ_WIDTH,
     parameter NCO_PHASE_WIDTH=RF_NCO_PHASE_WIDTH,
     parameter NCO_EN_WIDTH=RF_NCO_EN_WIDTH,
     parameter SEQ_REGS=RF_SEQ_REGS,
     parameter CTRL_REGS=RF_CTRL_REGS)
    (input  logic i_clk, i_rst,

     input  logic [0:SEQ_REGS-1][31:0] i_seq_regs,
     input  logic [0:CTRL_REGS-1][31:0] i_ctrl_regs,

     input  logic [0:SEQ_REGS-1][31:0] i_seq_uregs,
     input  logic [0:CTRL_REGS-1][31:0] i_ctrl_uregs,

     output logic [DAC_WIDTH*16-1:0] o_QIx8,

     input  logic i_start,
     output logic o_armed,
     
     output logic o_empty,

     // nco interface
     input  logic i_nco_wait,
     output logic o_nco_wait,

     output logic o_nco_req,
     input  logic i_nco_busy,
     output logic [NCO_FREQ_WIDTH-1:0] o_nco_freq,
     output logic [NCO_PHASE_WIDTH-1:0] o_nco_phase,
     output logic [NCO_EN_WIDTH-1:0] o_nco_en,

     // eop for verification
     output rf_eop_t o_eop);

    logic w_next, w_empty;
    logic [$clog2(DEPTH)-1:0] w_addr;
    rf_insn_t w_insn, w_insn_modified;

    sequencer #(
        .INSN_WIDTH(INSN_WIDTH),
        .ITER_WIDTH(ITER_WIDTH),
        .DEPTH(DEPTH)
    ) SEQ (
        .i_clk(i_clk),
        .i_rst(i_rst),

        .i_regs(i_seq_regs),
        .i_uregs(i_seq_uregs),

        .o_addr(w_addr),
        .o_insn(w_insn),
        .i_next(w_next),
        .o_empty(w_empty),
        .i_insn_modified(w_insn_modified)
    );

    rf_ctrl_t w_ctrl;

    rf_core #(
    	.KBC_WIDTH(KBC_WIDTH),
    	.NUM_SAMPLE_WIDTH(NUM_SAMPLE_WIDTH),
    	.INSN_WIDTH(RF_INSN_WIDTH),
        .IQ_WIDTH(IQ_WIDTH),
    	.DAC_WIDTH(DAC_WIDTH),
    	.PHASE_WIDTH(PHASE_WIDTH),
    	.CORDIC_STAGES(CORDIC_STAGES),
    	.CORDIC_PAD_ZEROS(CORDIC_PAD_ZEROS),
        .DEPTH(DEPTH)
    ) CORE (
        .i_clk(i_clk),
        .i_rst(i_rst),

        .i_addr(w_addr),
        .i_insn(w_insn),
        .o_next(w_next),
        .i_empty(w_empty),
        .o_insn_modified(w_insn_modified),

        .i_ctrl(w_ctrl),

        .o_QIx8(o_QIx8),

        .i_start(i_start),
        .o_armed(o_armed),

        .o_empty(o_empty),

        .o_eop(o_eop)
    );

    rf_ctrl #(
        .CTRL_REGS(CTRL_REGS),
        .NCO_FREQ_WIDTH(NCO_FREQ_WIDTH),
        .NCO_PHASE_WIDTH(NCO_PHASE_WIDTH),
        .NCO_EN_WIDTH(NCO_EN_WIDTH),
        .IQ_WIDTH(IQ_WIDTH)
    ) CTRL (
        .i_clk(i_clk),
        .i_rst(i_rst),

        .i_regs(i_ctrl_regs),
        .i_uregs(i_ctrl_uregs),

        .o_ctrl(w_ctrl),

        .i_running(!o_empty),
        .i_nco_wait(i_nco_wait),
        .o_nco_wait(o_nco_wait),

        .o_nco_req(o_nco_req),
        .i_nco_busy(i_nco_busy),
        .o_nco_freq(o_nco_freq),
        .o_nco_phase(o_nco_phase),
        .o_nco_en(o_nco_en)
    );

endmodule
