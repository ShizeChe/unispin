`timescale 1ns / 1ps

module launcher
   #(NUM_DC_CHANNEL=24,
     NUM_RF_CHANNEL=7,
     NUM_LI_CHANNEL=2)
    (input  logic i_clk, i_rst,

     input  logic [3:0][31:0] i_regs,

     input  logic [NUM_DC_CHANNEL-1:0] i_dc_armed,
     input  logic [NUM_RF_CHANNEL-1:0] i_rf_armed,
     input  logic [NUM_LI_CHANNEL-1:0] i_li_armed,

     output logic [NUM_DC_CHANNEL-1:0] o_dc_start,
     output logic [NUM_RF_CHANNEL-1:0] o_rf_start,
     output logic [NUM_LI_CHANNEL-1:0] o_li_start);

    logic w_last0, w_last0_ff1, w_last0_ff2;

    assign w_last0 = (i_regs[3] == 'h0);

    always_ff @(posedge i_clk) begin
        w_last0_ff1 <= w_last0;
        w_last0_ff2 <= w_last0_ff1;
    end

    logic w_new_stream;
    assign w_new_stream = (w_last0_ff2 && !w_last0_ff1);

    logic [NUM_DC_CHANNEL-1:0] r_dc_active_mask;
    logic [NUM_RF_CHANNEL-1:0] r_rf_active_mask;
    logic [NUM_LI_CHANNEL-1:0] r_li_active_mask;

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            r_dc_active_mask <= 'h0;
            r_rf_active_mask <= 'h0;
            r_li_active_mask <= 'h0;
        end
        else if (w_new_stream) begin
            r_dc_active_mask <= i_regs[0][NUM_DC_CHANNEL-1:0];
            r_rf_active_mask <= i_regs[1][NUM_RF_CHANNEL-1:0];
            r_li_active_mask <= i_regs[2][NUM_LI_CHANNEL-1:0];
        end
    end

    logic w_dc_ready, w_rf_ready, w_li_ready;
    assign w_dc_ready = ((r_dc_active_mask ^ i_dc_armed) == 'h0);
    assign w_rf_ready = ((r_rf_active_mask ^ i_rf_armed) == 'h0);
    assign w_li_ready = ((r_li_active_mask ^ i_li_armed) == 'h0);

    logic w_all_ready;
    assign w_all_ready = w_dc_ready && w_rf_ready && w_li_ready;

    enum {IDLE, LAUNCH} r_state, w_next_state;

    always_ff @(posedge i_clk) begin
        r_state <= i_rst ? IDLE : w_next_state;
    end

    always_comb begin

        o_dc_start = 'h0;
        o_rf_start = 'h0;
        o_li_start = 'h0;

        case (r_state)
            IDLE: begin
                w_next_state = w_new_stream ? LAUNCH : IDLE;
            end
            default: begin
                w_next_state = w_all_ready ? IDLE : LAUNCH;
                o_dc_start = w_all_ready ? r_dc_active_mask : 'h0;
                o_rf_start = w_all_ready ? r_rf_active_mask : 'h0;
                o_li_start = w_all_ready ? r_li_active_mask : 'h0;
            end
        endcase

    end

endmodule
