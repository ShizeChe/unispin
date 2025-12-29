`timescale 1ns / 1ps

module axil_slave_regs
   #(parameter NUM_REGS=32,
     parameter ADDR_WIDTH=$clog2(NUM_REGS)+2)
    (input  logic i_aclk,
     input  logic i_aresetn,
     
     // write address
     input  logic i_awvalid,
     output logic o_awready,
     input  logic [ADDR_WIDTH-1:0] i_awaddr,

     // write data
     input  logic i_wvalid,
     output logic o_wready,
     input  logic [31:0] i_wdata,
     input  logic [3:0] i_wstrb,

     // write response
     output logic o_bvalid,
     input  logic i_bready,
     output logic [1:0] o_bresp,

     // read address
     input  logic i_arvalid,
     output logic o_arready,
     input  logic [ADDR_WIDTH-1:0] i_araddr,

     // read data
     output logic o_rvalid,
     input  logic i_rready,
     output logic [31:0] o_rdata,
     output logic [1:0] o_rresp,

     output logic [0:NUM_REGS-1][31:0] o_regs);

    logic [31:0] r_regs [NUM_REGS];

    // write logic
    always_ff @(posedge i_aclk) begin
        if (!i_aresetn) begin
            o_awready <= 1'b0;
            o_wready <= 1'b0;
            o_bvalid <= 1'b0;
        end
        else if (o_awready && o_wready) begin
            o_awready <= 1'b0;
            o_wready <= 1'b0;
            o_bvalid <= 1'b1;
        end
        else if (o_bvalid) begin
            o_awready <= (i_awvalid && i_wvalid && i_bready);
            o_wready <= (i_awvalid && i_wvalid && i_bready);
            o_bvalid <= !i_bready;
        end
        else if (i_awvalid && i_wvalid) begin
            o_awready <= 1'b1;
            o_wready <= 1'b1;
            o_bvalid <= 1'b0;
        end
        else begin
            o_awready <= 1'b0;
            o_wready <= 1'b0;
            o_bvalid <= 1'b0;
        end
    end

    // write handshake
    // initial begin
    //     for (int i = 0; i < NUM_REGS; i++)
    //         r_regs[i] = 'h0;
    // end

    logic [ADDR_WIDTH-3:0] w_awireg;
    logic [1:0] w_awls2b;

    assign {w_awireg, w_awls2b} = i_awaddr;

    logic [31:0] w_wdatastrb;

    always_comb begin
        w_wdatastrb = w_awireg < NUM_REGS ? r_regs[w_awireg] : 'h0;
        if (i_wstrb[3]) w_wdatastrb[31:24] = i_wdata[31:24];
        if (i_wstrb[2]) w_wdatastrb[23:16] = i_wdata[23:16];
        if (i_wstrb[1]) w_wdatastrb[15:8] = i_wdata[15:8];
        if (i_wstrb[0]) w_wdatastrb[7:0] = i_wdata[7:0];
    end

    always_ff @(posedge i_aclk) begin
        if (!i_aresetn) begin
            o_bresp <= 2'b00;
        end
        else begin 
            if (i_awvalid && o_awready && i_wvalid && o_wready) begin
                if (w_awireg < NUM_REGS && w_awls2b == 2'b00) begin
                    r_regs[w_awireg] <= w_wdatastrb;
                    o_bresp <= 2'b00;
                end
                else begin
                    o_bresp <= 2'b10;
                end
            end
            if (o_bvalid && i_bready) begin
                o_bresp <= 2'b00;
            end
        end
    end

    // read logic
    always_ff @(posedge i_aclk) begin
        if (!i_aresetn) begin
            o_arready <= 1'b0;
            o_rvalid <= 1'b0;
        end
        else if (o_arready) begin
            o_arready <= 1'b0;
            o_rvalid <= 1'b1;
        end
        else if (o_rvalid) begin
            o_arready <= (i_arvalid && i_rready);
            o_rvalid <= !i_rready;
        end
        else if (i_arvalid) begin
            o_arready <= 1'b1;
            o_rvalid <= 1'b0;
        end
        else begin
            o_arready <= 1'b0;
            o_rvalid <= 1'b0;
        end
    end

    // read handshake
    logic [ADDR_WIDTH-3:0] w_arireg;
    logic [1:0] w_arls2b;

    assign {w_arireg, w_arls2b} = i_araddr;

    always_ff @(posedge i_aclk) begin
        if (!i_aresetn) begin
            o_rdata <= 'h0;
            o_rresp <= 2'b00;
        end
        else begin
            if (i_arvalid && o_arready) begin
                if (w_arireg < NUM_REGS && w_arls2b == 2'b00) begin
                    o_rdata <= r_regs[w_arireg];
                    o_rresp <= 2'b00;
                end
                else begin
                    o_rdata <= 'h0;
                    o_rresp <= 2'b10;
                end
            end
            if (o_rvalid && i_rready) begin
                o_rdata <= 'h0;
                o_rresp <= 2'b00;
            end
        end
    end

    always_comb begin
        for (int i = 0; i < NUM_REGS; i++)
            o_regs[i] = r_regs[i];
    end

`ifdef FORMAL

    logic [3:0] f_axi_rd_outstanding;
    logic [3:0] f_axi_wr_outstanding;
    logic [3:0] f_axi_awr_outstanding;

    faxil_slave #(
        .C_AXI_DATA_WIDTH(32),
        .C_AXI_ADDR_WIDTH(ADDR_WIDTH),
        .F_LGDEPTH(4)
    ) properties (
        .i_clk(i_aclk),
        .i_axi_reset_n(i_aresetn),
        //
        .i_axi_awaddr(i_awaddr),
        .i_axi_awprot(3'b000),
        .i_axi_awvalid(i_awvalid),
        .i_axi_awready(o_awready),
        //
        .i_axi_wdata(i_wdata),
        .i_axi_wstrb(i_wstrb),
        .i_axi_wvalid(i_wvalid),
        .i_axi_wready(o_wready),
        //
        .i_axi_bresp(o_bresp),
        .i_axi_bvalid(o_bvalid),
        .i_axi_bready(i_bready),
        //
        .i_axi_araddr(i_araddr),
        .i_axi_arprot(3'b000),
        .i_axi_arvalid(i_arvalid),
        .i_axi_arready(o_arready),
        //
        .i_axi_rdata(o_rdata),
        .i_axi_rresp(o_rresp),
        .i_axi_rvalid(o_rvalid),
        .i_axi_rready(i_rready),
        //
        .f_axi_rd_outstanding(f_axi_rd_outstanding),
        .f_axi_wr_outstanding(f_axi_wr_outstanding),
        .f_axi_awr_outstanding(f_axi_awr_outstanding)
    );

    initial begin
        o_awready = 1'b0;
        o_wready = 1'b0;
        o_bvalid = 1'b0;
        o_arready = 1'b0;
        o_rvalid = 1'b0;
    end

    always @(*)
        if (i_aresetn)
        begin
            assert(f_axi_rd_outstanding == ((o_rvalid)? 1:0));
            assert(f_axi_wr_outstanding == ((o_bvalid)? 1:0));
        end

	always @(*)
		assert(f_axi_awr_outstanding == f_axi_wr_outstanding);

    // faxil_register #(
    //     // {{{
    //     .AW(ADDR_WIDTH),
    //     .DW(32),
    //     .ADDR(32)
    //     // }}}
    // ) FAXIR (
    //     // {{{
    //     .S_AXI_ACLK(i_aclk),
    //     .S_AXI_ARESETN(i_aresetn),
    //     .S_AXIL_AWW(o_awready),
    //     .S_AXIL_AWADDR(i_awaddr),
    //     .S_AXIL_WDATA(i_wdata),
    //     .S_AXIL_WSTRB(i_wstrb),
    //     .S_AXIL_BVALID(o_bvalid),
    //     .S_AXIL_AR(o_arready),
    //     .S_AXIL_ARADDR(i_araddr),
    //     .S_AXIL_RVALID(o_rvalid),
    //     .S_AXIL_RDATA(o_rdata),
    //     .i_register(r_regs[8])
    //     // }}}
    // );

    for (genvar i = 0; i < NUM_REGS; i++) begin : FAXI_REGS
        faxil_register #(
            // {{{
            .AW(ADDR_WIDTH),
            .DW(32),
            .ADDR(i * 4)
            // }}}
        ) FAXIR (
            // {{{
            .S_AXI_ACLK(i_aclk),
            .S_AXI_ARESETN(i_aresetn),
            .S_AXIL_AWW(o_awready),
            .S_AXIL_AWADDR(i_awaddr),
            .S_AXIL_WDATA(i_wdata),
            .S_AXIL_WSTRB(i_wstrb),
            .S_AXIL_BVALID(o_bvalid),
            .S_AXIL_AR(o_arready),
            .S_AXIL_ARADDR(i_araddr),
            .S_AXIL_RVALID(o_rvalid),
            .S_AXIL_RDATA(o_rdata),
            .i_register(o_regs[i])
            // }}}
        );
    end

`endif 

endmodule
     
