// `default_nettype none
`timescale 1ns / 1ps

module nco_update
   #(parameter NUM_NCO=2,
     parameter NUM_CTRL_REGS=3*NUM_NCO+1,
     parameter NUM_STATUS_REGS=1)
    (input  logic i_clk, i_rst,

     input  logic [0:NUM_CTRL_REGS-1][31:0] i_ctrl_regs,
     output logic [0:NUM_STATUS_REGS-1][31:0] o_status_regs,

     output logic [0:NUM_NCO-1][47:0] o_freq,
     output logic [0:NUM_NCO-1][17:0] o_phase,
     output logic [0:NUM_NCO-1] o_phase_rst,
     output logic [0:NUM_NCO-1][5:0] o_en,
     output logic o_req,
     input  logic i_busy);

    logic w_new_param;

    edge_detector NCOWR (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_signal(i_ctrl_regs[NUM_CTRL_REGS-1][0]),
        .o_posedge(w_new_param),
        .o_negedge()
    );

    for (genvar i = 0; i < NUM_NCO; i++) begin : NCO_PARAM_GEN
        always_ff @(posedge i_clk) begin
            if (i_rst) begin
                {o_freq[i], o_phase[i], o_phase_rst[i], o_en[i]} <= 'h0;
            end
            else if (w_new_param) begin
                {o_freq[i], o_phase[i], o_phase_rst[i], o_en[i]} <= {
                    i_ctrl_regs[3 * i][8:0],
                    i_ctrl_regs[3 * i + 1],
                    i_ctrl_regs[3 * i + 2]
                };
            end
        end
    end

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            o_status_regs <= 'h0;
        end
        else begin
            o_status_regs <= {31'h0, i_busy};
        end
    end
    
    // nco update fsm
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

        case (r_state)
            IDLE: begin
                w_next_state = w_new_param ? REQ : IDLE;
            end
            REQ: begin
                w_next_state = HOLD;
                w_set_req = 1'b1;
            end
            HOLD: begin
                w_next_state = i_busy ? BUSY : HOLD;
            end
            BUSY: begin
                w_next_state = i_busy ? BUSY : IDLE;
            end
            default: begin
                w_next_state = IDLE;
            end
        endcase

    end

endmodule
