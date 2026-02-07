module test
   (input  logic i_pl_clk_n, i_pl_clk_p,
    input  logic i_rx,
    output logic o_tx,
    input  logic i_btn_c);

    logic w_clk;

    IBUFDS BDS (
        .O(w_clk),
        .I(i_pl_clk_p),
        .IB(i_pl_clk_n)
    );

    logic [0:127][31:0] w_uregs;

    uart_regs #(
        .DATA_WIDTH(8),
        .RX_FIFO_DEPTH(8),
        .RX_FIFO_AF_DEPTH(6),
        .RX_FIFO_AE_DEPTH(2),
        .TX_FIFO_DEPTH(8),
        .TX_FIFO_AF_DEPTH(6),
        .TX_FIFO_AE_DEPTH(2),
        .NUM_REGS(127)
    ) REGS (
        .i_clk(w_clk),
        .i_rst(i_btn_c),
        .i_rx(i_rx),
        .o_tx(o_tx),
        .i_dvsr(11'd6),
        .o_regs(w_uregs)
    );

    ila_0 ILA (
        .clk(w_clk), // input wire clk
    
        .probe0(i_rx), // input wire [0:0]  probe0  
        .probe1(o_tx), // input wire [0:0]  probe1 
        .probe2(REGS.UART.w_sample_tick), // input wire [0:0]  probe2 
        .probe3(REGS.UART.RECV.r_data), // input wire [7:0]  probe3 
        .probe4(REGS.UART.TSMT.r_data) // input wire [7:0]  probe4
    );

endmodule
