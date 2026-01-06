`timescale 1ns / 1ps

module debouncer
   #(parameter NUM_CYCLES=50000)
    (input  logic i_clk, i_rst,
     input  logic i_bouncy,
     output logic o_steady);

    logic [$clog2(NUM_CYCLES)-1:0] r_cycles;
    logic r_last_unchanged;

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            r_cycles <= 'd0;
        end
        else begin

            if (r_cycles == NUM_CYCLES) begin
                o_steady <= r_last_unchanged;
                r_cycles <= 'd0;
            end

            if (i_bouncy != r_last_unchanged) begin
                r_last_unchanged <= i_bouncy;
                r_cycles <= 'd1;
            end
            else begin
                r_cycles <= r_cycles + 'd1;
            end

        end
    end

endmodule

