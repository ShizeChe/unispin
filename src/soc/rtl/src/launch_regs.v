`timescale 1ns / 1ps
`include "include/launch.svh"

module launch_regs
   #(parameter NUM_REGS=LCH_TOTAL_REGS,
     parameter ADDR_WIDTH=$clog2(NUM_REGS)+2)
    (input  wire s_axi_aclk,
     input  wire s_axi_aresetn,
     
     // write address
     input  wire s_axi_awvalid,
     output wire s_axi_awready,
     input  wire [ADDR_WIDTH-1:0] s_axi_awaddr,

     // write data
     input  wire s_axi_wvalid,
     output wire s_axi_wready,
     input  wire [31:0] s_axi_wdata,
     input  wire [3:0] s_axi_wstrb,

     // write response
     output wire s_axi_bvalid,
     input  wire s_axi_bready,
     output wire [1:0] s_axi_bresp,

     // read address
     input  wire s_axi_arvalid,
     output wire s_axi_arready,
     input  wire [ADDR_WIDTH-1:0] s_axi_araddr,

     // read data
     output wire s_axi_rvalid,
     input  wire s_axi_rready,
     output wire [31:0] s_axi_rdata,
     output wire [1:0] s_axi_rresp,

     output wire [NUM_REGS-1:0][31:0] o_regs);

     axil_slave_regs #(
         .NUM_REGS(NUM_REGS)
     ) AXIL_REGS (

        .i_aclk(s_axi_aclk),
        .i_aresetn(s_axi_aresetn),

        .i_awvalid(s_axi_awvalid),
        .o_awready(s_axi_awready),
        .i_awaddr(s_axi_awaddr),

        .i_wvalid(s_axi_wvalid),
        .o_wready(s_axi_wready),
        .i_wdata(s_axi_wdata),
        .i_wstrb(s_axi_wstrb),

        .o_bvalid(s_axi_bvalid),
        .i_bready(s_axi_bready),
        .o_bresp(s_axi_bresp),

        .i_arvalid(s_axi_arvalid),
        .o_arready(s_axi_arready),
        .i_araddr(s_axi_araddr),

        .o_rvalid(s_axi_rvalid),
        .i_rready(s_axi_rready),
        .o_rdata(s_axi_rdata),
        .o_rresp(s_axi_rresp),

        .o_regs(o_regs)
     );

endmodule
     
