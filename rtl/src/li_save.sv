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

     // useless
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

     // useless
     output logic o_arlock,
     output logic o_aruser,

     // r
     input  logic i_rvalid,
     output logic o_rready,
     input  logic [5:0] i_rid,
     input  logic [127:0] i_rdata,
     input  logic [1:0] i_rresp,
     input  logic i_rlast);

     logic w_enq, w_deq;
     logic w_full, w_empty;

     logic [31:0] r_num_lost;
     logic [FIFO_ADDR_WIDTH-1:0] r_num_inbuf;

     assign w_enq = !w_full && ((i_validx4 == 4'b1111) || (i_last));

     always_ff @(posedge i_clk) begin
         if (i_rst) begin
             r_num_lost <= 'd0;
         end
         else if (i_ctrl.w_clear_lost) begin
             r_num_lost <= 'd0;
         end
         else if (w_full && ((i_validx4 == 4'b1111) || (i_last))) begin
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

     logic w_propagate_aw, w_propagate_aw2w, w_propagate_w2b;

     li_axi_aw_stg_t aw;

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
             aw <= '{
                 r_addr: i_ctrl.w_base_addr,
                 r_id: 'h0,
                 r_awvalid: 1'b0,
                 r_awid: 'h0,
                 r_awaddr: 'h0,
                 r_awlen: 'h0
             };
         end
         else if (w_propagate_aw) begin
             aw <= '{
                 r_addr: aw.r_addr + {40'h0, w_burst_len[3:0], 4'h0},
                 r_id: aw.r_id + 'd1,
                 r_awvalid: 1'b1,
                 r_awid: aw.r_id,
                 r_awaddr: aw.r_awaddr,
                 r_awlen: i_ctrl.w_max_burst > w_num_inbuf
             };
         end
     end


endmodule
