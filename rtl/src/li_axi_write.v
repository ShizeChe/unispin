`timescale 1ns / 1ps

module li_axi_write
    (input  wire s_axi_aclk, s_axi_aresetn,

     // interface with li core
     input  wire [3:0] i_validx4,
     input  wire i_last,
     input  wire [127:0] i_QIx4,

     input  wire [85:0] i_ctrl,

     output wire [31:0] o_samples_lost,
     output wire [7:0] o_samples_inbuf,

     // aw
     output wire m_axi_awvalid,
     input  wire m_axi_awready,
     output wire [5:0] m_axi_awid,
     output wire [48:0] m_axi_awaddr,
     output wire [1:0] m_axi_awburst,
     output wire [2:0] m_axi_awsize,
     output wire [7:0] m_axi_awlen,
     output wire [3:0] m_axi_awcache,
     output wire [2:0] m_axi_awprot,
     output wire [3:0] m_axi_awqos,
     output wire m_axi_awlock,
     output wire m_axi_awuser,

     // w
     output wire m_axi_wvalid,
     input  wire m_axi_wready,
     output wire [127:0] m_axi_wdata,
     output wire [15:0] m_axi_wstrb,
     output wire m_axi_wlast,

     // b
     input  wire m_axi_bvalid,
     output wire m_axi_bready,
     input  wire [5:0] m_axi_bid,
     input  wire [1:0] m_axi_bresp,

     // ar
     output wire m_axi_arvalid,
     input  wire m_axi_arready,
     output wire [5:0] m_axi_arid,
     output wire [48:0] m_axi_araddr,
     output wire [1:0] m_axi_arburst,
     output wire [2:0] m_axi_arsize,
     output wire [7:0] m_axi_arlen,
     output wire [3:0] m_axi_arcache,
     output wire [2:0] m_axi_arprot,
     output wire [3:0] m_axi_arqos,
     output wire m_axi_arlock,
     output wire m_axi_aruser,

     // r
     input  wire m_axi_rvalid,
     output wire m_axi_rready,
     input  wire [5:0] m_axi_rid,
     input  wire [127:0] m_axi_rdata,
     input  wire [1:0] m_axi_rresp,
     input  wire m_axi_rlast);


    li_save #(
        .ADC_WIDTH(16),
        .FIFO_ADDR_WIDTH(8)
    ) LI_SAVE(
        .i_clk(s_axi_aclk),
        .i_rst(!s_axi_aresetn),

        .i_validx4(i_validx4),
        .i_last(i_last),
        .i_QIx4(i_QIx4),

        .i_ctrl(i_ctrl),

        .o_samples_lost(),
        .o_samples_inbuf(),

        // AW
        .o_awvalid(m_axi_awvalid),
        .i_awready(m_axi_awready),
        .o_awid(m_axi_awid),
        .o_awaddr(m_axi_awaddr),
        .o_awburst(m_axi_awburst),
        .o_awsize(m_axi_awsize),
        .o_awlen(m_axi_awlen),
        .o_awcache(m_axi_awcache),
        .o_awprot(m_axi_awprot),
        .o_awqos(m_axi_awqos),
        .o_awlock(m_axi_awlock),
        .o_awuser(m_axi_awuser),

        // W
        .o_wvalid(m_axi_wvalid),
        .i_wready(m_axi_wready),
        .o_wdata(m_axi_wdata),
        .o_wstrb(m_axi_wstrb),
        .o_wlast(m_axi_wlast),

        // B
        .i_bvalid(m_axi_bvalid),
        .o_bready(m_axi_bready),
        .i_bid(m_axi_bid),
        .i_bresp(m_axi_bresp),

        // AR
        .o_arvalid(m_axi_arvalid),
        .i_arready(m_axi_arready),
        .o_arid(m_axi_arid),
        .o_araddr(m_axi_araddr),
        .o_arburst(m_axi_arburst),
        .o_arsize(m_axi_arsize),
        .o_arlen(m_axi_arlen),
        .o_arcache(m_axi_arcache),
        .o_arprot(m_axi_arprot),
        .o_arqos(m_axi_arqos),
        .o_arlock(m_axi_arlock),
        .o_aruser(m_axi_aruser),

        // R
        .i_rvalid(m_axi_rvalid),
        .o_rready(m_axi_rready),
        .i_rid(m_axi_rid),
        .i_rdata(m_axi_rdata),
        .i_rresp(m_axi_rresp),
        .i_rlast(m_axi_rlast)
    );

endmodule
