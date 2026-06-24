// `default_nettype none
`timescale 1ns / 1ps
`include "launch.svh"

module launch
   #(parameter NUM_DC_CHANNEL=24,
     parameter NUM_RF_CHANNEL=6,
     parameter NUM_LI_CHANNEL=2,
     parameter NUM_EX_CHANNEL=2,
     parameter CTRL_REGS=LCH_CTRL_REGS,
     parameter STATUS_REGS=LCH_STATUS_REGS)
    (input  logic i_clk, i_rst,

     input  logic [0:LCH_CTRL_REGS-1][31:0] i_ctrl_regs,
     output logic [0:LCH_STATUS_REGS-1][31:0] o_status_regs,

     input  logic [NUM_DC_CHANNEL-1:0] i_dc_armed,
     input  logic [NUM_RF_CHANNEL-1:0] i_rf_armed,
     input  logic [NUM_LI_CHANNEL-1:0] i_li_armed,
     input  logic [NUM_EX_CHANNEL-1:0] i_ex_armed,

     input  logic i_trigger,

     output logic [NUM_DC_CHANNEL-1:0] o_dc_start,
     output logic [NUM_RF_CHANNEL-1:0] o_rf_start,
     output logic [NUM_LI_CHANNEL-1:0] o_li_start,
     output logic [NUM_EX_CHANNEL-1:0] o_ex_start);

    logic w_new_ctrl;

    edge_detector CTRLWR (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_signal(i_ctrl_regs[LCH_CTRL_REGS-1][0]),
        .o_posedge(w_new_ctrl),
        .o_negedge()
    );

    logic w_clear;

    edge_detector CLR (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_signal(i_ctrl_regs[LCH_CTRL_REGS-2][0]),
        .o_posedge(w_clear),
        .o_negedge()
    );

    logic [NUM_DC_CHANNEL-1:0] r_dc_active_mask;
    logic [NUM_RF_CHANNEL-1:0] r_rf_active_mask;
    logic [NUM_LI_CHANNEL-1:0] r_li_active_mask;
    logic [NUM_EX_CHANNEL-1:0] r_ex_active_mask;
    logic r_use_trigger;
    logic [LCH_ITER_WIDTH-1:0] r_iters;

    logic w_all_ready;

    always_ff @(posedge i_clk) begin
        if (i_rst || w_clear) begin
            r_dc_active_mask <= 'h0;
            r_rf_active_mask <= 'h0;
            r_li_active_mask <= 'h0;
            r_ex_active_mask <= 'h0;
            r_use_trigger    <= 1'b0;
            r_iters          <= 'h0;
        end
        else if (w_new_ctrl) begin
            r_dc_active_mask <= i_ctrl_regs[0][NUM_DC_CHANNEL-1:0];
            r_rf_active_mask <= i_ctrl_regs[1][NUM_RF_CHANNEL-1:0];
            r_li_active_mask <= i_ctrl_regs[2][NUM_LI_CHANNEL-1:0];
            r_ex_active_mask <= i_ctrl_regs[3][NUM_EX_CHANNEL-1:0];
            r_use_trigger    <= i_ctrl_regs[4][0];
            r_iters          <= i_ctrl_regs[5][LCH_ITER_WIDTH-1:0];
        end
        else if (w_all_ready) begin
            r_iters <= (r_iters > 'd0) ? (r_iters - 'd1) : r_iters;
        end
    end

    logic [NUM_DC_CHANNEL-1:0] r_dc_armed;
    logic [NUM_RF_CHANNEL-1:0] r_rf_armed;
    logic [NUM_LI_CHANNEL-1:0] r_li_armed;
    logic [NUM_EX_CHANNEL-1:0] r_ex_armed;

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            r_dc_armed <= 'h0;
            r_rf_armed <= 'h0;
            r_li_armed <= 'h0;
            r_ex_armed <= 'h0;
        end
        else begin
            r_dc_armed <= i_dc_armed;
            r_rf_armed <= i_rf_armed;
            r_li_armed <= i_li_armed;
            r_ex_armed <= i_ex_armed;
        end
    end

    logic w_dc_ready, w_rf_ready, w_li_ready, w_ex_ready;
    assign w_dc_ready = ((r_dc_active_mask ^ r_dc_armed) == 'h0);
    assign w_rf_ready = ((r_rf_active_mask ^ r_rf_armed) == 'h0);
    assign w_li_ready = ((r_li_active_mask ^ r_li_armed) == 'h0);
    assign w_ex_ready = ((r_ex_active_mask ^ r_ex_armed) == 'h0);

    enum {IDLE, ARM, LAUNCH, DELAY1, DELAY2} r_state, w_next_state;

    always_ff @(posedge i_clk) begin
        r_state <= (i_rst || w_clear) ? IDLE : w_next_state;
    end

    assign w_all_ready = (r_state == ARM) &&
        w_dc_ready && w_rf_ready && w_li_ready && w_ex_ready &&
        (!r_use_trigger || i_trigger);

    logic w_start;
    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            o_dc_start <= 'h0;
            o_rf_start <= 'h0;
            o_li_start <= 'h0;
            o_ex_start <= 'h0;
        end
        else if (w_start) begin
            o_dc_start <= r_dc_active_mask;
            o_rf_start <= r_rf_active_mask;
            o_li_start <= r_li_active_mask;
            o_ex_start <= r_ex_active_mask;
        end
        else begin
            o_dc_start <= 'h0;
            o_rf_start <= 'h0;
            o_li_start <= 'h0;
            o_ex_start <= 'h0;
        end
    end

    always_comb begin

        w_start = 1'b0;

        case (r_state)
            IDLE: begin
                w_next_state = (r_iters > 'd0) ? ARM : IDLE;
            end
            ARM: begin
                w_next_state = w_all_ready ? LAUNCH : ARM;
                w_start = w_all_ready;
            end
            LAUNCH: begin
                w_next_state = DELAY1;
            end
            DELAY1: begin
                w_next_state = DELAY2;
            end
            DELAY2: begin
                w_next_state = IDLE;
            end
            default: begin
                w_next_state = IDLE;
            end
        endcase

    end

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            o_status_regs[0] <= 'b0;
            o_status_regs[1] <= 'b0;
        end
        else begin
            o_status_regs[0] <= {31'h0, r_state != IDLE};
            o_status_regs[1] <= {{(32-LCH_ITER_WIDTH){1'b0}}, r_iters};
        end
    end

endmodule
