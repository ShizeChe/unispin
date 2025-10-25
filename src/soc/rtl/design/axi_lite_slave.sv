`timescale 1ns / 1ps

module axi_lite_slave
   #(parameter NUM_REGS=256,
     parameter C_S_AXI_DATA_WIDTH=32,
     parameter C_S_AXI_ADDR_WIDTH=10)
    (output logic [NUM_REGS-1:0][C_S_AXI_DATA_WIDTH-1:0] o_regs,

     input  logic S_AXI_ACLK,
     input  logic S_AXI_ARESETN,
     input  logic [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
     input  logic [2 : 0] S_AXI_AWPROT,
     input  logic S_AXI_AWVALID,
     output logic S_AXI_AWREADY,
     input  logic [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
     input  logic [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
     input  logic S_AXI_WVALID,
     output logic S_AXI_WREADY,
     output logic [1 : 0] S_AXI_BRESP,
     output logic S_AXI_BVALID,
     input  logic S_AXI_BREADY,
     input  logic [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
     input  logic [2 : 0] S_AXI_ARPROT,
     input  logic S_AXI_ARVALID,
     output logic S_AXI_ARREADY,
     output logic [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
     output logic [1 : 0] S_AXI_RRESP,
     output logic S_AXI_RVALID,
     input  logic S_AXI_RREADY);

    logic [C_S_AXI_ADDR_WIDTH-1 : 0] axi_awaddr;
    logic  axi_awready;
    logic  axi_wready;
    logic [1 : 0] axi_bresp;
    logic  axi_bvalid;
    logic [C_S_AXI_ADDR_WIDTH-1 : 0] axi_araddr;
    logic  axi_arready;
    logic [1 : 0] axi_rresp;
    logic  axi_rvalid;

    localparam ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
    localparam OPT_MEM_ADDR_BITS = C_S_AXI_ADDR_WIDTH - ADDR_LSB - 1;
    logic [C_S_AXI_DATA_WIDTH-1:0] slv_regs [NUM_REGS];

    assign S_AXI_AWREADY= axi_awready;
    assign S_AXI_WREADY= axi_wready;
    assign S_AXI_BRESP= axi_bresp;
    assign S_AXI_BVALID= axi_bvalid;
    assign S_AXI_ARREADY= axi_arready;
    assign S_AXI_RRESP= axi_rresp;
    assign S_AXI_RVALID= axi_rvalid;

    logic [1:0] state_write;
    logic [1:0] state_read;

    localparam Idle = 2'b00,Raddr = 2'b10,Rdata = 2'b11 ,Waddr = 2'b10,Wdata = 2'b11;

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_awready <= 0;
            axi_wready <= 0;
            axi_bvalid <= 0;
            axi_bresp <= 0;
            axi_awaddr <= 0;
            state_write <= Idle;
        end
        else begin

            case(state_write)

                Idle: begin
                    if (S_AXI_ARESETN == 1'b1) begin
                        axi_awready <= 1'b1;
                        axi_wready <= 1'b1;
                        state_write <= Waddr;
                    end
                    else state_write <= state_write;
                end

                Waddr: begin
                    if (S_AXI_AWVALID && S_AXI_AWREADY) begin
                        axi_awaddr <= S_AXI_AWADDR;
                        if(S_AXI_WVALID) begin
                            axi_awready <= 1'b1;
                            state_write <= Waddr;
                            axi_bvalid <= 1'b1;
                        end
                        else begin
                            axi_awready <= 1'b0;
                            state_write <= Wdata;
                            if (S_AXI_BREADY && axi_bvalid) axi_bvalid <= 1'b0;
                        end
                    end
                    else begin
                        state_write <= state_write;
                        if (S_AXI_BREADY && axi_bvalid) axi_bvalid <= 1'b0;
                    end
                end

                Wdata: begin
                    if (S_AXI_WVALID) begin
                        state_write <= Waddr;
                        axi_bvalid <= 1'b1;
                        axi_awready <= 1'b1;
                    end
                    else begin
                        state_write <= state_write;
                        if (S_AXI_BREADY && axi_bvalid) axi_bvalid <= 1'b0;
                    end
                end

            endcase
        end
    end

    for (genvar i = 0; i < NUM_REGS - 1; i++) begin

        always_ff @(posedge S_AXI_ACLK) begin

            if (S_AXI_ARESETN == 1'b0) slv_regs[i] <= 'd0;
            else begin

                if (S_AXI_WVALID && (S_AXI_AWVALID ? 
                    S_AXI_AWADDR[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] : 
                    axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB]) == i) begin

                    for (integer byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                        if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                            slv_regs[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                        end

                end

            end

        end

    end

    // one special counter down register
    always_ff @(posedge S_AXI_ACLK) begin

        if (S_AXI_ARESETN == 1'b0) slv_regs[NUM_REGS-1] <= 'd0;
        else begin

            if (S_AXI_WVALID && (S_AXI_AWVALID ? 
                S_AXI_AWADDR[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] : 
                axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB]) == NUM_REGS - 1)

                for (integer byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                        slv_regs[NUM_REGS-1][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                    end
            else
                slv_regs[NUM_REGS-1] <= (slv_regs[NUM_REGS-1] == 'h0) ? 'd0 : (slv_regs[NUM_REGS-1] - 'd1);

        end

    end

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_arready <= 1'b0;
            axi_rvalid <= 1'b0;
            axi_rresp <= 1'b0;
            state_read <= Idle;
        end
        else begin
            case(state_read)
                Idle: begin
                    if (S_AXI_ARESETN == 1'b1) begin
                    state_read <= Raddr;
                    axi_arready <= 1'b1;
                    end
                    else state_read <= state_read;
                end
                Raddr: begin
                    if (S_AXI_ARVALID && S_AXI_ARREADY) begin
                        state_read <= Rdata;
                        axi_araddr <= S_AXI_ARADDR;
                        axi_rvalid <= 1'b1;
                        axi_arready <= 1'b0;
                    end
                    else state_read <= state_read;
                    end
                Rdata: begin
                    if (S_AXI_RVALID && S_AXI_RREADY) begin
                        axi_rvalid <= 1'b0;
                        axi_arready <= 1'b1;
                        state_read <= Raddr;
                    end
                    else state_read <= state_read;
                end
            endcase
        end
    end

    // Implement memory mapped register select and read logic generation
    assign S_AXI_RDATA = slv_regs[axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB]];
    for (genvar i = 0; i < NUM_REGS; i++) begin
        assign o_regs[i] = slv_regs[i];
    end

endmodule
