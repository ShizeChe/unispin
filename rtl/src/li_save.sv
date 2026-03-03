`timescale 1ns / 1ps

module li_save
   #()
    (input  logic i_clk, i_rst,

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



endmodule
