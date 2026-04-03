// `default_nettype none
`timescale 1ns / 1ps

module button_detector
   #(parameter NUM_CYCLES=50000,
     parameter NUM_BUTTONS=1)
    (input  logic i_clk, i_rst,
     input  logic [0:NUM_BUTTONS-1] i_btn,
     output logic [0:NUM_BUTTONS-1] o_pressed);

    logic [0:NUM_BUTTONS-1] w_btn_steady;
    logic [0:NUM_BUTTONS-1] r_ff1, r_ff2;

    for (genvar i = 0; i < NUM_BUTTONS; i++) begin : DETECTOR_GEN
        debouncer #(
            .NUM_CYCLES(NUM_CYCLES)
        ) DEBOUNCER (
            .i_clk(i_clk),
            .i_rst(i_rst),
            .i_bouncy(i_btn[i]),
            .o_steady(w_btn_steady[i])
        );

        always_ff @(posedge i_clk) begin
            if (i_rst) begin
                r_ff1[i] <= 1'b0;
                r_ff2[i] <= 1'b0;
                o_pressed[i] <= 1'b0;
            end
            else begin
                r_ff1[i] <= w_btn_steady[i];
                r_ff2[i] <= r_ff1[i];
                o_pressed[i] <= (!r_ff2[i] && r_ff1[i]);
            end
        end
    end

endmodule

