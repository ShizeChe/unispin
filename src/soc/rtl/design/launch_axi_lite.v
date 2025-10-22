`timescale 1ns / 1ps

module launch_axi_lite
    (input  wire s_axi_aclk,
     input  wire s_axi_aresetn,
     input  wire [10 : 0] s_axi_awaddr,
     input  wire [2 : 0] s_axi_awprot,
     input  wire s_axi_awvalid,
     output wire s_axi_awready,
     input  wire [31 : 0] s_axi_wdata,
     input  wire [3 : 0] s_axi_wstrb,
     input  wire s_axi_wvalid,
     output wire s_axi_wready,
     output wire [1 : 0] s_axi_bresp,
     output wire s_axi_bvalid,
     input  wire s_axi_bready,
     input  wire [10 : 0] s_axi_araddr,
     input  wire [2 : 0] s_axi_arprot,
     input  wire s_axi_arvalid,
     output wire s_axi_arready,
     output wire [31 : 0] s_axi_rdata,
     output wire [1 : 0] s_axi_rresp,
     output wire s_axi_rvalid,
     input  wire s_axi_rready,

     input  wire [23 : 0] dc_armed,
     input  wire [5 : 0] rf_armed,
     input  wire [1 : 0] li_armed,

     output wire [23 : 0] dc_start,
     output wire [5 : 0] rf_start,
     output wire [1 : 0] li_start);

    wire [127:0] w_regs;
    
    axi_lite_slave #(
        .NUM_REGS(258),
        .C_S_AXI_DATA_WIDTH(32),
        .C_S_AXI_ADDR_WIDTH(11)
    ) S_AXI (
        .S_AXI_ACLK(s_axi_aclk),
        .S_AXI_ARESETN(s_axi_aresetn),
        .S_AXI_AWADDR(s_axi_awaddr),
        .S_AXI_AWPROT(s_axi_awprot),
        .S_AXI_AWVALID(s_axi_awvalid),
        .S_AXI_AWREADY(s_axi_awready),
        .S_AXI_WDATA(s_axi_wdata),
        .S_AXI_WSTRB(s_axi_wstrb),
        .S_AXI_WVALID(s_axi_wvalid),
        .S_AXI_WREADY(s_axi_wready),
        .S_AXI_BRESP(s_axi_bresp),
        .S_AXI_BVALID(s_axi_bvalid),
        .S_AXI_BREADY(s_axi_bready),
        .S_AXI_ARADDR(s_axi_araddr),
        .S_AXI_ARPROT(s_axi_arprot),
        .S_AXI_ARVALID(s_axi_arvalid),
        .S_AXI_ARREADY(s_axi_arready),
        .S_AXI_RDATA(s_axi_rdata),
        .S_AXI_RRESP(s_axi_rresp),
        .S_AXI_RVALID(s_axi_rvalid),
        .S_AXI_RREADY(s_axi_rready),
        .o_regs(w_regs)
    );

    launch #(
        .NUM_DC_CHANNEL(24),
        .NUM_RF_CHANNEL(6),
        .NUM_LI_CHANNEL(2)
    ) LAUNCH (
        .i_clk(s_axi_aclk),
        .i_rst(!s_axi_aresetn),
        .i_regs(w_regs),
        .i_dc_armed(dc_armed),
        .i_rf_armed(rf_armed),
        .i_li_armed(li_armed),
        .o_dc_start(dc_start),
        .o_rf_start(rf_start),
        .o_li_start(li_start)
    );

endmodule
