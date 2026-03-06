// `default_nettype none
`timescale 1ns / 1ps
`include "li.svh"

module li_save_vip_tb;

    typedef axi_vip_0_pkg::axi_vip_0_slv_mem_t axi_mem_t;

    logic w_clk, w_rst;

    // aw
    logic w_awvalid;
    logic w_awready;
    logic [5:0] w_awid;
    logic [48:0] w_awaddr;
    logic [1:0] w_awburst;
    logic [2:0] w_awsize;
    logic [7:0] w_awlen;
    logic [3:0] w_awcache;
    logic [2:0] w_awprot;
    logic [3:0] w_awqos;
    logic w_awlock;
    logic w_awuser;

    // w
    logic w_wvalid;
    logic w_wready;
    logic [127:0] w_wdata;
    logic [15:0] w_wstrb;
    logic w_wlast;
    logic [3:0] w_awregion;

    // b
    logic w_bvalid;
    logic w_bready;
    logic [5:0] w_bid;
    logic [1:0] w_bresp;

    // ar
    logic w_arvalid;
    logic w_arready;
    logic [5:0] w_arid;
    logic [48:0] w_araddr;
    logic [1:0] w_arburst;
    logic [2:0] w_arsize;
    logic [7:0] w_arlen;
    logic [3:0] w_arcache;
    logic [2:0] w_arprot;
    logic [3:0] w_arqos;
    logic w_arlock;
    logic w_aruser;

    // r
    logic w_rvalid;
    logic w_rready;
    logic [5:0] w_rid;
    logic [127:0] w_rdata;
    logic [1:0] w_rresp;
    logic w_rlast;
    
    li_ctrl_t w_ctrl;
    logic [127:0] w_QIx4;
    logic [3:0] w_validx4;
    logic w_last;

    assign w_ctrl = '{
        w_default_I: 'h0,
        w_default_Q: 'h0,
        w_max_burst: 'd15,
        w_base_addr: 'h0,
        w_clear_lost: 1'b0
    };

    li_save DUT (
        .i_clk      (w_clk),
        .i_rst      (w_rst),

        // interface with li core
        .i_validx4  (w_validx4),
        .i_last     (w_last),
        .i_QIx4     (w_QIx4),
        .i_ctrl     (w_ctrl),

        // aw
        .o_awvalid  (w_awvalid),
        .i_awready  (w_awready),
        .o_awid     (w_awid),
        .o_awaddr   (w_awaddr),
        .o_awburst  (w_awburst),
        .o_awsize   (w_awsize),
        .o_awlen    (w_awlen),
        .o_awcache  (w_awcache),
        .o_awprot   (w_awprot),
        .o_awqos    (w_awqos),
        .o_awlock   (w_awlock),
        .o_awuser   (w_awuser),

        // w
        .o_wvalid   (w_wvalid),
        .i_wready   (w_wready),
        .o_wdata    (w_wdata),
        .o_wstrb    (w_wstrb),
        .o_wlast    (w_wlast),

        // b
        .i_bvalid   (w_bvalid),
        .o_bready   (w_bready),
        .i_bid      (w_bid),
        .i_bresp    (w_bresp),

        // ar
        .o_arvalid  (w_arvalid),
        .i_arready  (w_arready),
        .o_arid     (w_arid),
        .o_araddr   (w_araddr),
        .o_arburst  (w_arburst),
        .o_arsize   (w_arsize),
        .o_arlen    (w_arlen),
        .o_arcache  (w_arcache),
        .o_arprot   (w_arprot),
        .o_arqos    (w_arqos),
        .o_arlock   (w_arlock),
        .o_aruser   (w_aruser),

        // r
        .i_rvalid   (w_rvalid),
        .o_rready   (w_rready),
        .i_rid      (w_rid),
        .i_rdata    (w_rdata),
        .i_rresp    (w_rresp),
        .i_rlast    (w_rlast)
    );

    assign w_arready = 1'b0;
    assign w_rvalid = 1'b0;
    assign w_rid = 'h0;
    assign w_rdata = 'h0;
    assign w_rresp = 'h0;
    assign w_rlast = 1'b0;
    assign w_awregion = 'h0;

    axi_vip_0 XILINX_VIP (
        .aclk          (w_clk),
        .aresetn       (!w_rst),

        // ---------------- AW ----------------
        .s_axi_awid     (w_awid),
        .s_axi_awaddr   (w_awaddr),
        .s_axi_awlen    (w_awlen),
        .s_axi_awsize   (w_awsize),
        .s_axi_awburst  (w_awburst),
        .s_axi_awcache  (w_awcache),
        .s_axi_awprot   (w_awprot),
        .s_axi_awregion (w_awregion),
        .s_axi_awqos    (w_awqos),
        .s_axi_awuser   (w_awuser),     // 1-bit -> [0:0] is fine
        .s_axi_awvalid  (w_awvalid),
        .s_axi_awready  (w_awready),

        // ---------------- W ----------------
        .s_axi_wdata    (w_wdata),
        .s_axi_wstrb    (w_wstrb),
        .s_axi_wlast    (w_wlast),
        .s_axi_wvalid   (w_wvalid),
        .s_axi_wready   (w_wready),

        // ---------------- B ----------------
        .s_axi_bid      (w_bid),
        .s_axi_bresp    (w_bresp),
        .s_axi_bvalid   (w_bvalid),
        .s_axi_bready   (w_bready)
    );
    
    axi_mem_t axi_mem;

    initial begin
        axi_mem = new("axi_mem", XILINX_VIP.inst.IF);
        axi_mem.start_slave();
    end

    task dump_axi_vip_mem(input logic [48:0] base, input logic [48:0] words);
        logic [48:0] a;
        bit [127:0] d;
        for (logic [48:0] i = 'h0; i < words; i = i + 'd1) begin
            a = base + 49'd16*i;
            d = axi_mem.mem_model.backdoor_memory_read(a);
            $display("[%0t] VIP_MEM[0x%08h] = 0x%08h", $time, a, d);
        end
    endtask

    initial begin
        w_clk = 1'b0;
        forever #2 w_clk = !w_clk;
    end

    initial begin

        w_rst = 1'b1;
        @(negedge w_clk);
        w_rst = 1'b0;

        for (int i = 0; i < 100; i++) begin
            w_validx4 = 4'b1111;
            w_last = 1'b0;
            w_QIx4 = {
                16'(i * 8 + 7),
                16'(i * 8 + 6),
                16'(i * 8 + 5),
                16'(i * 8 + 4),
                16'(i * 8 + 3),
                16'(i * 8 + 2),
                16'(i * 8 + 1),
                16'(i * 8)
            };
            @(negedge w_clk);
        end
        w_validx4 = 4'b1111;
        w_last = 1'b1;
        w_QIx4 = {
            16'(100 * 8 + 7),
            16'(100 * 8 + 6),
            16'(100 * 8 + 5),
            16'(100 * 8 + 4),
            16'(100 * 8 + 3),
            16'(100 * 8 + 2),
            16'(100 * 8 + 1),
            16'(100 * 8)
        };
        @(negedge w_clk);

        repeat(10000) @(negedge w_clk);
        $display("try dump mem");
        dump_axi_vip_mem('h0000_0000, 4096);
        $finish;

    end

endmodule
