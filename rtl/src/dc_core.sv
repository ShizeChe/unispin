// `default_nettype none
`timescale 1ns / 1ps
`include "dc.svh"

module dc_core
   #(parameter SPI_DATA_WIDTH=DC_SPI_DATA_WIDTH,
     parameter CYCLE_WIDTH=DC_CYCLE_WIDTH,
     parameter SPI_LDAC_WIDTH=DC_SPI_LDAC_WIDTH,
     parameter ITER_WIDTH=DC_CORE_ITER_WIDTH,
     parameter INSN_WIDTH=DC_INSN_WIDTH,
     parameter DEPTH=DC_DEPTH)
    (input  logic i_clk, i_rst,

     // sequencer interface
     input  logic [$clog2(DEPTH)-1:0] i_addr,
     input  dc_insn_t i_insn,
     output logic o_next,
     input  logic i_empty,
     output dc_insn_t o_insn_modified,

     // control interface
     input  dc_ctrl_t i_ctrl,

     // spi interface
     output logic o_sclk,
     output logic o_mosi,
     input  logic i_miso,
     output logic o_cs_n,
     output logic o_ldac_n,

     // launcher interface
     input  logic i_start,
     output logic o_armed,

     // pipeline empty flag
     output logic o_empty,

     // eop for verification
     output dc_eop_t o_eop);

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
                r_spi_din: 'bx,
                r_spi_rd: 1'b0,
                r_spi_dout: 'h0,
                r_strb_ldac: 1'b0,
                r_hold_cycles: 'd0,
                r_arm: 1'b0,
                r_delay_cycles: 'd0,
                r_cs_up_cycles: 'd0,
                r_cs_n: 1'b1,
                r_spi_start: 1'b0,
                r_spi_done: 1'b1
            };
        end
        else if (!w_stall) begin
            s <= '{
                r_addr: i.r_bubble ? 'bx : i.r_addr,
                r_iter: i.r_bubble ? 'bx : i.r_iters,
                r_spi_din: i.r_bubble ? 'bx : i.r_spi_din,
                r_spi_rd: i.r_bubble ? 1'b0 : i.r_spi_rd,
                r_spi_dout: 'h0,
                r_strb_ldac: i.r_bubble ? 1'b0 : i.r_strb_ldac,
                r_hold_cycles: i.r_bubble ? 'd0 : i.r_hold_cycles,
                r_arm: i.r_bubble ? 1'b0 : i.r_arm,
                r_delay_cycles: i.r_bubble ? 'd0 : i_ctrl.w_delay_cycles,
                r_cs_up_cycles: i.r_bubble ? 'd0 : i_ctrl.w_cs_up_cycles,
                r_cs_n: 1'b1,
                r_spi_start: !i.r_bubble,
                r_spi_done: i.r_bubble
            };
        end
        else begin
            if (s.r_delay_cycles > 'd0) begin
                s.r_delay_cycles <= s.r_delay_cycles - 'd1;
            end
            else if (!s.r_spi_done) begin
                s.r_spi_start <= 1'b0;
                s.r_cs_n <= w_spi_done;
                s.r_spi_done <= w_spi_done;
                s.r_spi_dout <= w_spi_done ? w_spi_dout : 'bx;
            end
            else begin
                s.r_cs_n <= 1'b1;
                s.r_cs_up_cycles <= (s.r_cs_up_cycles > 'd0) ? 
                    s.r_cs_up_cycles - 'd1 : 'd0;
            end
        end
    end

    dc_spi_master #(
        .DATA_WIDTH(DC_SPI_DATA_WIDTH),
        .SCLK_POLARITY(0),
        .SCLK_PHASE(1)
    ) SPI (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_dvsr(i_ctrl.w_dvsr),
        .i_din(s.r_spi_din),
        .o_dout(w_spi_dout),
        .i_start(s.r_spi_start && s.r_delay_cycles == 'd0),
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
                r_ldac_cycles: 'd0,
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
                r_ldac_cycles: s.r_strb_ldac ? i_ctrl.w_ldac_cycles : 'd0, 
                r_ldac_n: !s.r_strb_ldac,
                r_cycles_left: s.r_hold_cycles
            };
        end
        else begin
            if (h.r_ldac_cycles > 'd0) begin
                h.r_ldac_cycles <= h.r_ldac_cycles - 'd1;
            end
            else if (!h.r_ldac_n) begin
                h.r_ldac_n <= 1'b1;
            end
            else begin
                h.r_cycles_left <= (h.r_cycles_left > 'd0) ? (h.r_cycles_left - 'd1) : 'd0;
            end
        end
    end

    /*************
    * stall logic
    *************/

    assign w_stall = (h.r_ldac_cycles > 'd0) || (h.r_cycles_left > 'd0) || (!h.r_ldac_n) ||
                     (!s.r_spi_done) || (s.r_cs_up_cycles > 'd0) || (!s.r_cs_n) ||
                     (o_armed && !i_start);

    /****************
    * output signals
    ****************/

    assign o_cs_n = s.r_cs_n;
    assign o_ldac_n = h.r_ldac_n;

    assign o_armed = s.r_arm && s.r_spi_done && (s.r_cs_up_cycles == 'd0);

    assign o_next = !w_stall && (i.r_iters == 'd0) && !i_empty;

    assign o_empty = i_empty && i.r_bubble && s.r_spi_done && (s.r_cs_up_cycles == 'd0) && 
                     s.r_cs_n && (h.r_ldac_cycles == 'd0) && (h.r_cycles_left == 'd0) &&
                     h.r_ldac_n;

    assign o_eop = '{
        w_addr: h.r_addr,
        w_iter: h.r_iter,
        w_spi_din: h.r_spi_din,
        w_spi_rd: h.r_spi_rd,
        w_spi_dout: h.r_spi_dout,
        w_ldac_cycles: h.r_ldac_cycles,
        w_cycles_left: h.r_cycles_left
    };

endmodule

