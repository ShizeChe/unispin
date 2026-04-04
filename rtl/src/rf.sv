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
     parameter SEQ_REGS=RF_SEQ_REGS,
     parameter CTRL_REGS=RF_CTRL_REGS,
     parameter STATUS_REGS=RF_STATUS_REGS,
     parameter STATUS_FFS=5)
    (input  logic i_clk, i_rst,

     input  logic [0:SEQ_REGS-1][31:0] i_seq_regs,
     input  logic [0:CTRL_REGS-1][31:0] i_ctrl_regs,
     output logic [0:STATUS_REGS-1][31:0] o_status_regs,

     output logic [DAC_WIDTH*16-1:0] o_QIx8,

     input  logic i_start,
     output logic o_armed,
     
     output logic o_empty,

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
        .IQ_WIDTH(IQ_WIDTH)
    ) CTRL (
        .i_clk(i_clk),
        .i_rst(i_rst),

        .i_regs(i_ctrl_regs),

        .o_ctrl(w_ctrl)
    );

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            o_status_regs[0] <= 'b11;
        end
        else begin
            o_status_regs[0] <= {
                {(32-3){1'b0}}, 
                o_armed, w_empty, o_empty
            };
        end
    end

    logic [2:0] r_status_ffs [STATUS_FFS];

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            r_status_ffs[0] <= 'h0;
        end
        else begin
            r_status_ffs[0] <= {
                {(32-3){1'b0}}, 
                o_armed, w_empty, o_empty
            };
        end
    end

    for (genvar i = 1; i < STATUS_FFS; i++) begin : STATUS_FF_GEN
        always_ff @(posedge i_clk) begin
            if (i_rst) begin
                r_status_ffs[i] <= 'h0;
            end
            else begin
                r_status_ffs[i] <= r_status_ffs[i - 1];
            end
        end
    end

    assign o_status_regs[0] = {{(32-3){1'b0}}, r_status_ffs[STATUS_FFS-1]};

endmodule
