`default_nettype none
`timescale 1ns / 1ps
`include "include/dc.svh"
`include "include/rf.svh"
`include "include/li.svh"

import "DPI-C" function int cmd_open(input string path);
import "DPI-C" function int cmd_accept_poll(input int timeout_ms);
import "DPI-C" function int cmd_getline(output byte unsigned line_buf[]);

module simulator;

    // define number of dc/rf/li channels
    localparam NUM_DC_CHANNEL=24;
    localparam NUM_RF_CHANNEL=6;
    localparam NUM_LI_CHANNEL=2;
    localparam NUM_DEBOUNCE_CYCLES=25;

    /********************
    * signal declaration
    ********************/

    // clocks and reset
    logic w_dcrfli_clk, w_rf_dac_clk, w_li_adc_clk, w_dcrfli_rst_n;

    // dc axi bus
    localparam DC_TOTAL_REGS = DC_SEQ_REGS + DC_CTRL_REGS;

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

    logic [0:NUM_DC_CHANNEL-1][0:DC_SEQ_REGS-1][31:0] w_dc_seq_regs;
    logic [0:NUM_DC_CHANNEL-1][0:DC_CTRL_REGS-1][31:0] w_dc_ctrl_regs;

    // dc spi bus
    logic [0:NUM_DC_CHANNEL-1] w_dc_sclk_bus;
    logic [0:NUM_DC_CHANNEL-1] w_dc_mosi_bus;
    logic [0:NUM_DC_CHANNEL-1] w_dc_miso_bus;
    logic [0:NUM_DC_CHANNEL-1] w_dc_cs_n_bus;
    logic [0:NUM_DC_CHANNEL-1] w_dc_ldac_n_bus;

    // dc armed bus
    logic [NUM_DC_CHANNEL-1:0] w_dc_armed_bus;

    // dc empty bus
    logic [0:NUM_DC_CHANNEL-1] w_dc_empty_bus;

    // dc voltage output
    logic [DC_DAC_WIDTH-1:0] vdc_digital [NUM_DC_CHANNEL];
    real vdc [NUM_DC_CHANNEL];

    // rf axi bus
    localparam RF_TOTAL_REGS = RF_SEQ_REGS + RF_CTRL_REGS;

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

    logic [0:NUM_RF_CHANNEL-1][0:RF_SEQ_REGS-1][31:0] w_rf_seq_regs;
    logic [0:NUM_RF_CHANNEL-1][0:RF_CTRL_REGS-1][31:0] w_rf_ctrl_regs;

    // rf QIx8 bus
    logic [0:NUM_RF_CHANNEL-1][RF_DAC_WIDTH*16-1:0] w_rf_QIx8_bus;

    // rf armed bus
    logic [NUM_RF_CHANNEL-1:0] w_rf_armed_bus;

    // rf empty bus
    logic [0:NUM_RF_CHANNEL-1] w_rf_empty_bus;

    // rf nco bus
    logic [0:(NUM_RF_CHANNEL+1)/2-1] w_rf_nco_req_bus;
    logic [0:(NUM_RF_CHANNEL+1)/2-1] w_rf_nco_tile_busy_bus;
    logic [0:NUM_RF_CHANNEL-1] w_rf_nco_busy_bus;
    logic [0:NUM_RF_CHANNEL-1][RF_NCO_FREQ_WIDTH-1:0] w_rf_nco_freq_bus;
    logic [0:NUM_RF_CHANNEL-1][RF_NCO_PHASE_WIDTH-1:0] w_rf_nco_phase_bus;
    logic [0:NUM_RF_CHANNEL-1][RF_NCO_EN_WIDTH-1:0] w_rf_nco_en_bus;

    // rf voltage output
    logic [RF_IQ_WIDTH-1:0] vrf_Q [NUM_RF_CHANNEL];
    logic [RF_IQ_WIDTH-1:0] vrf_I [NUM_RF_CHANNEL];
    real vrf [NUM_RF_CHANNEL];

    // li axi bus
    localparam LI_TOTAL_REGS = LI_SEQ_REGS + LI_CTRL_REGS;

    logic [0:NUM_LI_CHANNEL-1] w_li_awvalid_bus;
    logic [0:NUM_LI_CHANNEL-1] w_li_awready_bus;
    logic [0:NUM_LI_CHANNEL-1][$clog2(LI_TOTAL_REGS*4)-1:0] w_li_awaddr_bus;

    logic [0:NUM_LI_CHANNEL-1] w_li_wvalid_bus;
    logic [0:NUM_LI_CHANNEL-1] w_li_wready_bus;
    logic [0:NUM_LI_CHANNEL-1][31:0] w_li_wdata_bus;
    logic [0:NUM_LI_CHANNEL-1][3:0] w_li_wstrb_bus;

    logic [0:NUM_LI_CHANNEL-1] w_li_bvalid_bus;
    logic [0:NUM_LI_CHANNEL-1] w_li_bready_bus;
    logic [0:NUM_LI_CHANNEL-1][1:0] w_li_bresp_bus;

    logic [0:NUM_LI_CHANNEL-1][0:LI_SEQ_REGS-1][31:0] w_li_seq_regs;
    logic [0:NUM_LI_CHANNEL-1][0:LI_CTRL_REGS-1][31:0] w_li_ctrl_regs;

    // li Ix8/Qx8 bus
    logic [0:NUM_LI_CHANNEL-1][LI_ADC_WIDTH*8-1:0] w_li_QIx4_bus;

    // li armed bus
    logic [NUM_LI_CHANNEL-1:0] w_li_armed_bus;

    // li empty bus
    logic [0:NUM_LI_CHANNEL-1] w_li_empty_bus;

    // li sample mask/spike bus
    logic [0:NUM_LI_CHANNEL-1][3:0] w_li_sample_mask_bus;
    logic [0:NUM_LI_CHANNEL-1] w_li_sample_spike_bus;

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

    logic w_trigger;
    
    // uart regs
    localparam TOTAL_UREGS=DC_SEQ_REGS+DC_CTRL_REGS+
                           RF_SEQ_REGS+RF_CTRL_REGS+
                           LI_SEQ_REGS+LI_CTRL_REGS+
                           LCH_TOTAL_REGS;

    localparam U_DC_SEQ_START = 0;
    localparam U_DC_SEQ_END = U_DC_SEQ_START + DC_SEQ_REGS - 1;

    localparam U_DC_CTRL_START = U_DC_SEQ_END + 1;
    localparam U_DC_CTRL_END = U_DC_CTRL_START + DC_CTRL_REGS - 1;

    localparam U_RF_SEQ_START = U_DC_CTRL_END + 1;
    localparam U_RF_SEQ_END = U_RF_SEQ_START + RF_SEQ_REGS - 1;

    localparam U_RF_CTRL_START = U_RF_SEQ_END + 1;
    localparam U_RF_CTRL_END = U_RF_CTRL_START + RF_CTRL_REGS - 1;

    localparam U_LI_SEQ_START = U_RF_CTRL_END + 1;
    localparam U_LI_SEQ_END = U_LI_SEQ_START + LI_SEQ_REGS - 1;

    localparam U_LI_CTRL_START = U_LI_SEQ_END + 1;
    localparam U_LI_CTRL_END = U_LI_CTRL_START + LI_CTRL_REGS - 1;

    localparam U_LCH_START = U_LI_CTRL_END + 1;
    localparam U_LCH_END = U_LCH_START + LCH_TOTAL_REGS - 1;

    logic [0:TOTAL_UREGS-1][31:0] w_uregs;

    logic w_rx, w_tx;

    /********************************
    * top-level module instantiation
    ********************************/

    uart_regs #(
        .DATA_WIDTH(8),
        .RX_FIFO_DEPTH(8),
        .RX_FIFO_AF_DEPTH(6),
        .RX_FIFO_AE_DEPTH(2),
        .TX_FIFO_DEPTH(8),
        .TX_FIFO_AF_DEPTH(6),
        .TX_FIFO_AE_DEPTH(2),
        .NUM_REGS(TOTAL_UREGS)
    ) UREGS (
        .i_clk(w_dcrfli_clk),
        .i_rst(!w_dcrfli_rst_n),
        .i_rx(w_rx),
        .o_tx(w_tx),
        .i_dvsr(11'd16),
        .o_regs(w_uregs)
    );

    logic i_btn_w;

    dcrfli_uart_btn #(
        .NUM_DC_CHANNEL(NUM_DC_CHANNEL),
        .NUM_RF_CHANNEL(NUM_RF_CHANNEL),
        .NUM_LI_CHANNEL(NUM_LI_CHANNEL),
        .NUM_DEBOUNCE_CYCLES(NUM_DEBOUNCE_CYCLES)
    ) DCRFLI (
        .i_clk(w_dcrfli_clk),
        .i_rst(!w_dcrfli_rst_n),

        // dc
        .i_dc_seq_regs(w_dc_seq_regs),
        .i_dc_ctrl_regs(w_dc_ctrl_regs),

        .i_dc_seq_uregs(w_uregs[U_DC_SEQ_START:U_DC_SEQ_END]),
        .i_dc_ctrl_uregs(w_uregs[U_DC_CTRL_START:U_DC_CTRL_END]),

        .o_dc_sclk_bus(w_dc_sclk_bus),
        .o_dc_mosi_bus(w_dc_mosi_bus),
        .i_dc_miso_bus(w_dc_miso_bus),
        .o_dc_cs_n_bus(w_dc_cs_n_bus),
        .o_dc_ldac_n_bus(w_dc_ldac_n_bus),

        .o_dc_armed_bus(w_dc_armed_bus),

        .o_dc_empty_bus(w_dc_empty_bus),

        .o_dc_eop_bus(),

        // rf
        .i_rf_seq_regs(w_rf_seq_regs),
        .i_rf_ctrl_regs(w_rf_ctrl_regs),

        .i_rf_seq_uregs(w_uregs[U_RF_SEQ_START:U_RF_SEQ_END]),
        .i_rf_ctrl_uregs(w_uregs[U_RF_CTRL_START:U_RF_CTRL_END]),

        .o_rf_QIx8_bus(w_rf_QIx8_bus),

        .o_rf_armed_bus(w_rf_armed_bus),

        .o_rf_empty_bus(w_rf_empty_bus),

        .o_rf_nco_req_bus(w_rf_nco_req_bus),
        .i_rf_nco_busy_bus(w_rf_nco_tile_busy_bus),
        .o_rf_nco_freq_bus(w_rf_nco_freq_bus),
        .o_rf_nco_phase_bus(w_rf_nco_phase_bus),
        .o_rf_nco_en_bus(w_rf_nco_en_bus),

        .o_rf_eop_bus(),

        // li
        .i_li_seq_regs(w_li_seq_regs),
        .i_li_ctrl_regs(w_li_ctrl_regs),

        .i_li_seq_uregs(w_uregs[U_LI_SEQ_START:U_LI_SEQ_END]),
        .i_li_ctrl_uregs(w_uregs[U_LI_CTRL_START:U_LI_CTRL_END]),

        .i_li_QIx4_bus(w_li_QIx4_bus),

        .o_li_armed_bus(w_li_armed_bus),

        .o_li_empty_bus(w_li_empty_bus),

        .o_li_sample_mask_bus(w_li_sample_mask_bus),

        .o_li_eop_bus(),

        // launch
        .i_lch_regs(w_lch_regs),

        .i_lch_uregs(w_uregs[U_LCH_START:U_LCH_END]),
        
        // button
        .i_btn(i_btn_w)
    );

    /************
    * uart tasks
    *************/

    localparam bit_duration = 1085.069;
    task pc_tsmt(input logic [7:0] data);
        // start bit = 0
        w_rx = 1'b0;
        #bit_duration;

        // data bits
        for (int i = 0; i < 8; i++) begin
            w_rx = data[i];
            #bit_duration;
        end

        // end bit = 1
        w_rx = 1'b1;
        #bit_duration;
    endtask

    logic [7:0] pc_received [$];
    logic [7:0] rx_data;

    task pc_recv;

        // start bit == 0
        @(negedge w_tx);
        #(bit_duration / 2);
        assert (w_tx == 1'b0)
        else $fatal(1, "At %0.3f ns: o_tx didn't hold start bit as 0", $realtime);

        // data bits
        for (int i = 0; i < 8; i++) begin
            #bit_duration;
            rx_data[i] = w_tx;
        end

        // stop bit == 1
        #bit_duration;
        assert (w_tx == 1'b1)
        else $fatal(1, "At %0.3f ns: o_tx didn't hold stop bit as 1", $realtime);

        pc_received.push_back(rx_data);

    endtask

    /*********************************
    * axil regs and dac instantiation
    *********************************/

    // dc axil reg and dac instantiation
    for (genvar i = 0; i < NUM_DC_CHANNEL; i++) begin : DC_IO_GEN

        dc_regs #(
            .NUM_SEQ_REGS(DC_SEQ_REGS),
            .NUM_CTRL_REGS(DC_CTRL_REGS)
        ) REGS (
            .s_axi_aclk(w_dcrfli_clk),
            .s_axi_aresetn(w_dcrfli_rst_n),

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

            .o_seq_regs(w_dc_seq_regs[i]),
            .o_ctrl_regs(w_dc_ctrl_regs[i])
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

    end


    // rf axil regs and dac instantiation
    for (genvar i = 0; i < NUM_RF_CHANNEL; i++) begin : RF_IO_GEN

        rf_regs #(
            .NUM_SEQ_REGS(RF_SEQ_REGS),
            .NUM_CTRL_REGS(RF_CTRL_REGS)
        ) REGS (
            .s_axi_aclk(w_dcrfli_clk),
            .s_axi_aresetn(w_dcrfli_rst_n),

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

            .o_seq_regs(w_rf_seq_regs[i]),
            .o_ctrl_regs(w_rf_ctrl_regs[i])
        );

        zcu216_dac DAC (
            .i_clk(w_dcrfli_clk),
            .i_dac_clk(w_rf_dac_clk),
            .i_QIx8(w_rf_QIx8_bus[i]),
            .o_I(vrf_I[i]),
            .o_Q(vrf_Q[i]),
            .o_vrf(vrf[i]),

            .i_nco_req(w_rf_nco_req_bus[i / 2]),
            .o_nco_busy(w_rf_nco_busy_bus[i]),
            .i_nco_freq(w_rf_nco_freq_bus[i]),
            .i_nco_phase(w_rf_nco_phase_bus[i]),
            .i_nco_en(w_rf_nco_en_bus[i])
        );

    end

    for (genvar i = 0; i < (NUM_RF_CHANNEL + 1) / 2; i++) begin : RF_NCO_TILE_BUSY_GEN
        if (2 * i + 1 < NUM_RF_CHANNEL) begin : PAIR
            assign w_rf_nco_tile_busy_bus[i] = w_rf_nco_busy_bus[2 * i] | 
                                               w_rf_nco_busy_bus[2 * i + 1];
        end
        else begin : SINGLE
            assign w_rf_nco_tile_busy_bus[i] = w_rf_nco_busy_bus[2 * i];
        end
    end

    // li axil regs and adc instantiation
    for (genvar i = 0; i < NUM_LI_CHANNEL; i++) begin : LI_IO_GEN

        li_regs #(
            .NUM_SEQ_REGS(LI_SEQ_REGS),
            .NUM_CTRL_REGS(LI_CTRL_REGS)
        ) REGS (
            .s_axi_aclk(w_dcrfli_clk),
            .s_axi_aresetn(w_dcrfli_rst_n),

            .s_axi_awvalid(w_li_awvalid_bus[i]), 
            .s_axi_awready(w_li_awready_bus[i]),
            .s_axi_awaddr(w_li_awaddr_bus[i]),

            .s_axi_wvalid(w_li_wvalid_bus[i]),
            .s_axi_wready(w_li_wready_bus[i]),
            .s_axi_wdata(w_li_wdata_bus[i]),
            .s_axi_wstrb(w_li_wstrb_bus[i]),

            .s_axi_bvalid(w_li_bvalid_bus[i]),
            .s_axi_bready(w_li_bready_bus[i]),
            .s_axi_bresp(w_li_bresp_bus[i]),

            // leave read ports unconencted
            .s_axi_arvalid(1'b0),
            .s_axi_arready(),
            .s_axi_araddr(($clog2(LI_TOTAL_REGS*4))'('h0)),

            .s_axi_rvalid(),
            .s_axi_rready(1'b1),
            .s_axi_rdata(),
            .s_axi_rresp(),

            .o_seq_regs(w_li_seq_regs[i]),
            .o_ctrl_regs(w_li_ctrl_regs[i])
        );

        zcu216_adc ADC (
            .i_clk(w_dcrfli_clk),
            .i_adc_clk(w_li_adc_clk),
            .i_vli(0.0),
            .o_QIx4(w_li_QIx4_bus[i]), 
            .i_sample_mask(w_li_sample_mask_bus[i]),
            .o_sample_spike(w_li_sample_spike_bus[i])
        );

    end

    // launch axil regs instantiation
    launch_regs #(
        .NUM_REGS(LCH_TOTAL_REGS)
    ) LCH_REGS (
        .s_axi_aclk(w_dcrfli_clk),
        .s_axi_aresetn(w_dcrfli_rst_n),

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

    /*********************************
    * axil write tasks for simulation
    *********************************/

    localparam ADDR_BITS = 12;

    task automatic dc_axil_write(int ch); 

        $display("dc_axil_write channel%0d", ch);

        @(negedge w_dcrfli_clk);

        w_dc_awvalid_bus[ch] = 1'b1;
        w_dc_wvalid_bus[ch] = 1'b1;
        w_dc_bready_bus[ch] = 1'b0;

        $display("pre fork");

        fork 

            begin: AWREADY
                forever begin
                    if (w_dc_awvalid_bus[ch] && w_dc_awready_bus[ch]) begin
                        @(negedge w_dcrfli_clk);
                        w_dc_awvalid_bus[ch] = 1'b0;
                        break;
                    end
                    else @(negedge w_dcrfli_clk);
                end
            end
            
            begin: WREADY
                forever begin
                    if (w_dc_wvalid_bus[ch] && w_dc_wready_bus[ch]) begin
                        @(negedge w_dcrfli_clk);
                        w_dc_wvalid_bus[ch] = 1'b0;
                        break;
                    end
                    else @(negedge w_dcrfli_clk);
                end
            end

        join

        $display("post fork");
        w_dc_bready_bus[ch] = 1'b1;

        forever begin
            if (w_dc_bvalid_bus[ch] && w_dc_bready_bus[ch]) begin
                @(negedge w_dcrfli_clk);
                w_dc_bready_bus[ch] = 1'b0;
                assert (w_dc_bresp_bus[ch] == 2'b00)
                else $fatal(1, "Bad bresp: %0b", w_dc_bresp_bus[ch]);
                break;
            end
            else @(negedge w_dcrfli_clk);
        end

    endtask

    task automatic rf_axil_write(int ch); 

        $display("rf_axil_write channel%0d", ch);

        @(negedge w_dcrfli_clk);

        w_rf_awvalid_bus[ch] = 1'b1;
        w_rf_wvalid_bus[ch] = 1'b1;
        w_rf_bready_bus[ch] = 1'b0;

        $display("pre fork");

        fork 

            begin: AWREADY
                forever begin
                    if (w_rf_awvalid_bus[ch] && w_rf_awready_bus[ch]) begin
                        @(negedge w_dcrfli_clk);
                        w_rf_awvalid_bus[ch] = 1'b0;
                        break;
                    end
                    else @(negedge w_dcrfli_clk);
                end
            end
            
            begin: WREADY
                forever begin
                    if (w_rf_wvalid_bus[ch] && w_rf_wready_bus[ch]) begin
                        @(negedge w_dcrfli_clk);
                        w_rf_wvalid_bus[ch] = 1'b0;
                        break;
                    end
                    else @(negedge w_dcrfli_clk);
                end
            end

        join

        $display("post fork");
        w_rf_bready_bus[ch] = 1'b1;

        forever begin
            if (w_rf_bvalid_bus[ch] && w_rf_bready_bus[ch]) begin
                @(negedge w_dcrfli_clk);
                w_rf_bready_bus[ch] = 1'b0;
                assert (w_rf_bresp_bus[ch] == 2'b00)
                else $fatal(1, "Bad bresp: %0b", w_rf_bresp_bus[ch]);
                break;
            end
            else @(negedge w_dcrfli_clk);
        end

    endtask

    task automatic li_axil_write(int ch); 

        $display("li_axil_write channel%0d", ch);

        @(negedge w_dcrfli_clk);

        w_li_awvalid_bus[ch] = 1'b1;
        w_li_wvalid_bus[ch] = 1'b1;
        w_li_bready_bus[ch] = 1'b0;

        $display("pre fork");

        fork 

            begin: AWREADY
                forever begin
                    if (w_li_awvalid_bus[ch] && w_li_awready_bus[ch]) begin
                        @(negedge w_dcrfli_clk);
                        w_li_awvalid_bus[ch] = 1'b0;
                        break;
                    end
                    else @(negedge w_dcrfli_clk);
                end
            end
            
            begin: WREADY
                forever begin
                    if (w_li_wvalid_bus[ch] && w_li_wready_bus[ch]) begin
                        @(negedge w_dcrfli_clk);
                        w_li_wvalid_bus[ch] = 1'b0;
                        break;
                    end
                    else @(negedge w_dcrfli_clk);
                end
            end

        join

        $display("post fork");
        w_li_bready_bus[ch] = 1'b1;

        forever begin
            if (w_li_bvalid_bus[ch] && w_li_bready_bus[ch]) begin
                @(negedge w_dcrfli_clk);
                w_li_bready_bus[ch] = 1'b0;
                assert (w_li_bresp_bus[ch] == 2'b00)
                else $fatal(1, "Bad bresp: %0b", w_li_bresp_bus[ch]);
                break;
            end
            else @(negedge w_dcrfli_clk);
        end

    endtask

    task automatic lch_axil_write; 

        $display("lch_axil_write");

        @(negedge w_dcrfli_clk);

        w_lch_awvalid = 1'b1;
        w_lch_wvalid = 1'b1;
        w_lch_bready = 1'b0;

        $display("pre fork");

        fork 

            begin: AWREADY
                forever begin
                    if (w_lch_awvalid && w_lch_awready) begin
                        @(negedge w_dcrfli_clk);
                        w_lch_awvalid = 1'b0;
                        break;
                    end
                    else @(negedge w_dcrfli_clk);
                end
            end
            
            begin: WREADY
                forever begin
                    if (w_lch_wvalid && w_lch_wready) begin
                        @(negedge w_dcrfli_clk);
                        w_lch_wvalid = 1'b0;
                        break;
                    end
                    else @(negedge w_dcrfli_clk);
                end
            end

        join

        $display("post fork");
        w_lch_bready = 1'b1;

        forever begin
            if (w_lch_bvalid && w_lch_bready) begin
                @(negedge w_dcrfli_clk);
                w_lch_bready = 1'b0;
                assert (w_lch_bresp == 2'b00)
                else $fatal(1, "Bad bresp: %0b", w_lch_bresp);
                break;
            end
            else @(negedge w_dcrfli_clk);
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
        else if ((NUM_DC_CHANNEL + NUM_RF_CHANNEL) <= i && i < (NUM_DC_CHANNEL + NUM_RF_CHANNEL + NUM_LI_CHANNEL)) begin

            $display("li%0d", i - NUM_DC_CHANNEL - NUM_RF_CHANNEL);

            w_li_awaddr_bus[i - NUM_DC_CHANNEL - NUM_RF_CHANNEL] = addr[$clog2(LI_TOTAL_REGS*4)-1:0];
            w_li_wdata_bus[i - NUM_DC_CHANNEL - NUM_RF_CHANNEL] = data;
            w_li_wstrb_bus[i - NUM_DC_CHANNEL - NUM_RF_CHANNEL] = 4'hf;

            li_axil_write(i - NUM_DC_CHANNEL - NUM_RF_CHANNEL);

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
        w_dcrfli_clk = 1'b0;
        forever #2 w_dcrfli_clk = !w_dcrfli_clk;
    end

    initial begin
        w_rf_dac_clk = 1'b1;
        forever #0.25 w_rf_dac_clk = !w_rf_dac_clk;
    end

    initial begin
        w_li_adc_clk = 1'b1;
        forever #0.25 w_li_adc_clk = !w_li_adc_clk;
    end

    // reset
    initial begin

        w_dc_awvalid_bus = 'h0;
        w_dc_wvalid_bus = 'h0;
        w_dc_bready_bus = 'h0;

        w_rf_awvalid_bus = 'h0;
        w_rf_wvalid_bus = 'h0;
        w_rf_bready_bus = 'h0;

        w_li_awvalid_bus = 'h0;
        w_li_wvalid_bus = 'h0;
        w_li_bready_bus = 'h0;

        w_lch_awvalid = 'h0;
        w_lch_wvalid = 'h0;
        w_lch_bready = 'h0;

        i_btn_w = 1'b0;

        w_dcrfli_rst_n = 1'b0;
        @(negedge w_dcrfli_clk);
        w_dcrfli_rst_n = 1'b1;

    end

    // tracker
    logic [NUM_DC_CHANNEL-1:0] dc_armed;
    logic [NUM_RF_CHANNEL-1:0] rf_armed;
    logic [NUM_LI_CHANNEL-1:0] li_armed;

    int all_empty;

    initial begin

        dc_armed = 'h0;
        rf_armed = 'h0;
        li_armed = 'h0;
        all_empty = 1;

        forever begin

            @(negedge w_dcrfli_clk);

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

            for (int i = 0; i < NUM_LI_CHANNEL; i++) begin

                if (!li_armed[i] && w_li_armed_bus[i])
                    $display("At %0.3f: LI %0d armed", $realtime, i);
                else if (li_armed[i] && !w_li_armed_bus[i])
                    $display("At %0.3f: LI %0d started", $realtime, i);

                li_armed[i] = w_li_armed_bus[i];

            end

            if (DCRFLI.LCH.w_all_ready) begin
                $display("At %0.3f: LAUNCH sees all ready", $realtime);
            end

            if (all_empty && !(w_dc_empty_bus == {(NUM_DC_CHANNEL){1'b1}} && 
                w_rf_empty_bus == {(NUM_RF_CHANNEL){1'b1}} && 
                w_li_empty_bus == {(NUM_LI_CHANNEL){1'b1}})) begin
                $display("At %0.3f: not all empty", $realtime);
                all_empty = 0;
            end
            else if (!all_empty && (w_dc_empty_bus == {(NUM_DC_CHANNEL){1'b1}} && 
                w_rf_empty_bus == {(NUM_RF_CHANNEL){1'b1}} &&
                w_li_empty_bus == {(NUM_LI_CHANNEL){1'b1}})) begin
                $display("At %0.3f: all empty", $realtime);
                all_empty = 1;
            end

        end
    end

    logic [7:0] tx_data;
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
                else if ($sscanf(line, "0x%4h", tx_data) == 1) begin
                    pc_tsmt(tx_data);
                end
                else if ($sscanf(line, "run %d", t) == 1) begin
                    wait(DCRFLI.LCH.r_state == DCRFLI.LCH.LAUNCH);
                    @(negedge w_dcrfli_clk);
                    wait(DCRFLI.LCH.w_dc_ready && 
                         DCRFLI.LCH.w_rf_ready &&
                         DCRFLI.LCH.w_li_ready);
                    @(negedge w_dcrfli_clk);
                    i_btn_w = 1'b1;
                    repeat(30) @(negedge w_dcrfli_clk);
                    i_btn_w = 1'b0;
                    repeat (t/4) @(negedge w_dcrfli_clk);
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

