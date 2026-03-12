// `default_nettype none
`timescale 1ns / 1ps
`include "rf.svh"

module rf_nco_update
   #(parameter NCO_FREQ_WIDTH=RF_NCO_FREQ_WIDTH,
     parameter NCO_PHASE_WIDTH=RF_NCO_PHASE_WIDTH,
     parameter NCO_EN_WIDTH=RF_NCO_EN_WIDTH)
    (input  logic i_clk, i_rst,

     input  logic i_wait,
     output logic o_wait,

     input  logic i_start,

     output logic o_req,
     input  logic i_busy);

    enum {IDLE, REQ, HOLD, BUSY} r_state, w_next_state;

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            r_state <= IDLE;
        end
        else begin
            r_state <= w_next_state;
        end
    end

    logic w_set_req;

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            o_req <= 1'b0;
        end
        else if (w_set_req) begin
            o_req <= 1'b1;
        end
        else begin
            o_req <= 1'b0;
        end
    end

    always_comb begin

        w_set_req = 1'b0;
        o_wait = 1'b0;

        case (r_state)
            IDLE: begin
                w_next_state = i_start ? REQ : IDLE;
            end
            REQ: begin
                w_next_state = i_wait ? REQ : HOLD;
                w_set_req = !i_wait;
            end
            HOLD: begin
                o_wait = 1'b1;
                w_next_state = i_busy ? BUSY : HOLD;
            end
            BUSY: begin
                o_wait = 1'b1;
                w_next_state = i_busy ? BUSY : IDLE;
            end
            default: begin
                w_next_state = IDLE;
            end
        endcase
    end

endmodule
