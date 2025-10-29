`timescale 1ns / 1ps

module dc_dispatcher 
#(
    parameter integer DAC_CHANNEL = 24,  
    parameter integer FRAME_WORDS = 62)   

(
    input  logic        i_clk,
    input  logic        i_rst,

    // -------------------- FIFO interface --------------------
    input  logic [31:0] i_fifo_data,   
    input  logic        i_fifo_empty,  
    output logic        o_fifo_deq,    


    output logic [FRAME_WORDS-1:0][31:0] o_dc_regs,    
    output logic [4:0]                   o_channel_sel, 
    output logic                         o_valid_frame,
    // -------------------- launch interface --------------------
    output logic [3:0][31:0]             o_launch_cmd,     
    output logic                         o_launch_valid    
    );

    typedef enum logic [1:0] {
        IDLE        = 2'b00,
        READ_HDR    = 2'b01,
        READ_PAYLOAD= 2'b10,
        READ_LAUNCH_CMD = 2'b11
    } state_t;

//    state_t r_state;
//    parameter IDLE            = 2'b00;
//    parameter READ_HDR        = 2'b01;
//    parameter READ_PAYLOAD    = 2'b10;
//    parameter READ_LAUNCH_CMD = 2'b11;

    logic [1:0]  r_state;
    logic [5:0]  r_word_cnt;       // word (0~61)
    logic [4:0]  r_channel_sel;    
    logic [FRAME_WORDS-1:0][31:0] r_frame_buf; 
    logic [3:0][31:0]            r_launch_buf;

    always_ff @(posedge i_clk or negedge i_rst) begin
        if (!i_rst) begin
            r_state        <= IDLE;
            o_fifo_deq     <= 1'b0;
            r_word_cnt     <= 6'd0;
            r_channel_sel  <= 5'd0;
            o_valid_frame  <= 1'b0;
            r_frame_buf    <= '0;
        end else begin
            o_fifo_deq    <= 1'b0;
            o_valid_frame <= 1'b0;

            case (r_state)
            IDLE: begin
                if (!i_fifo_empty) begin
                    o_fifo_deq <= 1'b1;   // first word
                    r_state    <= READ_HDR;
                end
            end

            // ====================================================
            READ_HDR: begin
                // first word
                if (i_fifo_data == 32'hFFFF_FFFF) begin
                    r_word_cnt <= 0;
                    r_state    <= READ_LAUNCH_CMD;
                end
                else begin
                    r_frame_buf[0] <= i_fifo_data;
                    for (int j = 0; j < DAC_CHANNEL; j++) begin
                        if (i_fifo_data[8+j] == 1'b0)
                            r_channel_sel <= j[4:0];
                    end
                    r_word_cnt <= 6'd1;
                    r_state    <= READ_PAYLOAD;
                end
                
            end

            // =========================61===========================
            
            READ_PAYLOAD: begin
                if (!i_fifo_empty) begin
                    o_fifo_deq <= 1'b1;
                    r_frame_buf[r_word_cnt] <= i_fifo_data;
                    r_word_cnt <= r_word_cnt + 1;

                    if (r_word_cnt == FRAME_WORDS-1) begin
                        r_state       <= IDLE;
                        r_word_cnt    <= 6'd0;
                        o_valid_frame <= 1'b1;  
                    end
                end
            end

            // ====================================================
            READ_LAUNCH_CMD: begin
                if (!i_fifo_empty) begin
                    o_fifo_deq <= 1'b1;
                    r_launch_buf[r_word_cnt] <= i_fifo_data;
                    r_word_cnt <= r_word_cnt + 1;

                    if (r_word_cnt == 3) begin   
                        r_state        <= IDLE;
                        o_launch_valid <= 1'b1;
                        r_word_cnt     <= 0;
                    end
                end
            end
            default: r_state <= IDLE;
            endcase
        end
    end

    assign o_channel_sel = r_channel_sel;
    assign o_dc_regs     = r_frame_buf;
    assign o_launch_cmd  = r_launch_buf;

endmodule
