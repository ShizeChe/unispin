`default_nettype none
`timescale 1ns / 1ps
`include "include/li.svh"

module li_tb;

    logic w_clk, w_rst;

    logic [0:LI_SEQ_REGS-1][31:0] w_seq_regs;
    // logic [0:LI_CTRL_REGS-1][31:0] w_ctrl_regs;

    logic [LI_ADC_WIDTH*8-1:0] w_Ix8_in;
    logic [LI_ADC_WIDTH*8-1:0] w_Qx8_in;

    logic [LI_ADC_WIDTH*8-1:0] w_Ix8_out;
    logic [LI_ADC_WIDTH*8-1:0] w_Qx8_out;
    logic [7:0] w_validx8;
    logic w_last;

    logic w_start;
    logic w_armed;
     
    logic w_empty;

    li_eop_t w_eop;

    li #(
        .NUM_SAMPLE_WIDTH(LI_NUM_SAMPLE_WIDTH),
        .STRIDE_WIDTH(LI_STRIDE_WIDTH),
        .INSN_WIDTH(LI_INSN_WIDTH),
        .DEPTH(LI_DEPTH),
        .ADC_WIDTH(LI_ADC_WIDTH),
        .SEQ_REGS(LI_SEQ_REGS),
        .CTRL_REGS(LI_CTRL_REGS)
    ) LI (
        .i_clk(w_clk),
        .i_rst(w_rst),

        .i_seq_regs(w_seq_regs),
        .i_ctrl_regs({(LI_CTRL_REGS*32){1'b0}}),

        .i_seq_uregs({(LI_SEQ_REGS*32){1'b0}}),
        .i_ctrl_uregs({(LI_CTRL_REGS*32){1'b0}}),

        .i_Ix8(w_Ix8_in),
        .i_Qx8(w_Qx8_in),

        .o_Ix8(w_Ix8_out),
        .o_Qx8(w_Qx8_out),
        .o_validx8(w_validx8),
        .o_last(w_last),

        .i_start(w_start),
        .o_armed(w_armed),

        .o_empty(w_empty),
        
        .o_eop(w_eop)
    );

    initial begin
        w_clk = 1'b0;
        forever #2 w_clk = !w_clk;
    end

    li_insn_t [0:LI_DEPTH-1] insns;
    for (genvar i = 0; i < LI_DEPTH; i++) begin : INSNS_GEN
        assign {w_seq_regs[i*LI_REG_PER_INSN:(i+1)*LI_REG_PER_INSN-1]} = 
            {{(LI_REG_PER_INSN*32-LI_INSN_WIDTH){1'b0}}, insns[i]};
    end
    
    logic [31:0] iters_reg;
    logic [31:0] start_reg;
    assign w_seq_regs[LI_SEQ_REGS-2] = iters_reg;
    assign w_seq_regs[LI_SEQ_REGS-1] = start_reg;

    initial begin

        w_rst = 1'b1;
        for (int i = 0; i < LI_DEPTH; i++) begin
            insns[i] = 'h0;
        end
        w_Ix8_in = 'h0;
        w_Qx8_in = 'h0;
        w_start = 1'b0;
        @(negedge w_clk);
        w_rst = 1'b0;

        insns[0] = '{
            w_arm: 1'b1,
            w_idle: 1'b0,
            w_samples: 'd1024,
            w_dsamples: 'd0,
            w_stride: 'd3
        };

        insns[1] = '{
            w_arm: 1'b0,
            w_idle: 1'b1,
            w_samples: 'd500,
            w_dsamples: 'd0,
            w_stride: 'd3
        };

        insns[2] = '{
            w_arm: 1'b0,
            w_idle: 1'b0,
            w_samples: 'd900,
            w_dsamples: 'd0,
            w_stride: 'd15
        };

        iters_reg = 'd1;
        start_reg = 'h0;
        @(negedge w_clk);
        start_reg = 'h1;

        wait(w_armed);
        @(negedge w_clk);
        w_start = 1'b1;
        w_Ix8_in = {
            16'd7,
            16'd6,
            16'd5,
            16'd4,
            16'd3,
            16'd2,
            16'd1,
            16'd0
        };
        w_Qx8_in = {
            16'd7,
            16'd6,
            16'd5,
            16'd4,
            16'd3,
            16'd2,
            16'd1,
            16'd0
        };
        for (int i = 1; i < 5000; i++) begin
            @(negedge w_clk);
            w_start = 1'b0;
            w_Ix8_in = {
                16'(i * 8 + 7),
                16'(i * 8 + 6),
                16'(i * 8 + 5),
                16'(i * 8 + 4),
                16'(i * 8 + 3),
                16'(i * 8 + 2),
                16'(i * 8 + 1),
                16'(i * 8)
            };
            w_Qx8_in = {
                16'(i * 8 + 7),
                16'(i * 8 + 6),
                16'(i * 8 + 5),
                16'(i * 8 + 4),
                16'(i * 8 + 3),
                16'(i * 8 + 2),
                16'(i * 8 + 1),
                16'(i * 8)
            };
        end
        $finish;

    end

endmodule
