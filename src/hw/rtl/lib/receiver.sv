`timescale 1ns / 1ps

module receiver
    (input  logic       i_clk, i_rst,
     input  logic       i_rx, i_sample_tick,
     output logic       o_enq_rxq,
     output logic [7:0] o_data);

    enum {IDLE, START, DATA, STOP} r_state, w_next_state;

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            r_state <= IDLE;
        end
        else begin
            r_state <= w_next_state;
        end
    end

    logic [3:0] r_cycle_counter, w_cycle_counter_next;
    logic [2:0] r_bit_counter, w_bit_counter_next;

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            r_cycle_counter <= 'd0;
            r_bit_counter <= 'd0;
        end
        else begin
            r_cycle_counter <= w_cycle_counter_next;
            r_bit_counter <= w_bit_counter_next;
        end
    end

    logic [7:0] r_data;
    logic w_data_en;

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            r_data <= 'd0;
        end
        else if (w_data_en) begin
            r_data <= {i_rx, r_data[7:1]};
        end
    end

    always_comb begin

        w_next_state = r_state;
        w_cycle_counter_next = r_cycle_counter;
        w_bit_counter_next = r_bit_counter;
        w_data_en = 1'b0;

        o_enq_rxq = 1'b0;

        case (r_state)

            IDLE: begin

                if (!i_rx) begin
                    w_next_state = START;
                    w_cycle_counter_next = 'd0;
                end

            end

            START: begin

                if (i_sample_tick) begin

                    if (r_cycle_counter == 'd7) begin
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

                if (i_sample_tick) begin

                    if (r_cycle_counter == 'd15) begin

                        w_data_en = 1'b1;

                        if (r_bit_counter == 'd7) begin
                            w_next_state = STOP;
                            w_bit_counter_next = 'd0;
                            w_cycle_counter_next = 'd0;
                        end
                        else begin
                            w_bit_counter_next = r_bit_counter + 'd1;
                            w_cycle_counter_next = r_cycle_counter + 'd1;
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
                        o_enq_rxq = 1'b1;
                        w_cycle_counter_next = 'd0;
                    end
                    else begin
                        w_cycle_counter_next = r_cycle_counter + 'd1;
                    end
                end

            end
            
            default: begin
            end

        endcase
    end

    assign o_data = r_data;

endmodule
