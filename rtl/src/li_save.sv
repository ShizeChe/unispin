`timescale 1ns / 1ps

module li_save
   #(parameter ADC_WIDTH=LI_ADC_WIDTH,
     parameter FIFO_ADDR_WIDTH=8)
    (input  logic i_clk, i_rst,

     // interface with li core
     input  logic [3:0] i_validx4,
     input  logic i_last,
     input  logic [ADC_WIDTH*8-1:0] i_QIx4,

     input li_ctrl_t i_ctrl,

     // aw
     output logic o_awvalid,
     input  logic i_awready,
     output logic [5:0] o_awid,
     output logic [48:0] o_awaddr,
     output logic [1:0] o_awburst,
     output logic [2:0] o_awsize,
     output logic [7:0] o_awlen,
     output logic [3:0] o_awcache,
     output logic [2:0] o_awprot,
     output logic [3:0] o_awqos,
     output logic o_awlock,
     output logic o_awuser,

     // w
     output logic o_wvalid,
     input  logic i_wready,
     output logic [127:0] o_wdata,
     output logic [15:0] o_wstrb,
     output logic o_wlast,

     // b
     input  logic i_bvalid,
     output logic o_bready,
     input  logic [5:0] i_bid,
     input  logic [1:0] i_bresp,

     // ar
     output logic o_arvalid,
     input  logic i_arready,
     output logic [5:0] o_arid,
     output logic [48:0] o_araddr,
     output logic [1:0] o_arburst,
     output logic [2:0] o_arsize,
     output logic [7:0] o_arlen,
     output logic [3:0] o_arcache,
     output logic [2:0] o_arprot,
     output logic [3:0] o_arqos,
     output logic o_arlock,
     output logic o_aruser,

     // r
     input  logic i_rvalid,
     output logic o_rready,
     input  logic [5:0] i_rid,
     input  logic [127:0] i_rdata,
     input  logic [1:0] i_rresp,
     input  logic i_rlast);

    logic w_propagate_aw, w_propagate_aw2w, w_propagate_w2b;

    /*************
    * bram buffer
    *************/

    logic w_enq, w_deq;
    logic w_full, w_empty;
    logic w_discard;

    logic [31:0] r_num_lost;
    logic [FIFO_ADDR_WIDTH:0] w_num_inbuf;

    assign w_enq = !w_full && ((i_validx4 == 4'b1111) || i_last);
    assign w_discard = w_full && ((i_validx4 == 4'b1111) || i_last);

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            r_num_lost <= 'd0;
        end
        else if (i_ctrl.w_clear_lost) begin
            r_num_lost <= 'd0;
        end
        else if (w_discard) begin
            r_num_lost <= r_num_lost + 'd1;
        end
    end

    logic [127:0] w_axi_data;

    bram_fifo #(
        .DATA_WIDTH(ADC_WIDTH*8),
        .ADDR_WIDTH(FIFO_ADDR_WIDTH)
    ) BFIFO (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_data(i_QIx4),
        .i_enq(w_enq),
        .i_deq(w_deq),
        .o_data(w_axi_data),
        .o_full(w_full),
        .o_empty(w_empty),
        .o_num_data(w_num_inbuf)
    );

    /**************
    * axi aw stage
    **************/

    li_axi_aw_stg_t aw;

    assign o_awvalid = aw.r_valid;
    assign o_awid = aw.r_id;
    assign o_awaddr = aw.r_addr;
    assign o_awlen = aw.r_len;

    assign o_awburst = 2'b01; // INCR
    assign o_awsize = 3'b100; // 16 Bytes Per Beat
    assign o_awcache = 4'b0011; // Normal Non-cacheable Bufferable
    assign o_awprot = 3'b010; // Data, Non-Secure, Unprevileged
    assign o_awqos = 4'b0000; // Not used
    assign o_awlock = 1'b0; // Not used
    assign o_awuser = 1'b0; // Not used

    logic [7:0] w_burst_len;
    logic [13:0] w_bytes2page;

    assign w_bytes2page = 13'h1000 - {1'b0, aw.r_addr[11:0]};

    always_comb begin

        w_burst_len = i_ctrl.w_max_burst;

        if (w_burst_len + 'd1 > w_num_inbuf) begin
            w_burst_len = w_num_inbuf - 'd1;
        end

        // can't cross 4K page boundary
        if (w_burst_len + 'd1 > w_bytes2page) begin
            w_burst_len = w_bytes2page - 'd1;
        end

    end

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            aw.r_addr_nxt <= i_ctrl.w_base_addr;
            aw.r_id_nxt <= 'h0;
            aw.r_valid <= 1'b0;
            aw.r_id <= 'h0;
            aw.r_addr <= 'h0;
            aw.r_len <= 'h0;
            aw.r_bubble <= 1'b1;
            aw.r_done <= 1'b1;
        end
        else if (w_propagate_aw) begin
            aw.r_addr_nxt <= aw.r_addr_nxt + {40'h0, w_burst_len[3:0], 4'h0};
            aw.r_id_nxt <= aw.r_id_nxt + 'd1;
            aw.r_valid <= 1'b1;
            aw.r_id <= aw.r_id_nxt;
            aw.r_addr <= aw.r_addr_nxt;
            aw.r_len <= w_burst_len;
            aw.r_bubble <= 1'b0;
            aw.r_done <= 1'b0;
        end
        else if (w_propagate_aw2w) begin
            aw.r_valid <= 1'b0;
            aw.r_id <= 'h0;
            aw.r_addr <= 'h0;
            aw.r_len <= 'h0;
            aw.r_bubble <= 1'b1;
            aw.r_done <= 1'b1;
        end
        else begin
            aw.r_done <= aw.w_handshake;
            if (aw.r_valid)
                aw.r_valid <= !aw.w_handshake;
        end
    end

    assign aw.w_handshake = aw.r_valid && i_awready;
    assign aw.w_done = aw.r_done || aw.w_handshake;

    /*************
    * axi w stage
    *************/

    li_axi_w_stg_t w;

    assign o_wvalid = w.r_valid;
    assign o_wdata = w.w_data;
    assign o_wstrb = 16'hFFFF;
    assign o_wlast = w.r_last;

    assign w_deq = !w_empty && (w_propagate_aw2w || !aw.w_done);
    assign w.w_data = w_axi_data;

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            w.r_valid <= 1'b0;
            w.r_id <= 'h0;
            w.r_len <= 'h0;
            w.r_last <= 1'b0;
            w.r_bubble <= 1'b1;
            w.r_done <= 1'b1;
        end
        else if (w_propagate_aw2w) begin
            w.r_valid <= !w_empty;
            w.r_id <= aw.r_id;
            w.r_len <= aw.r_len;
            w.r_last <= !w_empty && (aw.r_len == 'd0);
            w.r_bubble <= aw.r_bubble;
            w.r_done <= aw.r_bubble;
        end
        else if (w_propagate_w2b) begin
            w.r_valid <= 1'b0;
            w.r_id <= 'h0;
            w.r_len <= 'h0;
            w.r_last <= 1'b0;
            w.r_bubble <= 1'b1;
            w.r_done <= 1'b1;
        end
        else begin 

            w.r_valid <= w_deq;

            if (w.w_handshake) begin

                if (w.r_len > 'd1) begin
                    w.r_len <= w.r_len - 'd1;
                end
                else if (w.r_len == 'd1) begin
                    w.r_len <= 'd0;
                    w.r_last <= 1'b1;
                end
                else begin
                    w.r_valid <= 1'b0;
                    w.r_len <= 'd0;
                    w.r_last <= 1'b0;
                    w.r_done <= 1'b1;
                end

            end
        end
    end

    assign w.w_handshake = w.r_valid && i_wready;
    assign w.w_done = w.r_done || (w.w_handshake && w.r_last);

    /*************
    * axi b stage
    *************/

    li_axi_b_stg_t b;

    logic [1:0] r_bresp;

    assign o_bready = b.r_ready;

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            b.r_ready <= 1'b1;
            b.r_id <= 'h0;
            b.r_bubble <= 1'b1;
            b.r_ackb <= 1'b1;
            b.r_ackw <= 1'b1;
            r_bresp <= 'h0;
        end
        else if (w_propagate_w2b) begin
            b.r_ready <= 1'b1;
            b.r_id <= w.r_id;
            b.r_bubble <= w.r_bubble;
            b.r_ackb <= w.r_bubble || b.r_ackw;
            b.r_ackw <= 1'b0;
        end
        else begin
            if (b.w_ackb) begin
                b.r_ackb <= 1'b1;
                r_bresp <= i_bresp;
            end
            if (b.w_ackw) begin
                b.r_ackw <= 1'b1;
                r_bresp <= i_bresp;
            end
        end
    end

    assign b.w_handshake = b.r_ready && i_bvalid;
    assign b.w_ackb = b.w_handshake && (i_bid == b.r_id);
    assign b.w_ackw = b.w_handshake && (i_bid == w.r_id);
    assign b.w_done = b.w_ackb || b.r_ackb;

    /*****************
    * propagate logic
    *****************/

    logic w_new_txn;

    assign w_new_txn = (w_burst_len >= (i_ctrl.w_max_burst)) || i_last;

    assign w_propagate_w2b = b.w_done && w.w_done;
    assign w_propagate_aw2w = b.w_done && w.w_done && aw.w_done;
    assign w_propagate_aw =  b.w_done && w.w_done && aw.w_done && w_new_txn;

    /****************
    * ar/r not used
    ****************/

     assign o_arvalid = 'h0;
     assign o_arid = 'h0;
     assign o_araddr = 'h0;
     assign o_arburst = 'h0;
     assign o_arsize = 'h0;
     assign o_arlen = 'h0;
     assign o_arcache = 'h0;
     assign o_arprot = 'h0;
     assign o_arqos = 'h0;
     assign o_arlock = 'h0;
     assign o_aruser = 'h0;

     assign o_rready = 1'b1;

endmodule
