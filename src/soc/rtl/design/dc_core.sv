`timescale 1ns / 1ps

module dc_core
   #(parameter DAC_WIDTH=16,
     parameter CYCLE_WIDTH=30,
     parameter ITER_WIDTH=10,
     parameter INSN_WIDTH=DAC_WIDTH*2+ITER_WIDTH+CYCLE_WIDTH)
    (input  logic i_clk, i_rst,

     input  logic [INSN_WIDTH-1:0] i_insn,
     output logic o_next,
     input  logic i_empty,

     output logic o_sclk,
     output logic o_mosi,
     output logic o_cs_n,
     output logic o_ldac_n,

     input  logic i_start,
     output logic o_armed);

    logic [DAC_WIDTH-1:0] r_dac_code, w_dac_code_next;
    logic [ITER_WIDTH-1:0] r_iters, w_iters_next;
    logic [CYCLE_WIDTH-1:0] r_insn_cycles, w_insn_cycles_next;
    logic [CYCLE_WIDTH-1:0] r_cycles, w_cycles_next;
    logic [DAC_WIDTH-1:0] r_dv, w_dv_next;

    logic [DAC_WIDTH-1:0] w_dv_decode;
    logic [ITER_WIDTH-1:0] w_iters_decode;
    logic [DAC_WIDTH-1:0] w_dac_code_decode;
    logic [CYCLE_WIDTH-1:0] w_cycles_decode;

    logic r_spi_start, r_spi_finished;
    logic w_spi_done;

    assign {w_dv_decode, w_iters_decode, 
            w_dac_code_decode, w_cycles_decode} = i_insn;

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            r_dac_code <= 'h0;
            r_insn_cycles <= 'd0;
            r_iters <= 'd1;
            r_cycles <= 'd0;
            r_dv = 'h0;
        end
        else begin
            r_dac_code <= w_dac_code_next;
            r_insn_cycles <= w_insn_cycles_next;
            r_iters <= w_iters_next;
            r_cycles <= w_cycles_next;
            r_dv <= w_dv_next;
        end
    end

    logic w_small_propagate, w_big_propagate, w_propagate_last;

    enum {IDLE, ARMED, STREAM} r_state;

    always_ff @(posedge i_clk) begin
        if (i_rst) r_state <= IDLE;
        else if (r_state == ARMED && i_start) r_state <= STREAM;
        else if (r_state == IDLE && w_big_propagate) r_state <= ARMED;
        else if (w_propagate_last) r_state <= IDLE;
    end

    always_ff @(posedge i_clk)
        o_armed <= (r_state == ARMED) && r_spi_finished;
    // assign o_armed = (r_state == ARMED) && r_spi_finished;

    assign w_small_propagate = (r_cycles == 'd0) && (r_iters > 'd1) &&
                               r_spi_finished && (r_state == STREAM);
    assign w_big_propagate = (r_cycles == 'd0) && (r_iters == 'd1) &&
                             r_spi_finished && (!i_empty) && (r_state != ARMED);
    assign w_propagate_last = (r_cycles == 'd0) && (r_iters == 'd1) &&
                              r_spi_finished && i_empty && (r_state == STREAM);

    always_ff @(posedge i_clk) begin
        if (i_rst) r_spi_start <= 1'b0;
        else if (w_small_propagate || w_big_propagate) r_spi_start <= 1'b1;
        else if (r_spi_start) r_spi_start <= 1'b0;

        if (i_rst) r_spi_finished <= 1'b1;
        else if (w_small_propagate || w_big_propagate) r_spi_finished <= 1'b0; 
        else if (w_spi_done) r_spi_finished <= 1'b1;
    end

    spi_master #(
        .DATA_WIDTH(DAC_WIDTH),
        .SCLK_POLARITY(0),
        .SCLK_PHASE(0)
    ) spim (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_dvsr(16'd4),
        .i_din(r_dac_code),
        .o_dout(),
        .i_start(r_spi_start),
        .o_done(w_spi_done),
        .i_miso(),
        .o_mosi(o_mosi),
        .o_sclk(o_sclk)
    );

    always_ff @(posedge i_clk) begin
        if (i_rst) o_cs_n <= 1'b1;
        else if (r_spi_start) o_cs_n <= 1'b0;
        else if (w_spi_done) o_cs_n <= 1'b1;
    end

    always_ff @(posedge i_clk) begin
        if (i_rst) o_ldac_n <= 1'b1;
        else if ((w_small_propagate || w_big_propagate ||
                 w_propagate_last) && r_state == STREAM) o_ldac_n <= 1'b0;
        else if (!o_ldac_n) o_ldac_n <= 1'b1;
    end

    assign o_next = w_big_propagate && !i_empty;

    always_comb begin
        case ({w_propagate_last, w_small_propagate, w_big_propagate})
            3'b000: begin
                w_dac_code_next = r_dac_code;
                w_insn_cycles_next = r_insn_cycles;
                w_iters_next = r_iters;
                w_cycles_next = (r_cycles == 'd0) ? 'd0 : r_cycles - 'd1;
                w_dv_next = r_dv;
            end
            3'b001: begin
                w_dac_code_next = w_dac_code_decode;
                w_insn_cycles_next = w_cycles_decode;
                w_iters_next = w_iters_decode;
                w_cycles_next = r_insn_cycles;
                w_dv_next = w_dv_decode;
            end
            3'b010: begin
                w_dac_code_next = r_dac_code + r_dv;
                w_insn_cycles_next = r_insn_cycles;
                w_iters_next = r_iters - 'd1;
                w_cycles_next = r_insn_cycles;
                w_dv_next = r_dv;
            end
            3'b100: begin
                w_dac_code_next = 'h0;
                w_insn_cycles_next = 'h0;
                w_iters_next = 'd1;
                w_cycles_next = r_insn_cycles;
                w_dv_next = 'h0;
            end
            default: begin
                w_dac_code_next = r_dac_code;
                w_insn_cycles_next = r_insn_cycles;
                w_iters_next = r_iters;
                w_cycles_next = r_insn_cycles;
                w_dv_next = r_dv;
            end
        endcase
    end

endmodule

