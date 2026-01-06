// `default_nettype none
`timescale 1ns / 1ps
`include "dc.svh"

module dc_core
   #(parameter SPI_DATA_WIDTH=DC_SPI_DATA_WIDTH,
     parameter CYCLE_WIDTH=DC_CYCLE_WIDTH,
     parameter ITER_WIDTH=DC_CORE_ITER_WIDTH,
     parameter INSN_WIDTH=DC_INSN_WIDTH,
     parameter DEPTH=DC_DEPTH)
    (input  logic i_clk, i_rst,

     // sequencer interface
     input  logic [$clog2(DEPTH)-1:0] i_addr,
     input  logic [INSN_WIDTH-1:0] i_insn,
     output logic o_next,
     input  logic i_empty,
     output dc_insn_t o_insn_modified,

     // spi interface
     output logic o_sclk,
     output logic o_mosi,
     input  logic i_miso,
     output logic o_cs_n,
     output logic o_ldac_n,

     // output interface
     output logic [$clog2(DEPTH)-1:0] o_addr,
     output logic [ITER_WIDTH-1:0] o_iter,
     output logic [DC_SPI_DATA_WIDTH-1:0] o_spi_din,
     output logic o_spi_rd,
     output logic [SPI_DATA_WIDTH-1:0] o_spi_dout,
     output logic [CYCLE_WIDTH-1:0] o_cycles_left,

     // launcher interface
     input  logic i_start,
     output logic o_armed);

    logic w_stall;

    /**************
    * decode stage
    **************/

    dc_decode_stg_t d;

    dc_decode #(
        .DEPTH(DEPTH)
    ) DECODER (
        .i_addr(i_addr),
        .i_insn(i_insn),
        .d(d),
        .o_insn_modified(o_insn_modified)
    );

    /***************
    * iterate stage
    ***************/

    dc_iterate_stg_t i;

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            i <= '{
                r_addr: 'bx,
                r_iters: 'd0,
                r_spi_dvsr: 'bx,
                r_spi_din: 'bx,
                r_dspi_din: 'bx,
                r_spi_rd: 1'b0,
                r_strb_ldac: 1'b0,
                r_hold_cycles: 'd0,
                r_arm: 1'b0,
                r_bubble: 1'b1
            };
        end
        else if (!w_stall) begin

            if (i.r_iters == 'd0) begin

                if (!i_empty) begin
                    i <= '{
                        r_addr: d.w_addr,
                        r_iters: d.w_iters,
                        r_spi_dvsr: d.w_spi_dvsr,
                        r_spi_din: d.w_spi_din,
                        r_dspi_din: d.w_dspi_din,
                        r_spi_rd: d.w_spi_rd,
                        r_strb_ldac: d.w_strb_ldac,
                        r_hold_cycles: d.w_hold_cycles,
                        r_arm: d.w_arm,
                        r_bubble: 1'b0
                    };
                end
                else begin
                    i.r_bubble <= 1'b1;
                end

            end
            else begin
                i.r_iters <= (i.r_iters > 'd0) ? (i.r_iters - 'd1) : 'd0;
                i.r_spi_din <= {
                    i.r_spi_din[DC_SPI_DATA_WIDTH-1:DC_DAC_WIDTH],
                    i.r_spi_din[DC_DAC_WIDTH-1:0] + i.r_dspi_din
                };
                i.r_arm <= 1'b0;
            end

        end
    end

    /***********
    * spi stage
    ***********/

    dc_spi_stg_t s;

    logic w_spi_done;
    logic [DC_SPI_DATA_WIDTH-1:0] w_spi_dout;

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            s <= '{
                r_addr: 'bx,
                r_iter: 'bx,
                r_spi_dvsr: 'bx,
                r_spi_din: 'bx,
                r_spi_rd: 1'b0,
                r_spi_dout: 'h0,
                r_strb_ldac: 1'b0,
                r_hold_cycles: 'd0,
                r_arm: 1'b0,
                r_cs_n: 1'b1,
                r_spi_start: 1'b0,
                r_spi_done: 1'b1
            };
        end
        else if (!w_stall) begin
            s <= '{
                r_addr: i.r_bubble ? 'bx : i.r_addr,
                r_iter: i.r_bubble ? 'bx : i.r_iters,
                r_spi_dvsr: i.r_bubble ? 'bx : i.r_spi_dvsr,
                r_spi_din: i.r_bubble ? 'bx : i.r_spi_din,
                r_spi_rd: i.r_bubble ? 1'b0 : i.r_spi_rd,
                r_spi_dout: 'h0,
                r_strb_ldac: i.r_bubble ? 1'b0 : i.r_strb_ldac,
                r_hold_cycles: i.r_bubble ? 'd0 : i.r_hold_cycles,
                r_arm: i.r_bubble ? 1'b0 : i.r_arm,
                r_cs_n: i.r_bubble,
                r_spi_start: !i.r_bubble,
                r_spi_done: i.r_bubble
            };
        end
        else begin
            s.r_spi_start <= 1'b0;
            if (w_spi_done) begin
                s.r_spi_done <= 1'b1;
                s.r_spi_dout <= w_spi_dout;
                s.r_cs_n <= 1'b1;
            end
        end
    end

    logic [15:0] w_dvsr;
    assign w_dvsr = {{(16-DC_SPI_DVSR_WIDTH){1'b0}}, s.r_spi_dvsr};

    dc_spi_master #(
        .DATA_WIDTH(DC_SPI_DATA_WIDTH),
        .SCLK_POLARITY(0),
        .SCLK_PHASE(1)
    ) SPI (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_dvsr(w_dvsr),
        .i_din(s.r_spi_din),
        .o_dout(w_spi_dout),
        .i_start(s.r_spi_start),
        .o_done(w_spi_done),
        .i_miso(i_miso),
        .o_mosi(o_mosi),
        .o_sclk(o_sclk)
    );

    /************
    * hold stage
    ************/

    dc_hold_stg_t h;

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            h <= '{
                r_addr: 'bx,
                r_iter: 'bx,
                r_spi_din: 'bx,
                r_spi_rd: 1'b0,
                r_spi_dout: 'bx,
                r_ldac_n: 1'b1,
                r_cycles_left: 'd0
            };
        end
        else if (!w_stall) begin
            h <= '{
                r_addr: s.r_addr,
                r_iter: s.r_iter,
                r_spi_din: s.r_spi_din,
                r_spi_rd: s.r_spi_rd,
                r_spi_dout: s.r_spi_dout,
                r_ldac_n: !s.r_strb_ldac,
                r_cycles_left: s.r_hold_cycles
            };
        end
        else begin
            h.r_ldac_n <= 1'b1;
            h.r_cycles_left <= (h.r_cycles_left > 'd0) ? (h.r_cycles_left - 'd1) : 'd0;
        end
    end

    assign o_cs_n = s.r_cs_n;
    assign o_ldac_n = h.r_ldac_n;
    assign o_armed = s.r_arm && s.r_spi_done;

    assign w_stall = (h.r_cycles_left > 'd0) || !s.r_spi_done ||
                     (o_armed && !i_start);

    assign o_next = !w_stall && i.r_iters == 'd0 && !i_empty;

    assign o_addr = h.r_addr;
    assign o_iter = h.r_iter;
    assign o_spi_din = h.r_spi_din;
    assign o_spi_rd = h.r_spi_rd;
    assign o_spi_dout = h.r_spi_dout;
    assign o_cycles_left = h.r_cycles_left;

endmodule

