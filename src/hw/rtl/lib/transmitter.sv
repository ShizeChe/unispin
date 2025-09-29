`timescale 1ns / 1ps

module transmitter
    (input  logic i_clk, i_rst,
     input  logic i_sample_tick,
     output logic o_tx, 
     input  logic [7:0] i_data,
     output logic o_deq_txq,
     input  logic i_txq_empty);

    enum {IDLE, START, DATA, STOP} r_state, w_next_state;

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            r_state <= IDLE;
        end
        else begin
            r_state <= w_next_state;
        end
    end

    logic [7:0] r_data;
    logic w_data_en, w_data_shift;

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            r_data <= 'd0;
        end
        else if (w_data_en) begin
            r_data <= i_data;
        end
        else if (w_data_shift) begin
            r_data <= {1'b0, r_data[7:1]};
        end
    end

    logic [2:0] r_bit_counter, w_bit_counter_next;
    logic [3:0] r_cycle_counter, w_cycle_counter_next;
    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            r_bit_counter <= 'd0;
            r_cycle_counter <= 'd0;
        end
        else begin
            r_bit_counter <= w_bit_counter_next;
            r_cycle_counter <= w_cycle_counter_next;
        end
    end

    always_comb begin

        w_next_state = r_state;
        o_tx = 1'b1;

        o_deq_txq = 1'b0;

        w_data_en = 1'b0;
        w_data_shift = 1'b0;

        w_cycle_counter_next = r_cycle_counter;
        w_bit_counter_next = r_bit_counter;

        case (r_state)

            IDLE: begin

                if (i_sample_tick && !i_txq_empty) begin
                    w_next_state = START;
                    o_deq_txq = 1'b1;
                    w_data_en = 1'b1;
                    w_cycle_counter_next = 'd0;
                    w_bit_counter_next = 'd0;
                end

            end

            START: begin

                o_tx = 1'b0;

                if (i_sample_tick) begin

                    if (r_cycle_counter == 'd15) begin
                        w_next_state = DATA;
                        w_cycle_counter_next = 'd0;
                        w_bit_counter_next = 'd0;
                    end
                    else begin
                        w_cycle_counter_next = r_cycle_counter + 'd1;
                    end

                end

            end

            DATA: begin

                o_tx = r_data[0];

                if (i_sample_tick) begin

                    if (r_cycle_counter == 'd15) begin

                        if (r_bit_counter == 'd7) begin
                            w_next_state = STOP;
                            w_bit_counter_next = 'd0;
                            w_cycle_counter_next = 'd0;
                        end
                        else begin
                            w_data_shift = 1'b1;
                            w_bit_counter_next = r_bit_counter + 'd1;
                            w_cycle_counter_next = 'd0;
                        end

                    end
                    else begin
                        w_cycle_counter_next = r_cycle_counter + 'd1;
                    end

                end

            end

            STOP: begin

                if (i_sample_tick) begin

                    if (r_cycle_counter == 'd15) begin
                        w_next_state = IDLE;
                        w_cycle_counter_next = 'd0;
                        w_bit_counter_next = 'd0;
                    end
                    else begin
                        w_cycle_counter_next = r_cycle_counter + 'd1;
                    end

                end

            end

        endcase

    end

endmodule
