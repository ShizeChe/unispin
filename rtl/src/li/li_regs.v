// `default_nettype none
`timescale 1ns / 1ps

module li_regs
   #(parameter NUM_SEQ_REGS=13,
     parameter NUM_CTRL_REGS=6,
     parameter NUM_STATUS_REGS=8,
     parameter ADDR_WIDTH=$clog2(NUM_SEQ_REGS+NUM_CTRL_REGS+NUM_STATUS_REGS)+2,
     parameter [31:0] ADDR_BASE=32'hA0000000)
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

     output wire [0:NUM_SEQ_REGS-1][31:0] o_seq_regs,
     output wire [0:NUM_CTRL_REGS-1][31:0] o_ctrl_regs,
     input  wire [0:NUM_STATUS_REGS-1][31:0] i_status_regs);

     axil_slave_regs #(
         .NUM_WRITE_REGS(NUM_SEQ_REGS+NUM_CTRL_REGS),
         .NUM_READ_REGS(NUM_STATUS_REGS),
         .ADDR_BASE(ADDR_BASE)
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

        .o_regs({o_seq_regs, o_ctrl_regs}),
        .i_regs(i_status_regs)
     );

endmodule
     
