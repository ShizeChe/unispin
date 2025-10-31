`timescale 1ns / 1ps

module uart 
   #(parameter DATA_WIDTH=8,

     parameter RX_FIFO_DEPTH=20, 
     parameter RX_FIFO_AF_DEPTH=16,
     parameter RX_FIFO_AE_DEPTH=4,

     parameter TX_FIFO_DEPTH=20, 
     parameter TX_FIFO_AF_DEPTH=16,
     parameter TX_FIFO_AE_DEPTH=4)

    (input  logic i_clk, i_rst,

     input  logic i_rx,
     output logic o_tx,

     input  logic                  i_deq_rxq,
     output logic [DATA_WIDTH-1:0] o_rxq_data,
     output logic                  o_rxq_empty,
     output logic                  o_rxq_ae,
     output logic                  o_rxq_full,
     output logic                  o_rxq_af,

     input  logic                  i_enq_txq,
     input  logic [DATA_WIDTH-1:0] i_txq_data,
     output logic                  o_txq_empty,
     output logic                  o_txq_ae,
     output logic                  o_txq_full,
     output logic                  o_txq_af);

    logic w_sample_tick;

    baudx16_generator baud_gen (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_dvsr(11'd53), // baudrate = 115200, clock period = 100Mhz
        .o_sample_tick(w_sample_tick)
    );
    
    logic w_enq_rxq;
    logic [DATA_WIDTH-1:0] w_data_rx;

    receiver recv (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_rx(i_rx),
        .i_sample_tick(w_sample_tick),
        .o_enq_rxq(w_enq_rxq),
        .o_data(w_data_rx)
    );

    fifo #(
        .WIDTH(DATA_WIDTH),
        .DEPTH(RX_FIFO_DEPTH),
        .AF_DEPTH(RX_FIFO_AF_DEPTH),
        .AE_DEPTH(RX_FIFO_AE_DEPTH)
    ) rx_fifo (
        .i_clk(i_clk),
        .i_rst(i_rst),

        .i_enq(w_enq_rxq),
        .i_data(w_data_rx),
        .o_full(o_rxq_full),
        .o_almost_full(o_rxq_af),

        .i_deq(i_deq_rxq),
        .o_data(o_rxq_data),
        .o_empty(o_rxq_empty),
        .o_almost_empty(o_rxq_ae)
    );

    logic w_deq_txq;
    logic [DATA_WIDTH-1:0] w_data_tx;

    transmitter tsmt (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_sample_tick(w_sample_tick),
        .o_tx(o_tx),
        .i_data(w_data_tx),
        .o_deq_txq(w_deq_txq),
        .i_txq_empty(o_txq_empty)
    );

    fifo #(
        .WIDTH(DATA_WIDTH),
        .DEPTH(TX_FIFO_DEPTH),
        .AF_DEPTH(TX_FIFO_AF_DEPTH),
        .AE_DEPTH(TX_FIFO_AE_DEPTH)
    ) tx_fifo (
        .i_clk(i_clk),
        .i_rst(i_rst),

        .i_enq(i_enq_txq),
        .i_data(i_txq_data),
        .o_full(o_txq_full),
        .o_almost_full(o_txq_af),

        .i_deq(w_deq_txq),
        .o_data(w_data_tx),
        .o_empty(o_txq_empty),
        .o_almost_empty(o_txq_ae)
    );

endmodule

