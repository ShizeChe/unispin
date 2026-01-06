`default_nettype none
`timescale 1ns / 1ps
`include "include/dc.svh"
`include "include/rf.svh"

import "DPI-C" function int cmd_open(input string path);
import "DPI-C" function int cmd_accept_poll(input int timeout_ms);
import "DPI-C" function int cmd_getline(output byte unsigned line_buf[]);

module simulator;

    // define number of dc/rf/li channels
    localparam NUM_DC_CHANNEL=24;
    localparam NUM_RF_CHANNEL=6;
    localparam NUM_LI_CHANNEL=1;

    // clocks and reset
    logic w_clk, w_rf_dac_clk, w_rst;

    // dc axi bus
    logic [0:NUM_DC_CHANNEL-1] w_dc_awvalid_bus;
    logic [0:NUM_DC_CHANNEL-1] w_dc_awready_bus;
    logic [0:NUM_DC_CHANNEL-1][$clog2(DC_TOTAL_REGS*4)-1:0] w_dc_awaddr_bus;

    logic [0:NUM_DC_CHANNEL-1] w_dc_wvalid_bus;
    logic [0:NUM_DC_CHANNEL-1] w_dc_wready_bus;
    logic [0:NUM_DC_CHANNEL-1][31:0] w_dc_wdata_bus;
    logic [0:NUM_DC_CHANNEL-1][3:0] w_dc_wstrb_bus;

    logic [0:NUM_DC_CHANNEL-1] w_dc_bvalid_bus;
    logic [0:NUM_DC_CHANNEL-1] w_dc_bready_bus;
    logic [0:NUM_DC_CHANNEL-1][1:0] w_dc_bresp_bus;

    logic [0:NUM_DC_CHANNEL-1][0:DC_TOTAL_REGS-1][31:0] w_dc_regs;

    // dc spi bus
    logic [0:NUM_DC_CHANNEL-1] w_dc_sclk_bus;
    logic [0:NUM_DC_CHANNEL-1] w_dc_mosi_bus;
    logic [0:NUM_DC_CHANNEL-1] w_dc_miso_bus;
    logic [0:NUM_DC_CHANNEL-1] w_dc_cs_n_bus;
    logic [0:NUM_DC_CHANNEL-1] w_dc_ldac_n_bus;

    // dc armed/start bus
    logic [NUM_DC_CHANNEL-1:0] w_dc_armed_bus;
    logic [NUM_DC_CHANNEL-1:0] w_dc_start_bus;
    logic [0:NUM_DC_CHANNEL-1] w_dc_empty_bus;

    // voltage output
    logic [DC_DAC_WIDTH-1:0] vdc_digital [NUM_DC_CHANNEL];
    real vdc [NUM_DC_CHANNEL];

    // dc module instantiation
    for (genvar i = 0; i < NUM_DC_CHANNEL; i++) begin : DC_GEN

        dc_regs #(
            .NUM_REGS(DC_TOTAL_REGS)
        ) REGS (
            .s_axi_aclk(w_clk),
            .s_axi_aresetn(!w_rst),

            .s_axi_awvalid(w_dc_awvalid_bus[i]), 
            .s_axi_awready(w_dc_awready_bus[i]),
            .s_axi_awaddr(w_dc_awaddr_bus[i]),

            .s_axi_wvalid(w_dc_wvalid_bus[i]),
            .s_axi_wready(w_dc_wready_bus[i]),
            .s_axi_wdata(w_dc_wdata_bus[i]),
            .s_axi_wstrb(w_dc_wstrb_bus[i]),

            .s_axi_bvalid(w_dc_bvalid_bus[i]),
            .s_axi_bready(w_dc_bready_bus[i]),
            .s_axi_bresp(w_dc_bresp_bus[i]),

            // leave read ports unconencted
            .s_axi_arvalid(1'b0),
            .s_axi_arready(),
            .s_axi_araddr(($clog2(DC_TOTAL_REGS*4))'('h0)),

            .s_axi_rvalid(),
            .s_axi_rready(1'b1),
            .s_axi_rdata(),
            .s_axi_rresp(),

            .o_regs(w_dc_regs[i])
        );

        dc DC (
            .i_clk(w_clk),
            .i_rst(w_rst),

            .i_regs(w_dc_regs[i]),

            .o_sclk(w_dc_sclk_bus[i]),
            .o_mosi(w_dc_mosi_bus[i]),
            .i_miso(w_dc_miso_bus[i]),
            .o_cs_n(w_dc_cs_n_bus[i]),
            .o_ldac_n(w_dc_ldac_n_bus[i]),

            .i_start(w_dc_start_bus[i]),
            .o_armed(w_dc_armed_bus[i])
        );

        ad5791 DAC (
            .SCLK(w_dc_sclk_bus[i]),
            .SDIN(w_dc_mosi_bus[i]),
            .SYNC_N(w_dc_cs_n_bus[i]),
            .SDO(w_dc_miso_bus[i]),
            .LDAC_N(w_dc_ldac_n_bus[i]),

            .CLR_N(1'b1),
            .RESET_N(1'b1),

            .VDIGITAL(vdc_digital[i]),
            .VOUT(vdc[i])
        );

        assign w_dc_empty_bus[i] = DC.CORE.i_empty && DC.CORE.i.r_bubble &&
            DC.CORE.s.r_spi_done && DC.CORE.h.r_cycles_left == 'd0;

    end

    // rf axi bus
    logic [0:NUM_RF_CHANNEL-1] w_rf_awvalid_bus;
    logic [0:NUM_RF_CHANNEL-1] w_rf_awready_bus;
    logic [0:NUM_RF_CHANNEL-1][$clog2(RF_TOTAL_REGS*4)-1:0] w_rf_awaddr_bus;

    logic [0:NUM_RF_CHANNEL-1] w_rf_wvalid_bus;
    logic [0:NUM_RF_CHANNEL-1] w_rf_wready_bus;
    logic [0:NUM_RF_CHANNEL-1][31:0] w_rf_wdata_bus;
    logic [0:NUM_RF_CHANNEL-1][3:0] w_rf_wstrb_bus;

    logic [0:NUM_RF_CHANNEL-1] w_rf_bvalid_bus;
    logic [0:NUM_RF_CHANNEL-1] w_rf_bready_bus;
    logic [0:NUM_RF_CHANNEL-1][1:0] w_rf_bresp_bus;

    logic [0:NUM_RF_CHANNEL-1][0:RF_TOTAL_REGS-1][31:0] w_rf_regs;

    // rf QIx8 bus
    logic [0:NUM_RF_CHANNEL-1][RF_DAC_WIDTH*16-1:0] w_rf_QIx8_bus;

    // rf armed/start bus
    logic [NUM_RF_CHANNEL-1:0] w_rf_armed_bus;
    logic [NUM_RF_CHANNEL-1:0] w_rf_start_bus;
    logic [0:NUM_RF_CHANNEL-1] w_rf_empty_bus;

    // rf output
    logic [RF_IQ_WIDTH-1:0] vrf_Q [NUM_RF_CHANNEL];
    logic [RF_IQ_WIDTH-1:0] vrf_I [NUM_RF_CHANNEL];
    real vrf [NUM_RF_CHANNEL];

    // rf module instantiation
    for (genvar i = 0; i < NUM_RF_CHANNEL; i++) begin : RF_GEN

        rf_regs #(
            .NUM_REGS(RF_TOTAL_REGS)
        ) REGS (
            .s_axi_aclk(w_clk),
            .s_axi_aresetn(!w_rst),

            .s_axi_awvalid(w_rf_awvalid_bus[i]), 
            .s_axi_awready(w_rf_awready_bus[i]),
            .s_axi_awaddr(w_rf_awaddr_bus[i]),

            .s_axi_wvalid(w_rf_wvalid_bus[i]),
            .s_axi_wready(w_rf_wready_bus[i]),
            .s_axi_wdata(w_rf_wdata_bus[i]),
            .s_axi_wstrb(w_rf_wstrb_bus[i]),

            .s_axi_bvalid(w_rf_bvalid_bus[i]),
            .s_axi_bready(w_rf_bready_bus[i]),
            .s_axi_bresp(w_rf_bresp_bus[i]),

            // leave read ports unconencted
            .s_axi_arvalid(1'b0),
            .s_axi_arready(),
            .s_axi_araddr(($clog2(RF_TOTAL_REGS*4))'('h0)),

            .s_axi_rvalid(),
            .s_axi_rready(1'b1),
            .s_axi_rdata(),
            .s_axi_rresp(),

            .o_regs(w_rf_regs[i])
        );

        rf RF (
            .i_clk(w_clk),
            .i_rst(w_rst),

            .i_regs(w_rf_regs[i]),

            .o_QIx8(w_rf_QIx8_bus[i]),

            .i_start(w_rf_start_bus[i]),
            .o_armed(w_rf_armed_bus[i])
        );

        zcu216_dac DAC (
            .i_clk(w_clk),
            .i_dac_clk(w_rf_dac_clk),
            .i_QIx8(w_rf_QIx8_bus[i]),
            .o_I(vrf_I[i]),
            .o_Q(vrf_Q[i]),
            .o_vrf(vrf[i])
        );

        assign w_rf_empty_bus[i] = RF.CORE.i_empty && RF.CORE.p.r_samples_left == 'd0 &&
            (&{RF.CORE.r[0].r_bubble, RF.CORE.r[1].r_bubble, RF.CORE.r[2].r_bubble, RF.CORE.r[3].r_bubble,
               RF.CORE.r[4].r_bubble, RF.CORE.r[5].r_bubble, RF.CORE.r[6].r_bubble, RF.CORE.r[7].r_bubble});

    end

    // launch axi bus
    logic w_lch_awvalid;
    logic w_lch_awready;
    logic [$clog2(LCH_TOTAL_REGS*4)-1:0] w_lch_awaddr;

    logic w_lch_wvalid;
    logic w_lch_wready;
    logic [31:0] w_lch_wdata;
    logic [3:0] w_lch_wstrb;

    logic w_lch_bvalid;
    logic w_lch_bready;
    logic [1:0] w_lch_bresp;

    logic [0:LCH_TOTAL_REGS-1][31:0] w_lch_regs;

    // launch module instantiation
    launch_regs #(
        .NUM_REGS(LCH_TOTAL_REGS)
    ) LCH_REGS (
        .s_axi_aclk(w_clk),
        .s_axi_aresetn(!w_rst),

        .s_axi_awvalid(w_lch_awvalid), 
        .s_axi_awready(w_lch_awready),
        .s_axi_awaddr(w_lch_awaddr),

        .s_axi_wvalid(w_lch_wvalid),
        .s_axi_wready(w_lch_wready),
        .s_axi_wdata(w_lch_wdata),
        .s_axi_wstrb(w_lch_wstrb),

        .s_axi_bvalid(w_lch_bvalid),
        .s_axi_bready(w_lch_bready),
        .s_axi_bresp(w_lch_bresp),

        // leave read ports unconencted
        .s_axi_arvalid(1'b0),
        .s_axi_arready(),
        .s_axi_araddr(($clog2(LCH_TOTAL_REGS*4))'('h0)),

        .s_axi_rvalid(),
        .s_axi_rready(1'b1),
        .s_axi_rdata(),
        .s_axi_rresp(),

        .o_regs(w_lch_regs)
    );

    launch #(
        .NUM_DC_CHANNEL(NUM_DC_CHANNEL),
        .NUM_RF_CHANNEL(NUM_RF_CHANNEL),
        .NUM_LI_CHANNEL(NUM_LI_CHANNEL)
    ) LCH (
        .i_clk(w_clk),
        .i_rst(w_rst),

        .i_regs(w_lch_regs),

        .i_dc_armed(w_dc_armed_bus),
        .i_rf_armed(w_rf_armed_bus),
        .i_li_armed(NUM_LI_CHANNEL'('h0)),

        .i_trigger(1'b1),

        .o_dc_start(w_dc_start_bus),
        .o_rf_start(w_rf_start_bus),
        .o_li_start()
    );

    // axi write tasks

    localparam ADDR_BITS = 12;

    task automatic axil_write 
        (input  logic i_aclk,

         output logic o_awvalid,
         input  logic i_awready,

         output logic o_wvalid,
         input  logic i_wready,

         input  logic i_bvalid,
         output logic o_bready,
         input  logic [1:0] i_bresp);

        $display("axil_write");

        @(negedge i_aclk);
        $display("negedge");
        o_awvalid = 1'b1;
        o_wvalid = 1'b1;
        o_bready = 1'b0;

        $display("pre fork");

        fork 

            begin: AWREADY
                wait(i_awready);
            end
            
            begin: WREADY
                wait(i_wready);
            end

        join

        $display("post fork");

        @(negedge i_aclk);
        o_awvalid = 1'b0;
        o_wvalid = 1'b0;
        o_bready = 1'b1;

        wait(i_bvalid);
        @(negedge i_aclk);

        assert (i_bresp == 2'b00)
        else $fatal(1, "Bad bresp: %0b", i_bresp);

        o_bready = 1'b0;

    endtask

    task automatic dc_axil_write(int ch); 

        $display("dc_axil_write channel%0d", ch);

        @(negedge w_clk);

        w_dc_awvalid_bus[ch] = 1'b1;
        w_dc_wvalid_bus[ch] = 1'b1;
        w_dc_bready_bus[ch] = 1'b0;

        $display("pre fork");

        fork 

            begin: AWREADY
                forever begin
                    if (w_dc_awvalid_bus[ch] && w_dc_awready_bus[ch]) begin
                        @(negedge w_clk);
                        w_dc_awvalid_bus[ch] = 1'b0;
                        break;
                    end
                    else @(negedge w_clk);
                end
            end
            
            begin: WREADY
                forever begin
                    if (w_dc_wvalid_bus[ch] && w_dc_wready_bus[ch]) begin
                        @(negedge w_clk);
                        w_dc_wvalid_bus[ch] = 1'b0;
                        break;
                    end
                    else @(negedge w_clk);
                end
            end

        join

        $display("post fork");
        w_dc_bready_bus[ch] = 1'b1;

        forever begin
            if (w_dc_bvalid_bus[ch] && w_dc_bready_bus[ch]) begin
                @(negedge w_clk);
                w_dc_bready_bus[ch] = 1'b0;
                assert (w_dc_bresp_bus[ch] == 2'b00)
                else $fatal(1, "Bad bresp: %0b", w_dc_bresp_bus[ch]);
                break;
            end
            else @(negedge w_clk);
        end

    endtask

    task automatic rf_axil_write(int ch); 

        $display("rf_axil_write channel%0d", ch);

        @(negedge w_clk);

        w_rf_awvalid_bus[ch] = 1'b1;
        w_rf_wvalid_bus[ch] = 1'b1;
        w_rf_bready_bus[ch] = 1'b0;

        $display("pre fork");

        fork 

            begin: AWREADY
                forever begin
                    if (w_rf_awvalid_bus[ch] && w_rf_awready_bus[ch]) begin
                        @(negedge w_clk);
                        w_rf_awvalid_bus[ch] = 1'b0;
                        break;
                    end
                    else @(negedge w_clk);
                end
            end
            
            begin: WREADY
                forever begin
                    if (w_rf_wvalid_bus[ch] && w_rf_wready_bus[ch]) begin
                        @(negedge w_clk);
                        w_rf_wvalid_bus[ch] = 1'b0;
                        break;
                    end
                    else @(negedge w_clk);
                end
            end

        join

        $display("post fork");
        w_rf_bready_bus[ch] = 1'b1;

        forever begin
            if (w_rf_bvalid_bus[ch] && w_rf_bready_bus[ch]) begin
                @(negedge w_clk);
                w_rf_bready_bus[ch] = 1'b0;
                assert (w_rf_bresp_bus[ch] == 2'b00)
                else $fatal(1, "Bad bresp: %0b", w_rf_bresp_bus[ch]);
                break;
            end
            else @(negedge w_clk);
        end

    endtask

    task automatic lch_axil_write; 

        $display("lch_axil_write");

        @(negedge w_clk);

        w_lch_awvalid = 1'b1;
        w_lch_wvalid = 1'b1;
        w_lch_bready = 1'b0;

        $display("pre fork");

        fork 

            begin: AWREADY
                forever begin
                    if (w_lch_awvalid && w_lch_awready) begin
                        @(negedge w_clk);
                        w_lch_awvalid = 1'b0;
                        break;
                    end
                    else @(negedge w_clk);
                end
            end
            
            begin: WREADY
                forever begin
                    if (w_lch_wvalid && w_lch_wready) begin
                        @(negedge w_clk);
                        w_lch_wvalid = 1'b0;
                        break;
                    end
                    else @(negedge w_clk);
                end
            end

        join

        $display("post fork");
        w_lch_bready = 1'b1;

        forever begin
            if (w_lch_bvalid && w_lch_bready) begin
                @(negedge w_clk);
                w_lch_bready = 1'b0;
                assert (w_lch_bresp == 2'b00)
                else $fatal(1, "Bad bresp: %0b", w_lch_bresp);
                break;
            end
            else @(negedge w_clk);
        end

    endtask

    task automatic axil_bus_write(input logic [31:0] addr, data);

        int i = addr[31:ADDR_BITS];

        if (0 <= i && i < NUM_DC_CHANNEL) begin
            
            $display("dc%0d", i);

            w_dc_awaddr_bus[i] = addr[$clog2(DC_TOTAL_REGS*4)-1:0];
            w_dc_wdata_bus[i] = data;
            w_dc_wstrb_bus[i] = 4'hf;

            dc_axil_write(i);

            $display("dc%0d axil write finished", i);

        end
        else if (NUM_DC_CHANNEL <= i && i < (NUM_DC_CHANNEL + NUM_RF_CHANNEL)) begin

            $display("rf%0d", i - NUM_DC_CHANNEL);

            w_rf_awaddr_bus[i - NUM_DC_CHANNEL] = addr[$clog2(RF_TOTAL_REGS*4)-1:0];
            w_rf_wdata_bus[i - NUM_DC_CHANNEL] = data;
            w_rf_wstrb_bus[i - NUM_DC_CHANNEL] = 4'hf;

            rf_axil_write(i - NUM_DC_CHANNEL);

            $display("dc%0d axil write finished", i);

        end
        else begin

            $display("launch"); 

            w_lch_awaddr = addr[$clog2(LCH_TOTAL_REGS*4)-1:0];
            w_lch_wdata = data;
            w_lch_wstrb = 4'hf;

            lch_axil_write;

            $display("launch axil write finished");

        end

    endtask

    // clocks
    initial begin
        w_clk = 1'b0;
        forever #2 w_clk = !w_clk;
    end

    initial begin
        w_rf_dac_clk = 1'b1;
        forever #0.25 w_rf_dac_clk = !w_rf_dac_clk;
    end

    // reset
    initial begin

        w_dc_awvalid_bus = 'h0;
        w_dc_wvalid_bus = 'h0;
        w_dc_bready_bus = 'h0;

        w_rf_awvalid_bus = 'h0;
        w_rf_wvalid_bus = 'h0;
        w_rf_bready_bus = 'h0;

        w_lch_awvalid = 'h0;
        w_lch_wvalid = 'h0;
        w_lch_bready = 'h0;

        w_rst = 1'b1;
        @(negedge w_clk);
        w_rst = 1'b0;

    end

    // tracker

    logic [NUM_DC_CHANNEL-1:0] dc_armed;
    logic [NUM_RF_CHANNEL-1:0] rf_armed;

    int all_empty;

    initial begin

        dc_armed = 'h0;
        rf_armed = 'h0;
        all_empty = 1;

        forever begin

            @(negedge w_clk);

            for (int i = 0; i < NUM_DC_CHANNEL; i++) begin

                if (!dc_armed[i] && w_dc_armed_bus[i])
                    $display("At %0.3f: DC %0d armed", $realtime, i);
                else if (dc_armed[i] && !w_dc_armed_bus[i])
                    $display("At %0.3f: DC %0d started", $realtime, i);

                dc_armed[i] = w_dc_armed_bus[i];

            end

            for (int i = 0; i < NUM_RF_CHANNEL; i++) begin

                if (!rf_armed[i] && w_rf_armed_bus[i])
                    $display("At %0.3f: RF %0d armed", $realtime, i);
                else if (rf_armed[i] && !w_rf_armed_bus[i])
                    $display("At %0.3f: RF %0d started", $realtime, i);

                rf_armed[i] = w_rf_armed_bus[i];

            end

            if (LCH.w_all_ready) begin
                $display("At %0.3f: LAUNCH sees all ready", $realtime);
            end

            if (all_empty && !(w_dc_empty_bus == {(NUM_DC_CHANNEL){1'b1}} && 
                w_rf_empty_bus == {(NUM_RF_CHANNEL){1'b1}})) begin
                $display("At %0.3f: not all empty", $realtime);
                all_empty = 0;
            end
            else if (!all_empty && (w_dc_empty_bus == {(NUM_DC_CHANNEL){1'b1}} && 
                w_rf_empty_bus == {(NUM_RF_CHANNEL){1'b1}})) begin
                $display("At %0.3f: all empty", $realtime);
                all_empty = 1;
            end

        end
    end

    // file interface
    // int fd, fd_writer;
    // string line;
    // string fifo_in;
    //
    // logic [31:0] addr, data;
    // longint unsigned t;
    //
    // initial begin
    //
    //     $value$plusargs("FIFO_IN=%s", fifo_in);
    //
    //     fd_writer = $fopen(fifo_in, "w");
    //     fd = $fopen(fifo_in, "r");
    //     if (fd == 0) 
    //         $fatal(1, "Failed to open %s", fifo_in);
    //
    //     $display("Simulator ready");
    //
    //     forever begin
    //
    //         if (!$feof(fd) && $fgets(line, fd)) begin
    //
    //             if ($sscanf(line, "0x%8h 0x%8h", addr, data) == 2) begin
    //
    //                 $display("RX addr=%08h data=%08h", addr, data);
    //
    //                 axil_bus_write(addr, data);
    //                 t = $urandom_range(0, 50);
    //                 $display("Advance %0d cycles", t / 4);
    //                 repeat($urandom_range(0, 10)) @(negedge w_clk);
    //
    //             end
    //             else if ($sscanf(line, "run %d", t)) begin
    //
    //                 $display("Advance %0d cycles", t / 4);
    //                 repeat(t / 4) @(negedge w_clk);
    //
    //             end
    //             else begin
    //                 $fatal(1, "Bad line: %s", line);
    //             end
    //
    //         end 
    //         else begin
    //             // $display("fgets failed");
    //             // $fclose(fd);
    //             // $display("fclose returned");
    //             // fd = $fopen(fifo_in, "r");
    //             // $display("fopen returned");
    //             // if (fd == 0) $fatal(1, "reopen failed");
    //         end
    //
    //     end
    //
    // end

    logic [31:0] addr, data;
    longint unsigned t;
    int rc;
    localparam LINE_MAX = 512;
    byte unsigned line_buf[LINE_MAX];
    string line;

    function automatic string bytes2string(input byte unsigned b[]);
        string s = "";
        for (int i = 0; i < b.size(); i++) begin
            if (b[i] == 0) break;           // stop at NUL
            s = {s, byte'(b[i])};
        end
        return s;
    endfunction

    task wait_client;
        $display("Waiting for command connection...");
        forever begin
            if (cmd_accept_poll(100) == 0)
                break;
        end
        $display("Client connected");
    endtask

    initial begin
        rc = cmd_open("/tmp/tb_cmd.sock");
        if (rc != 0) $fatal("cmd_open failed");

        wait_client;

        forever begin

            rc = cmd_getline(line_buf);

            if (rc == 1) begin
                line = bytes2string(line_buf);
                $display("RX: %s", line);

                if ($sscanf(line, "0x%8h 0x%8h", addr, data) == 2) begin
                    axil_bus_write(addr, data);
                end
                else if ($sscanf(line, "run %d", t) == 1) begin
                    repeat (t/4) @(negedge w_clk);
                end
                else begin
                    $display("Unknown command: %s", line);
                end

            end else if (rc == 0) begin
                $display("Client disconnected, waiting...");
                wait_client;
            end else begin
                $fatal("cmd_getline error");
            end
        end
    end

endmodule

