`timescale 1ns / 1ps

module spi_master
   #(parameter DATA_WIDTH=8,
     parameter SCLK_POLARITY=0,
     parameter SCLK_PHASE=0)
    (input  logic i_clk, i_rst,

     input  logic [DATA_WIDTH-1:0] i_din,
     output logic [DATA_WIDTH-1:0] o_dout,

     input  logic i_start,
     output logic o_done,

     input  logic [15:0] i_dvsr,

     input  logic i_miso,
     output logic o_mosi,
     output logic o_sclk);

     localparam IDLE_LVL = SCLK_POLARITY;
     localparam P0_LVL = (SCLK_PHASE) ? (!IDLE_LVL) : IDLE_LVL; 
     localparam P1_LVL = !P0_LVL;
     localparam logic [31:0] DATA_WIDTH_LOGIC = DATA_WIDTH;
     localparam logic [31:0] WIDTH_CMP_32BIT = DATA_WIDTH_LOGIC - 'd1;
     localparam logic [3:0] WIDTH_CMP = WIDTH_CMP_32BIT[3:0];

     enum {IDLE, P0, P1} r_state, w_next_state;

     logic [15:0] r_cycle_counter, w_cycle_counter_next;
     logic [$clog2(DATA_WIDTH)-1:0] r_bit_counter, w_bit_counter_next;

     logic r_sclk, w_sclk_next;
     assign o_sclk = r_sclk;

     always_ff @(posedge i_clk) begin
         if (i_rst) begin
             r_state <= IDLE;
             r_cycle_counter <= 'd0;
             r_bit_counter <= 'd0;
             r_sclk <= IDLE_LVL;
         end
         else begin
             r_state <= w_next_state;
             r_cycle_counter <= w_cycle_counter_next;
             r_bit_counter <= w_bit_counter_next;
             r_sclk <= w_sclk_next;
         end
     end

     logic [DATA_WIDTH-1:0] r_data_send, r_data_recv;
     logic w_data_send_en, w_data_send_shift, w_data_recv_shift;
     assign o_dout = r_data_recv;

     always_ff @(posedge i_clk) begin
         if (i_rst) begin
             r_data_send <= 'd0;
         end
         else if (w_data_send_en) begin
             r_data_send <= i_din;
         end
         else if (w_data_send_shift) begin
             r_data_send <= {r_data_send[DATA_WIDTH-2:0], 1'b0};
         end
     end

     assign o_mosi = r_data_send[DATA_WIDTH-1];

     always_ff @(posedge i_clk) begin
         if (i_rst) begin
             r_data_recv <= 'd0;
         end
         else if (w_data_recv_shift) begin
             r_data_recv <= {r_data_recv[DATA_WIDTH-2:0], i_miso};
         end
     end

     always_comb begin

         w_next_state = r_state;
         w_cycle_counter_next = r_cycle_counter;
         w_bit_counter_next = r_bit_counter;
         w_sclk_next = r_sclk;

         w_data_send_en = 1'b0;
         w_data_send_shift = 1'b0;
         w_data_recv_shift = 1'b0;
         w_sclk_next = IDLE_LVL;
        
         /* verilator lint_off WAITCONST */
         o_done = 1'b0;

         case (r_state)

             IDLE: begin

                 if (i_start) begin
                     w_next_state = P0;
                     w_cycle_counter_next = 'd0;
                     w_bit_counter_next = 'd0;
                     w_sclk_next = P0_LVL;

                     w_data_send_en = 1'b1;
                 end

             end

             P0: begin

                 w_sclk_next = P0_LVL;

                 if (r_cycle_counter == i_dvsr) begin
                     w_next_state = P1;
                     w_cycle_counter_next = 'd0;
                     w_sclk_next = P1_LVL;

                     // P0->P1 shift in 1 bit
                     w_data_recv_shift = 1'b1;
                 end
                 else begin
                     w_cycle_counter_next = r_cycle_counter + 'd1;
                 end

             end

             P1: begin

                 w_sclk_next = P1_LVL;

                 if (r_cycle_counter == i_dvsr) begin

                     if (r_bit_counter == WIDTH_CMP) begin
                         w_next_state = IDLE;
                         w_cycle_counter_next = 'd0;
                         w_bit_counter_next = 'd0;
                         w_sclk_next = IDLE_LVL;

                         o_done = 1'b1;
                     end
                     else begin
                         w_next_state = P0;
                         w_cycle_counter_next = 'd0;
                         w_bit_counter_next = r_bit_counter + 'd1;
                         w_sclk_next = P0_LVL;

                         // P1->P0 shift out 1 bit
                         w_data_send_shift = 1'b1;
                     end

                 end
                 else begin
                     w_cycle_counter_next = r_cycle_counter + 'd1;
                 end

             end

         endcase

     end

endmodule

