`default_nettype none
`timescale 1ns / 1ps
`include "include/dc.svh"
`include "include/rf.svh"
`include "include/li.svh"
`include "include/ex.svh"
`include "include/launch.svh"

import "DPI-C" function int cmd_open(input string path);
import "DPI-C" function int cmd_accept_poll(input int timeout_ms);
import "DPI-C" function int cmd_getline(output byte unsigned line_buf[]);
import "DPI-C" function int cmd_sendline(input string s);

module simulator;

    // define number of dc/rf/li channels
    localparam NUM_DC_CHANNEL=24;
    localparam NUM_RF_CHANNEL=6;
    localparam NUM_LI_CHANNEL=2;
    localparam NUM_EX_CHANNEL=2;
    localparam NUM_DEBOUNCE_CYCLES=25;

    /*****************
    * clk/rst signals
    *****************/

    logic w_processor_clk, w_rf_dac_clk, w_li_adc_clk, w_ex_dac_clk, w_processor_rst_n;

    /************
    * dc signals
    ************/

    // dc axi bus
    localparam DC_TOTAL_REGS = DC_SEQ_REGS + DC_CTRL_REGS + DC_STATUS_REGS;

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

    // dc axil read bus
    logic [0:NUM_DC_CHANNEL-1] w_dc_arvalid_bus;
    logic [0:NUM_DC_CHANNEL-1] w_dc_arready_bus;
    logic [0:NUM_DC_CHANNEL-1][$clog2(DC_TOTAL_REGS*4)-1:0] w_dc_araddr_bus;
    logic [0:NUM_DC_CHANNEL-1] w_dc_rvalid_bus;
    logic [0:NUM_DC_CHANNEL-1] w_dc_rready_bus;
    logic [0:NUM_DC_CHANNEL-1][31:0] w_dc_rdata_bus;
    logic [0:NUM_DC_CHANNEL-1][1:0] w_dc_rresp_bus;

    logic [0:NUM_DC_CHANNEL-1][0:DC_SEQ_REGS-1][31:0] w_dc_seq_regs;
    logic [0:NUM_DC_CHANNEL-1][0:DC_CTRL_REGS-1][31:0] w_dc_ctrl_regs;
    logic [0:NUM_DC_CHANNEL-1][0:DC_STATUS_REGS-1][31:0] w_dc_status_regs;

    // dc spi bus
    logic [0:NUM_DC_CHANNEL-1] w_dc_sclk_bus;
    logic [0:NUM_DC_CHANNEL-1] w_dc_mosi_bus;
    logic [0:NUM_DC_CHANNEL-1] w_dc_miso_bus;
    logic [0:NUM_DC_CHANNEL-1] w_dc_cs_n_bus;
    logic [0:NUM_DC_CHANNEL-1] w_dc_ldac_n_bus;

    // dc armed/marker bus
    logic [NUM_DC_CHANNEL-1:0] w_dc_armed_bus;
    logic [NUM_DC_CHANNEL-1:0] w_dc_marker_bus;

    // dc empty bus
    logic [0:NUM_DC_CHANNEL-1] w_dc_empty_bus;

    // dc eop bus
    dc_eop_t [0:NUM_DC_CHANNEL-1] w_dc_eop_bus;

    // dc voltage output
    logic [DC_DAC_WIDTH-1:0] vdc_digital [NUM_DC_CHANNEL];
    real vdc [NUM_DC_CHANNEL];

    /************
    * rf signals
    ************/

    // rf axi bus
    localparam RF_TOTAL_REGS = RF_SEQ_REGS + RF_CTRL_REGS + RF_STATUS_REGS;

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

    // rf axil read bus
    logic [0:NUM_RF_CHANNEL-1] w_rf_arvalid_bus;
    logic [0:NUM_RF_CHANNEL-1] w_rf_arready_bus;
    logic [0:NUM_RF_CHANNEL-1][$clog2(RF_TOTAL_REGS*4)-1:0] w_rf_araddr_bus;
    logic [0:NUM_RF_CHANNEL-1] w_rf_rvalid_bus;
    logic [0:NUM_RF_CHANNEL-1] w_rf_rready_bus;
    logic [0:NUM_RF_CHANNEL-1][31:0] w_rf_rdata_bus;
    logic [0:NUM_RF_CHANNEL-1][1:0] w_rf_rresp_bus;

    logic [0:NUM_RF_CHANNEL-1][0:RF_SEQ_REGS-1][31:0] w_rf_seq_regs;
    logic [0:NUM_RF_CHANNEL-1][0:RF_CTRL_REGS-1][31:0] w_rf_ctrl_regs;
    logic [0:NUM_RF_CHANNEL-1][0:RF_STATUS_REGS-1][31:0] w_rf_status_regs;

    // rf QIx8 bus
    logic [0:NUM_RF_CHANNEL-1][RF_DAC_WIDTH*16-1:0] w_rf_QIx8_bus;

    // rf armed/marker bus
    logic [NUM_RF_CHANNEL-1:0] w_rf_armed_bus;
    logic [NUM_RF_CHANNEL-1:0] w_rf_marker_bus;

    // rf empty bus
    logic [0:NUM_RF_CHANNEL-1] w_rf_empty_bus;

    // rf eop bus
    logic [0:NUM_RF_CHANNEL-1] w_rf_eop_bus;

    // rf voltage output
    logic [RF_IQ_WIDTH-1:0] vrf_Q [NUM_RF_CHANNEL];
    logic [RF_IQ_WIDTH-1:0] vrf_I [NUM_RF_CHANNEL];
    real vrf [NUM_RF_CHANNEL];

    /************
    * li signals
    ************/

    // li axi bus
    localparam LI_TOTAL_REGS = LI_SEQ_REGS + LI_CTRL_REGS + LI_STATUS_REGS;

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

    // li axil read bus
    logic [0:NUM_LI_CHANNEL-1] w_li_arvalid_bus;
    logic [0:NUM_LI_CHANNEL-1] w_li_arready_bus;
    logic [0:NUM_LI_CHANNEL-1][$clog2(LI_TOTAL_REGS*4)-1:0] w_li_araddr_bus;
    logic [0:NUM_LI_CHANNEL-1] w_li_rvalid_bus;
    logic [0:NUM_LI_CHANNEL-1] w_li_rready_bus;
    logic [0:NUM_LI_CHANNEL-1][31:0] w_li_rdata_bus;
    logic [0:NUM_LI_CHANNEL-1][1:0] w_li_rresp_bus;

    logic [0:NUM_LI_CHANNEL-1][0:LI_SEQ_REGS-1][31:0] w_li_seq_regs;
    logic [0:NUM_LI_CHANNEL-1][0:LI_CTRL_REGS-1][31:0] w_li_ctrl_regs;
    logic [0:NUM_LI_CHANNEL-1][0:LI_STATUS_REGS-1][31:0] w_li_status_regs;

    // li QIx4 bus
    logic [0:NUM_LI_CHANNEL-1][LI_ADC_WIDTH*8-1:0] w_li_QIx4_bus;

    // li armed/marker bus
    logic [NUM_LI_CHANNEL-1:0] w_li_armed_bus;
    logic [NUM_LI_CHANNEL-1:0] w_li_marker_bus;

    // li empty bus
    logic [0:NUM_LI_CHANNEL-1] w_li_empty_bus;

    // li samples lost bus
    logic [0:NUM_LI_CHANNEL-1][31:0] w_li_samples_lost_bus;

    // li samples inbuf bus
    logic [0:NUM_LI_CHANNEL-1][LI_AXIBUF_ADDR_WIDTH-1:0] w_li_samples_inbuf_bus;

    // li sample mask/spike bus
    logic [0:NUM_LI_CHANNEL-1][3:0] w_li_sample_mask_bus;
    logic [0:NUM_LI_CHANNEL-1] w_li_sample_spike_bus;

    // li axi write
    logic [0:NUM_LI_CHANNEL-1][LI_ADC_WIDTH*8-1:0] w_li_QIx4_save_bus;
    logic [0:NUM_LI_CHANNEL-1][LI_SAMPLE_TAG_WIDTH*4-1:0] w_li_tagx4_bus;
    logic [0:NUM_LI_CHANNEL-1][3:0] w_li_validx4_bus;
    logic [0:NUM_LI_CHANNEL-1] w_li_last_bus;
    li_ctrl_t [0:NUM_LI_CHANNEL-1] w_li_ctrl_bus;

    // ddr axi4 buses (from li_save masters to ddr slave)
    localparam logic [48:0] DDR_BASE  = 49'h800000000;
    localparam int          DDR_WORDS = 8192;

    logic [0:NUM_LI_CHANNEL-1]        w_ddr_awvalid_bus;
    logic [0:NUM_LI_CHANNEL-1]        w_ddr_awready_bus;
    logic [0:NUM_LI_CHANNEL-1][48:0]  w_ddr_awaddr_bus;
    logic [0:NUM_LI_CHANNEL-1][7:0]   w_ddr_awlen_bus;
    logic [0:NUM_LI_CHANNEL-1][5:0]   w_ddr_awid_bus;
    logic [0:NUM_LI_CHANNEL-1]        w_ddr_wvalid_bus;
    logic [0:NUM_LI_CHANNEL-1]        w_ddr_wready_bus;
    logic [0:NUM_LI_CHANNEL-1][127:0] w_ddr_wdata_bus;
    logic [0:NUM_LI_CHANNEL-1]        w_ddr_wlast_bus;
    logic [0:NUM_LI_CHANNEL-1]        w_ddr_bvalid_bus;
    logic [0:NUM_LI_CHANNEL-1]        w_ddr_bready_bus;
    logic [0:NUM_LI_CHANNEL-1][5:0]   w_ddr_bid_bus;
    logic [0:NUM_LI_CHANNEL-1][1:0]   w_ddr_bresp_bus;

    /************
    * ex signals
    ************/

    // ex axi bus
    localparam EX_TOTAL_REGS = EX_SEQ_REGS + EX_STATUS_REGS;

    logic [0:NUM_EX_CHANNEL-1] w_ex_awvalid_bus;
    logic [0:NUM_EX_CHANNEL-1] w_ex_awready_bus;
    logic [0:NUM_EX_CHANNEL-1][$clog2(EX_TOTAL_REGS*4)-1:0] w_ex_awaddr_bus;

    logic [0:NUM_EX_CHANNEL-1] w_ex_wvalid_bus;
    logic [0:NUM_EX_CHANNEL-1] w_ex_wready_bus;
    logic [0:NUM_EX_CHANNEL-1][31:0] w_ex_wdata_bus;
    logic [0:NUM_EX_CHANNEL-1][3:0] w_ex_wstrb_bus;

    logic [0:NUM_EX_CHANNEL-1] w_ex_bvalid_bus;
    logic [0:NUM_EX_CHANNEL-1] w_ex_bready_bus;
    logic [0:NUM_EX_CHANNEL-1][1:0] w_ex_bresp_bus;

    // ex axil read bus
    logic [0:NUM_EX_CHANNEL-1] w_ex_arvalid_bus;
    logic [0:NUM_EX_CHANNEL-1] w_ex_arready_bus;
    logic [0:NUM_EX_CHANNEL-1][$clog2(EX_TOTAL_REGS*4)-1:0] w_ex_araddr_bus;
    logic [0:NUM_EX_CHANNEL-1] w_ex_rvalid_bus;
    logic [0:NUM_EX_CHANNEL-1] w_ex_rready_bus;
    logic [0:NUM_EX_CHANNEL-1][31:0] w_ex_rdata_bus;
    logic [0:NUM_EX_CHANNEL-1][1:0] w_ex_rresp_bus;

    logic [0:NUM_EX_CHANNEL-1][0:EX_SEQ_REGS-1][31:0] w_ex_seq_regs;
    logic [0:NUM_EX_CHANNEL-1][0:EX_STATUS_REGS-1][31:0] w_ex_status_regs;

    logic [0:NUM_EX_CHANNEL-1][EX_DAC_WIDTH*16-1:0] w_ex_realx16_bus;

    logic [NUM_EX_CHANNEL-1:0] w_ex_armed_bus;
    logic [NUM_EX_CHANNEL-1:0] w_ex_marker_bus;

    // ex empty bus
    logic [0:NUM_EX_CHANNEL-1] w_ex_empty_bus;

    // ex eop bus
    ex_eop_t [0:NUM_EX_CHANNEL-1] w_ex_eop_bus;

    // ex voltage output
    logic [0:NUM_EX_CHANNEL-1][EX_REAL_WIDTH-1:0] vex;

    /****************
    * launch signals
    ****************/

    // launch axi bus
    localparam LCH_TOTAL_REGS = LCH_CTRL_REGS + LCH_STATUS_REGS;

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

    // launch axil read
    logic w_lch_arvalid;
    logic w_lch_arready;
    logic [$clog2(LCH_TOTAL_REGS*4)-1:0] w_lch_araddr;
    logic w_lch_rvalid;
    logic w_lch_rready;
    logic [31:0] w_lch_rdata;
    logic [1:0] w_lch_rresp;

    logic [0:LCH_CTRL_REGS-1][31:0] w_lch_ctrl_regs;
    logic [0:LCH_STATUS_REGS-1][31:0] w_lch_status_regs;

    logic w_trigger;

    /********************************
    * top-level module instantiation
    ********************************/

    processor #(
        .NUM_DC_CHANNEL(NUM_DC_CHANNEL),
        .NUM_RF_CHANNEL(NUM_RF_CHANNEL),
        .NUM_LI_CHANNEL(NUM_LI_CHANNEL),
        .NUM_EX_CHANNEL(NUM_EX_CHANNEL),
        .NUM_DEBOUNCE_CYCLES(NUM_DEBOUNCE_CYCLES)
    ) PROCESSOR (
        .i_clk(w_processor_clk),
        .i_rst(!w_processor_rst_n),

        // dc
        .i_dc_seq_regs(w_dc_seq_regs),
        .i_dc_ctrl_regs(w_dc_ctrl_regs),
        .o_dc_status_regs(w_dc_status_regs),

        .o_dc_sclk_bus(w_dc_sclk_bus),
        .o_dc_mosi_bus(w_dc_mosi_bus),
        .i_dc_miso_bus(w_dc_miso_bus),
        .o_dc_cs_n_bus(w_dc_cs_n_bus),
        .o_dc_ldac_n_bus(w_dc_ldac_n_bus),

        .o_dc_armed_bus(w_dc_armed_bus),
        .o_dc_marker_bus(w_dc_marker_bus),

        .o_dc_empty_bus(w_dc_empty_bus),

        .o_dc_eop_bus(),

        // rf
        .i_rf_seq_regs(w_rf_seq_regs),
        .i_rf_ctrl_regs(w_rf_ctrl_regs),
        .o_rf_status_regs(w_rf_status_regs),

        .o_rf_QIx8_bus(w_rf_QIx8_bus),

        .o_rf_armed_bus(w_rf_armed_bus),
        .o_rf_marker_bus(w_rf_marker_bus),

        .o_rf_empty_bus(w_rf_empty_bus),

        .o_rf_eop_bus(),

        // li
        .i_li_seq_regs(w_li_seq_regs),
        .i_li_ctrl_regs(w_li_ctrl_regs),
        .o_li_status_regs(w_li_status_regs),

        .i_li_QIx4_bus(w_li_QIx4_bus),

        .o_li_armed_bus(w_li_armed_bus),
        .o_li_marker_bus(w_li_marker_bus),

        .o_li_empty_bus(w_li_empty_bus),

        .o_li_sample_mask_bus(w_li_sample_mask_bus),

        .o_li_QIx4_bus(w_li_QIx4_save_bus),
        .o_li_tagx4_bus(w_li_tagx4_bus),
        .o_li_validx4_bus(w_li_validx4_bus),
        .o_li_last_bus(w_li_last_bus),

        .o_li_ctrl_bus(w_li_ctrl_bus),

        .o_li_eop_bus(),

        .i_li_samples_lost_bus(w_li_samples_lost_bus),
        .i_li_samples_inbuf_bus(w_li_samples_inbuf_bus),

        // ex
        .i_ex_seq_regs(w_ex_seq_regs),
        .o_ex_status_regs(w_ex_status_regs),

        .o_ex_realx16_bus(w_ex_realx16_bus),

        .o_ex_armed_bus(w_ex_armed_bus),
        .o_ex_marker_bus(w_ex_marker_bus),

        .o_ex_empty_bus(w_ex_empty_bus),

        .o_ex_eop_bus(),

        // launch
        .i_lch_ctrl_regs(w_lch_ctrl_regs),
        .o_lch_status_regs(w_lch_status_regs)
    );

    /*********************************
    * axil regs and dac instantiation
    *********************************/

    // dc axil reg and dac instantiation
    for (genvar i = 0; i < NUM_DC_CHANNEL; i++) begin : DC_IO_GEN

        dc_regs #(
            .NUM_SEQ_REGS(DC_SEQ_REGS),
            .NUM_CTRL_REGS(DC_CTRL_REGS),
            .NUM_STATUS_REGS(DC_STATUS_REGS),
            .ADDR_BASE(32'hA0000000 + i * 32'h1000)
        ) REGS (
            .s_axi_aclk(w_processor_clk),
            .s_axi_aresetn(w_processor_rst_n),

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

            .s_axi_arvalid(w_dc_arvalid_bus[i]),
            .s_axi_arready(w_dc_arready_bus[i]),
            .s_axi_araddr(w_dc_araddr_bus[i]),

            .s_axi_rvalid(w_dc_rvalid_bus[i]),
            .s_axi_rready(w_dc_rready_bus[i]),
            .s_axi_rdata(w_dc_rdata_bus[i]),
            .s_axi_rresp(w_dc_rresp_bus[i]),

            .o_seq_regs(w_dc_seq_regs[i]),
            .o_ctrl_regs(w_dc_ctrl_regs[i]),
            .i_status_regs(w_dc_status_regs[i])
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
            .NUM_CTRL_REGS(RF_CTRL_REGS),
            .NUM_STATUS_REGS(RF_STATUS_REGS),
            .ADDR_BASE(32'hA0000000 + (NUM_DC_CHANNEL + i) * 32'h1000)
        ) REGS (
            .s_axi_aclk(w_processor_clk),
            .s_axi_aresetn(w_processor_rst_n),

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

            .s_axi_arvalid(w_rf_arvalid_bus[i]),
            .s_axi_arready(w_rf_arready_bus[i]),
            .s_axi_araddr(w_rf_araddr_bus[i]),

            .s_axi_rvalid(w_rf_rvalid_bus[i]),
            .s_axi_rready(w_rf_rready_bus[i]),
            .s_axi_rdata(w_rf_rdata_bus[i]),
            .s_axi_rresp(w_rf_rresp_bus[i]),

            .o_seq_regs(w_rf_seq_regs[i]),
            .o_ctrl_regs(w_rf_ctrl_regs[i]),
            .i_status_regs(w_rf_status_regs[i])
        );

        zcu216_dac DAC (
            .i_clk(w_processor_clk),
            .i_dac_clk(w_rf_dac_clk),
            .i_QIx8(w_rf_QIx8_bus[i]),
            .o_I(vrf_I[i]),
            .o_Q(vrf_Q[i]),
            .o_vrf(vrf[i]),

            .i_nco_req(1'b0),
            .o_nco_busy(),
            .i_nco_freq(48'h0),
            .i_nco_phase(18'h0),
            .i_nco_en(6'h0)
        );

    end

    // li axil regs, adc, and li_save instantiation
    for (genvar i = 0; i < NUM_LI_CHANNEL; i++) begin : LI_IO_GEN

        li_regs #(
            .NUM_SEQ_REGS(LI_SEQ_REGS),
            .NUM_CTRL_REGS(LI_CTRL_REGS),
            .NUM_STATUS_REGS(LI_STATUS_REGS),
            .ADDR_BASE(32'hA0000000 + (NUM_DC_CHANNEL + NUM_RF_CHANNEL + i) * 32'h1000)
        ) REGS (
            .s_axi_aclk(w_processor_clk),
            .s_axi_aresetn(w_processor_rst_n),

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

            .s_axi_arvalid(w_li_arvalid_bus[i]),
            .s_axi_arready(w_li_arready_bus[i]),
            .s_axi_araddr(w_li_araddr_bus[i]),

            .s_axi_rvalid(w_li_rvalid_bus[i]),
            .s_axi_rready(w_li_rready_bus[i]),
            .s_axi_rdata(w_li_rdata_bus[i]),
            .s_axi_rresp(w_li_rresp_bus[i]),

            .o_seq_regs(w_li_seq_regs[i]),
            .o_ctrl_regs(w_li_ctrl_regs[i]),
            .i_status_regs(w_li_status_regs[i])
        );

        zcu216_adc ADC (
            .i_clk(w_processor_clk),
            .i_adc_clk(w_li_adc_clk),
            .i_vli(0.0),
            .o_QIx4(w_li_QIx4_bus[i]),
            .i_sample_mask(w_li_sample_mask_bus[i]),
            .o_sample_spike(w_li_sample_spike_bus[i])
        );

        li_save #(
            .ADC_WIDTH(LI_ADC_WIDTH),
            .FIFO_ADDR_WIDTH(LI_AXIBUF_ADDR_WIDTH)
        ) SAVE (
            .i_clk(w_processor_clk),
            .i_rst(!w_processor_rst_n),

            .i_validx4(w_li_validx4_bus[i]),
            .i_last(w_li_last_bus[i]),
            .i_QIx4(w_li_QIx4_save_bus[i]),
            .i_tagx4(w_li_tagx4_bus[i]),
            .i_ctrl(w_li_ctrl_bus[i]),

            .o_samples_lost(w_li_samples_lost_bus[i]),
            .o_samples_inbuf(w_li_samples_inbuf_bus[i]),

            // AW — to ddr slave
            .o_awvalid(w_ddr_awvalid_bus[i]),
            .i_awready(w_ddr_awready_bus[i]),
            .o_awid(w_ddr_awid_bus[i]),
            .o_awaddr(w_ddr_awaddr_bus[i]),
            .o_awburst(),
            .o_awsize(),
            .o_awlen(w_ddr_awlen_bus[i]),
            .o_awcache(),
            .o_awprot(),
            .o_awqos(),
            .o_awlock(),
            .o_awuser(),

            // W — to ddr slave
            .o_wvalid(w_ddr_wvalid_bus[i]),
            .i_wready(w_ddr_wready_bus[i]),
            .o_wdata(w_ddr_wdata_bus[i]),
            .o_wstrb(),
            .o_wlast(w_ddr_wlast_bus[i]),

            // B — from ddr slave
            .i_bvalid(w_ddr_bvalid_bus[i]),
            .o_bready(w_ddr_bready_bus[i]),
            .i_bid(w_ddr_bid_bus[i]),
            .i_bresp(w_ddr_bresp_bus[i]),

            // AR/R — li_save drives arvalid=0; no ddr slave needed for reads
            .o_arvalid(),
            .i_arready(1'b0),
            .o_arid(),
            .o_araddr(),
            .o_arburst(),
            .o_arsize(),
            .o_arlen(),
            .o_arcache(),
            .o_arprot(),
            .o_arqos(),
            .o_arlock(),
            .o_aruser(),
            .i_rvalid(1'b0),
            .o_rready(),
            .i_rid(6'h0),
            .i_rdata(128'h0),
            .i_rresp(2'b00),
            .i_rlast(1'b0)
        );

    end

    // ex axil regs and dac instantiation
    for (genvar i = 0; i < NUM_EX_CHANNEL; i++) begin : EX_IO_GEN

        ex_regs #(
            .NUM_SEQ_REGS(EX_SEQ_REGS),
            .NUM_STATUS_REGS(EX_STATUS_REGS),
            .ADDR_BASE(32'hA0000000 + (NUM_DC_CHANNEL + NUM_RF_CHANNEL + NUM_LI_CHANNEL + i) * 32'h1000)
        ) REGS (
            .s_axi_aclk(w_processor_clk),
            .s_axi_aresetn(w_processor_rst_n),

            .s_axi_awvalid(w_ex_awvalid_bus[i]),
            .s_axi_awready(w_ex_awready_bus[i]),
            .s_axi_awaddr(w_ex_awaddr_bus[i]),

            .s_axi_wvalid(w_ex_wvalid_bus[i]),
            .s_axi_wready(w_ex_wready_bus[i]),
            .s_axi_wdata(w_ex_wdata_bus[i]),
            .s_axi_wstrb(w_ex_wstrb_bus[i]),

            .s_axi_bvalid(w_ex_bvalid_bus[i]),
            .s_axi_bready(w_ex_bready_bus[i]),
            .s_axi_bresp(w_ex_bresp_bus[i]),

            .s_axi_arvalid(w_ex_arvalid_bus[i]),
            .s_axi_arready(w_ex_arready_bus[i]),
            .s_axi_araddr(w_ex_araddr_bus[i]),

            .s_axi_rvalid(w_ex_rvalid_bus[i]),
            .s_axi_rready(w_ex_rready_bus[i]),
            .s_axi_rdata(w_ex_rdata_bus[i]),
            .s_axi_rresp(w_ex_rresp_bus[i]),

            .o_seq_regs(w_ex_seq_regs[i]),
            .i_status_regs(w_ex_status_regs[i])
        );

        zcu216_real_dac DAC (
            .i_clk(w_processor_clk),
            .i_dac_clk(w_ex_dac_clk),
            .i_realx16(w_ex_realx16_bus[i]),
            .o_vex(vex[i])
        );

    end

    // launch axil regs instantiation
    launch_regs #(
        .NUM_CTRL_REGS(LCH_CTRL_REGS),
        .NUM_STATUS_REGS(LCH_STATUS_REGS),
        .ADDR_BASE(32'hA0000000 + (NUM_DC_CHANNEL + NUM_RF_CHANNEL + NUM_LI_CHANNEL + NUM_EX_CHANNEL) * 32'h1000)
    ) LCH_REGS (
        .s_axi_aclk(w_processor_clk),
        .s_axi_aresetn(w_processor_rst_n),

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

        .s_axi_arvalid(w_lch_arvalid),
        .s_axi_arready(w_lch_arready),
        .s_axi_araddr(w_lch_araddr),

        .s_axi_rvalid(w_lch_rvalid),
        .s_axi_rready(w_lch_rready),
        .s_axi_rdata(w_lch_rdata),
        .s_axi_rresp(w_lch_rresp),

        .o_ctrl_regs(w_lch_ctrl_regs),
        .i_status_regs(w_lch_status_regs)
    );

    /***********************************
    * ddr slave state machine
    * single-outstanding AXI4 slave for
    * li_save masters; ch0 has priority
    ***********************************/

    logic [31:0] ddr_mem [0:DDR_WORDS-1];

    typedef enum logic [1:0] {DDR_IDLE, DDR_W, DDR_B} ddr_state_t;
    ddr_state_t ddr_state;

    logic        ddr_ch;        // which channel is being served
    logic [48:0] ddr_awaddr;    // saved AW address
    logic [5:0]  ddr_awid;      // saved AW id (echoed in B)
    logic [13:0] ddr_word_ptr;  // 32-bit word index into ddr_mem for current beat

    initial begin
        for (int k = 0; k < DDR_WORDS; k++) ddr_mem[k] = 32'h0;
        ddr_state    = DDR_IDLE;
        ddr_ch       = 1'b0;
        ddr_awaddr   = '0;
        ddr_awid     = '0;
        ddr_word_ptr = '0;
    end

    always @(posedge w_processor_clk) begin

        // default: deassert all slave outputs each cycle
        w_ddr_awready_bus <= '0;
        w_ddr_wready_bus  <= '0;
        w_ddr_bvalid_bus  <= '0;
        w_ddr_bid_bus     <= '0;
        w_ddr_bresp_bus   <= '0;

        case (ddr_state)

            DDR_IDLE: begin
                // ch0 priority arbitration
                if (w_ddr_awvalid_bus[0]) begin
                    ddr_ch           <= 1'b0;
                    ddr_awaddr       <= w_ddr_awaddr_bus[0];
                    ddr_awid         <= w_ddr_awid_bus[0];
                    ddr_word_ptr     <= 14'((w_ddr_awaddr_bus[0] - DDR_BASE) >> 2);
                    w_ddr_awready_bus[0] <= 1'b1;
                    ddr_state        <= DDR_W;
                end
                else if (w_ddr_awvalid_bus[1]) begin
                    ddr_ch           <= 1'b1;
                    ddr_awaddr       <= w_ddr_awaddr_bus[1];
                    ddr_awid         <= w_ddr_awid_bus[1];
                    ddr_word_ptr     <= 14'((w_ddr_awaddr_bus[1] - DDR_BASE) >> 2);
                    w_ddr_awready_bus[1] <= 1'b1;
                    ddr_state        <= DDR_W;
                end
            end

            DDR_W: begin
                w_ddr_wready_bus[ddr_ch] <= 1'b1;
                // handshake: wvalid && wready (wready was set previous cycle)
                if (w_ddr_wvalid_bus[ddr_ch] && w_ddr_wready_bus[ddr_ch]) begin
                    if (ddr_word_ptr + 14'd3 >= DDR_WORDS)
                        $fatal(1, "DDR overflow: word_ptr=%0d", ddr_word_ptr);
                    // pack 128-bit beat as 4 x {Q,I} pairs
                    ddr_mem[ddr_word_ptr + 0] <= w_ddr_wdata_bus[ddr_ch][31:0];
                    ddr_mem[ddr_word_ptr + 1] <= w_ddr_wdata_bus[ddr_ch][63:32];
                    ddr_mem[ddr_word_ptr + 2] <= w_ddr_wdata_bus[ddr_ch][95:64];
                    ddr_mem[ddr_word_ptr + 3] <= w_ddr_wdata_bus[ddr_ch][127:96];
                    if (w_ddr_wlast_bus[ddr_ch]) begin
                        ddr_state <= DDR_B;
                    end
                    else begin
                        ddr_word_ptr <= ddr_word_ptr + 14'd4;
                    end
                end
            end

            DDR_B: begin
                w_ddr_bvalid_bus[ddr_ch] <= 1'b1;
                w_ddr_bid_bus[ddr_ch]    <= ddr_awid;
                w_ddr_bresp_bus[ddr_ch]  <= 2'b00;
                // handshake: bvalid && bready (bvalid was set previous cycle)
                if (w_ddr_bvalid_bus[ddr_ch] && w_ddr_bready_bus[ddr_ch]) begin
                    ddr_state <= DDR_IDLE;
                end
            end

        endcase
    end

    /*********************************
    * axil write tasks for simulation
    *********************************/

    localparam ADDR_BITS = 12;

    task automatic dc_axil_write(int ch);

        $display("dc_axil_write channel%0d", ch);

        @(negedge w_processor_clk);

        w_dc_awvalid_bus[ch] = 1'b1;
        w_dc_wvalid_bus[ch] = 1'b1;
        w_dc_bready_bus[ch] = 1'b0;

        $display("pre fork");

        fork

            begin: AWREADY
                forever begin
                    if (w_dc_awvalid_bus[ch] && w_dc_awready_bus[ch]) begin
                        @(negedge w_processor_clk);
                        w_dc_awvalid_bus[ch] = 1'b0;
                        break;
                    end
                    else @(negedge w_processor_clk);
                end
            end

            begin: WREADY
                forever begin
                    if (w_dc_wvalid_bus[ch] && w_dc_wready_bus[ch]) begin
                        @(negedge w_processor_clk);
                        w_dc_wvalid_bus[ch] = 1'b0;
                        break;
                    end
                    else @(negedge w_processor_clk);
                end
            end

        join

        $display("post fork");
        w_dc_bready_bus[ch] = 1'b1;

        forever begin
            if (w_dc_bvalid_bus[ch] && w_dc_bready_bus[ch]) begin
                @(negedge w_processor_clk);
                w_dc_bready_bus[ch] = 1'b0;
                assert (w_dc_bresp_bus[ch] == 2'b00)
                else $fatal(1, "Bad bresp: %0b", w_dc_bresp_bus[ch]);
                break;
            end
            else @(negedge w_processor_clk);
        end

    endtask

    task automatic rf_axil_write(int ch);

        $display("rf_axil_write channel%0d", ch);

        @(negedge w_processor_clk);

        w_rf_awvalid_bus[ch] = 1'b1;
        w_rf_wvalid_bus[ch] = 1'b1;
        w_rf_bready_bus[ch] = 1'b0;

        $display("pre fork");

        fork

            begin: AWREADY
                forever begin
                    if (w_rf_awvalid_bus[ch] && w_rf_awready_bus[ch]) begin
                        @(negedge w_processor_clk);
                        w_rf_awvalid_bus[ch] = 1'b0;
                        break;
                    end
                    else @(negedge w_processor_clk);
                end
            end

            begin: WREADY
                forever begin
                    if (w_rf_wvalid_bus[ch] && w_rf_wready_bus[ch]) begin
                        @(negedge w_processor_clk);
                        w_rf_wvalid_bus[ch] = 1'b0;
                        break;
                    end
                    else @(negedge w_processor_clk);
                end
            end

        join

        $display("post fork");
        w_rf_bready_bus[ch] = 1'b1;

        forever begin
            if (w_rf_bvalid_bus[ch] && w_rf_bready_bus[ch]) begin
                @(negedge w_processor_clk);
                w_rf_bready_bus[ch] = 1'b0;
                assert (w_rf_bresp_bus[ch] == 2'b00)
                else $fatal(1, "Bad bresp: %0b", w_rf_bresp_bus[ch]);
                break;
            end
            else @(negedge w_processor_clk);
        end

    endtask

    task automatic li_axil_write(int ch);

        $display("li_axil_write channel%0d", ch);

        @(negedge w_processor_clk);

        w_li_awvalid_bus[ch] = 1'b1;
        w_li_wvalid_bus[ch] = 1'b1;
        w_li_bready_bus[ch] = 1'b0;

        $display("pre fork");

        fork

            begin: AWREADY
                forever begin
                    if (w_li_awvalid_bus[ch] && w_li_awready_bus[ch]) begin
                        @(negedge w_processor_clk);
                        w_li_awvalid_bus[ch] = 1'b0;
                        break;
                    end
                    else @(negedge w_processor_clk);
                end
            end

            begin: WREADY
                forever begin
                    if (w_li_wvalid_bus[ch] && w_li_wready_bus[ch]) begin
                        @(negedge w_processor_clk);
                        w_li_wvalid_bus[ch] = 1'b0;
                        break;
                    end
                    else @(negedge w_processor_clk);
                end
            end

        join

        $display("post fork");
        w_li_bready_bus[ch] = 1'b1;

        forever begin
            if (w_li_bvalid_bus[ch] && w_li_bready_bus[ch]) begin
                @(negedge w_processor_clk);
                w_li_bready_bus[ch] = 1'b0;
                assert (w_li_bresp_bus[ch] == 2'b00)
                else $fatal(1, "Bad bresp: %0b", w_li_bresp_bus[ch]);
                break;
            end
            else @(negedge w_processor_clk);
        end

    endtask

    task automatic ex_axil_write(int ch);

        $display("ex_axil_write channel%0d", ch);

        @(negedge w_processor_clk);

        w_ex_awvalid_bus[ch] = 1'b1;
        w_ex_wvalid_bus[ch] = 1'b1;
        w_ex_bready_bus[ch] = 1'b0;

        $display("pre fork");

        fork

            begin: AWREADY
                forever begin
                    if (w_ex_awvalid_bus[ch] && w_ex_awready_bus[ch]) begin
                        @(negedge w_processor_clk);
                        w_ex_awvalid_bus[ch] = 1'b0;
                        break;
                    end
                    else @(negedge w_processor_clk);
                end
            end

            begin: WREADY
                forever begin
                    if (w_ex_wvalid_bus[ch] && w_ex_wready_bus[ch]) begin
                        @(negedge w_processor_clk);
                        w_ex_wvalid_bus[ch] = 1'b0;
                        break;
                    end
                    else @(negedge w_processor_clk);
                end
            end

        join

        $display("post fork");
        w_ex_bready_bus[ch] = 1'b1;

        forever begin
            if (w_ex_bvalid_bus[ch] && w_ex_bready_bus[ch]) begin
                @(negedge w_processor_clk);
                w_ex_bready_bus[ch] = 1'b0;
                assert (w_ex_bresp_bus[ch] == 2'b00)
                else $fatal(1, "Bad bresp: %0b", w_ex_bresp_bus[ch]);
                break;
            end
            else @(negedge w_processor_clk);
        end

    endtask

    task automatic lch_axil_write;

        $display("lch_axil_write");

        @(negedge w_processor_clk);

        w_lch_awvalid = 1'b1;
        w_lch_wvalid = 1'b1;
        w_lch_bready = 1'b0;

        $display("pre fork");

        fork

            begin: AWREADY
                forever begin
                    if (w_lch_awvalid && w_lch_awready) begin
                        @(negedge w_processor_clk);
                        w_lch_awvalid = 1'b0;
                        break;
                    end
                    else @(negedge w_processor_clk);
                end
            end

            begin: WREADY
                forever begin
                    if (w_lch_wvalid && w_lch_wready) begin
                        @(negedge w_processor_clk);
                        w_lch_wvalid = 1'b0;
                        break;
                    end
                    else @(negedge w_processor_clk);
                end
            end

        join

        $display("post fork");
        w_lch_bready = 1'b1;

        forever begin
            if (w_lch_bvalid && w_lch_bready) begin
                @(negedge w_processor_clk);
                w_lch_bready = 1'b0;
                assert (w_lch_bresp == 2'b00)
                else $fatal(1, "Bad bresp: %0b", w_lch_bresp);
                break;
            end
            else @(negedge w_processor_clk);
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

            $display("dc%0d axil write finished\n", i);

        end
        else if (NUM_DC_CHANNEL <= i && i < (NUM_DC_CHANNEL + NUM_RF_CHANNEL)) begin

            $display("rf%0d", i - NUM_DC_CHANNEL);

            w_rf_awaddr_bus[i - NUM_DC_CHANNEL] = addr[$clog2(RF_TOTAL_REGS*4)-1:0];
            w_rf_wdata_bus[i - NUM_DC_CHANNEL] = data;
            w_rf_wstrb_bus[i - NUM_DC_CHANNEL] = 4'hf;

            rf_axil_write(i - NUM_DC_CHANNEL);

            $display("rf%0d axil write finished\n", i - NUM_DC_CHANNEL);

        end
        else if ((NUM_DC_CHANNEL + NUM_RF_CHANNEL) <= i && i < (NUM_DC_CHANNEL + NUM_RF_CHANNEL + NUM_LI_CHANNEL)) begin

            $display("li%0d", i - NUM_DC_CHANNEL - NUM_RF_CHANNEL);

            w_li_awaddr_bus[i - NUM_DC_CHANNEL - NUM_RF_CHANNEL] = addr[$clog2(LI_TOTAL_REGS*4)-1:0];
            w_li_wdata_bus[i - NUM_DC_CHANNEL - NUM_RF_CHANNEL] = data;
            w_li_wstrb_bus[i - NUM_DC_CHANNEL - NUM_RF_CHANNEL] = 4'hf;

            li_axil_write(i - NUM_DC_CHANNEL - NUM_RF_CHANNEL);

            $display("li%0d axil write finished\n", i - NUM_DC_CHANNEL - NUM_RF_CHANNEL);

        end
        else if ((NUM_DC_CHANNEL + NUM_RF_CHANNEL + NUM_LI_CHANNEL) <= i &&
            i < (NUM_DC_CHANNEL + NUM_RF_CHANNEL + NUM_LI_CHANNEL + NUM_EX_CHANNEL)) begin

            $display("ex%0d", i - NUM_LI_CHANNEL - NUM_DC_CHANNEL - NUM_RF_CHANNEL);

            w_ex_awaddr_bus[i - NUM_LI_CHANNEL - NUM_DC_CHANNEL - NUM_RF_CHANNEL] = addr[$clog2(EX_TOTAL_REGS*4)-1:0];
            w_ex_wdata_bus[i - NUM_LI_CHANNEL - NUM_DC_CHANNEL - NUM_RF_CHANNEL] = data;
            w_ex_wstrb_bus[i - NUM_LI_CHANNEL - NUM_DC_CHANNEL - NUM_RF_CHANNEL] = 4'hf;

            ex_axil_write(i - NUM_LI_CHANNEL - NUM_DC_CHANNEL - NUM_RF_CHANNEL);

            $display("ex%0d axil write finished\n", i - NUM_LI_CHANNEL - NUM_DC_CHANNEL - NUM_RF_CHANNEL);

        end
        else begin

            $display("launch");

            w_lch_awaddr = addr[$clog2(LCH_TOTAL_REGS*4)-1:0];
            w_lch_wdata = data;
            w_lch_wstrb = 4'hf;

            lch_axil_write;

            $display("launch axil write finished\n");

        end

    endtask

    /*********************************
    * axil read tasks for simulation
    *********************************/

    task automatic dc_axil_read(int ch, output logic [31:0] rdata);

        $display("dc_axil_read channel%0d", ch);

        @(negedge w_processor_clk);

        w_dc_arvalid_bus[ch] = 1'b1;
        w_dc_rready_bus[ch]  = 1'b0;

        forever begin
            if (w_dc_arvalid_bus[ch] && w_dc_arready_bus[ch]) begin
                @(negedge w_processor_clk);
                w_dc_arvalid_bus[ch] = 1'b0;
                break;
            end
            else @(negedge w_processor_clk);
        end

        w_dc_rready_bus[ch] = 1'b1;

        forever begin
            if (w_dc_rvalid_bus[ch] && w_dc_rready_bus[ch]) begin
                rdata = w_dc_rdata_bus[ch];
                assert (w_dc_rresp_bus[ch] == 2'b00)
                    else $fatal(1, "Bad rresp dc%0d: %0b", ch, w_dc_rresp_bus[ch]);
                @(negedge w_processor_clk);
                w_dc_rready_bus[ch] = 1'b0;
                break;
            end
            else @(negedge w_processor_clk);
        end

    endtask

    task automatic rf_axil_read(int ch, output logic [31:0] rdata);

        $display("rf_axil_read channel%0d", ch);

        @(negedge w_processor_clk);

        w_rf_arvalid_bus[ch] = 1'b1;
        w_rf_rready_bus[ch]  = 1'b0;

        forever begin
            if (w_rf_arvalid_bus[ch] && w_rf_arready_bus[ch]) begin
                @(negedge w_processor_clk);
                w_rf_arvalid_bus[ch] = 1'b0;
                break;
            end
            else @(negedge w_processor_clk);
        end

        w_rf_rready_bus[ch] = 1'b1;

        forever begin
            if (w_rf_rvalid_bus[ch] && w_rf_rready_bus[ch]) begin
                rdata = w_rf_rdata_bus[ch];
                assert (w_rf_rresp_bus[ch] == 2'b00)
                    else $fatal(1, "Bad rresp rf%0d: %0b", ch, w_rf_rresp_bus[ch]);
                @(negedge w_processor_clk);
                w_rf_rready_bus[ch] = 1'b0;
                break;
            end
            else @(negedge w_processor_clk);
        end

    endtask

    task automatic li_axil_read(int ch, output logic [31:0] rdata);

        $display("li_axil_read channel%0d", ch);

        @(negedge w_processor_clk);

        w_li_arvalid_bus[ch] = 1'b1;
        w_li_rready_bus[ch]  = 1'b0;

        forever begin
            if (w_li_arvalid_bus[ch] && w_li_arready_bus[ch]) begin
                @(negedge w_processor_clk);
                w_li_arvalid_bus[ch] = 1'b0;
                break;
            end
            else @(negedge w_processor_clk);
        end

        w_li_rready_bus[ch] = 1'b1;

        forever begin
            if (w_li_rvalid_bus[ch] && w_li_rready_bus[ch]) begin
                rdata = w_li_rdata_bus[ch];
                assert (w_li_rresp_bus[ch] == 2'b00)
                    else $fatal(1, "Bad rresp li%0d: %0b", ch, w_li_rresp_bus[ch]);
                @(negedge w_processor_clk);
                w_li_rready_bus[ch] = 1'b0;
                break;
            end
            else @(negedge w_processor_clk);
        end

    endtask

    task automatic ex_axil_read(int ch, output logic [31:0] rdata);

        $display("ex_axil_read channel%0d", ch);

        @(negedge w_processor_clk);

        w_ex_arvalid_bus[ch] = 1'b1;
        w_ex_rready_bus[ch]  = 1'b0;

        forever begin
            if (w_ex_arvalid_bus[ch] && w_ex_arready_bus[ch]) begin
                @(negedge w_processor_clk);
                w_ex_arvalid_bus[ch] = 1'b0;
                break;
            end
            else @(negedge w_processor_clk);
        end

        w_ex_rready_bus[ch] = 1'b1;

        forever begin
            if (w_ex_rvalid_bus[ch] && w_ex_rready_bus[ch]) begin
                rdata = w_ex_rdata_bus[ch];
                assert (w_ex_rresp_bus[ch] == 2'b00)
                    else $fatal(1, "Bad rresp ex%0d: %0b", ch, w_ex_rresp_bus[ch]);
                @(negedge w_processor_clk);
                w_ex_rready_bus[ch] = 1'b0;
                break;
            end
            else @(negedge w_processor_clk);
        end

    endtask

    task automatic lch_axil_read(output logic [31:0] rdata);

        $display("lch_axil_read");

        @(negedge w_processor_clk);

        w_lch_arvalid = 1'b1;
        w_lch_rready  = 1'b0;

        forever begin
            if (w_lch_arvalid && w_lch_arready) begin
                @(negedge w_processor_clk);
                w_lch_arvalid = 1'b0;
                break;
            end
            else @(negedge w_processor_clk);
        end

        w_lch_rready = 1'b1;

        forever begin
            if (w_lch_rvalid && w_lch_rready) begin
                rdata = w_lch_rdata;
                assert (w_lch_rresp == 2'b00)
                    else $fatal(1, "Bad rresp lch: %0b", w_lch_rresp);
                @(negedge w_processor_clk);
                w_lch_rready = 1'b0;
                break;
            end
            else @(negedge w_processor_clk);
        end

    endtask

    task automatic axil_bus_read(input logic [48:0] addr, output logic [31:0] rdata);

        int i = addr[31:ADDR_BITS];

        if (0 <= i && i < NUM_DC_CHANNEL) begin

            w_dc_araddr_bus[i] = addr[$clog2(DC_TOTAL_REGS*4)-1:0];
            dc_axil_read(i, rdata);
            $display("dc%0d axil read = 0x%08h\n", i, rdata);

        end
        else if (NUM_DC_CHANNEL <= i && i < (NUM_DC_CHANNEL + NUM_RF_CHANNEL)) begin

            w_rf_araddr_bus[i - NUM_DC_CHANNEL] = addr[$clog2(RF_TOTAL_REGS*4)-1:0];
            rf_axil_read(i - NUM_DC_CHANNEL, rdata);
            $display("rf%0d axil read = 0x%08h\n", i - NUM_DC_CHANNEL, rdata);

        end
        else if ((NUM_DC_CHANNEL + NUM_RF_CHANNEL) <= i &&
                 i < (NUM_DC_CHANNEL + NUM_RF_CHANNEL + NUM_LI_CHANNEL)) begin

            w_li_araddr_bus[i - NUM_DC_CHANNEL - NUM_RF_CHANNEL] = addr[$clog2(LI_TOTAL_REGS*4)-1:0];
            li_axil_read(i - NUM_DC_CHANNEL - NUM_RF_CHANNEL, rdata);
            $display("li%0d axil read = 0x%08h\n", i - NUM_DC_CHANNEL - NUM_RF_CHANNEL, rdata);

        end
        else if ((NUM_DC_CHANNEL + NUM_RF_CHANNEL + NUM_LI_CHANNEL) <= i &&
                 i < (NUM_DC_CHANNEL + NUM_RF_CHANNEL + NUM_LI_CHANNEL + NUM_EX_CHANNEL)) begin

            w_ex_araddr_bus[i - NUM_DC_CHANNEL - NUM_RF_CHANNEL - NUM_LI_CHANNEL] = addr[$clog2(EX_TOTAL_REGS*4)-1:0];
            ex_axil_read(i - NUM_DC_CHANNEL - NUM_RF_CHANNEL - NUM_LI_CHANNEL, rdata);
            $display("ex%0d axil read = 0x%08h\n",
                i - NUM_DC_CHANNEL - NUM_RF_CHANNEL - NUM_LI_CHANNEL, rdata);

        end
        else begin

            w_lch_araddr = addr[$clog2(LCH_TOTAL_REGS*4)-1:0];
            lch_axil_read(rdata);
            $display("lch axil read = 0x%08h\n", rdata);

        end

    endtask

    // clocks
    initial begin
        w_processor_clk = 1'b0;
        forever #2 w_processor_clk = !w_processor_clk;
    end

    initial begin
        w_rf_dac_clk = 1'b1;
        forever #0.25 w_rf_dac_clk = !w_rf_dac_clk;
    end

    initial begin
        w_li_adc_clk = 1'b1;
        forever #0.5 w_li_adc_clk = !w_li_adc_clk;
    end

    initial begin
        w_ex_dac_clk = 1'b1;
        forever #0.125 w_ex_dac_clk = !w_ex_dac_clk;
    end

    // reset
    initial begin

        w_dc_awvalid_bus = 'h0;
        w_dc_wvalid_bus  = 'h0;
        w_dc_bready_bus  = 'h0;
        w_dc_arvalid_bus = 'h0;
        w_dc_rready_bus  = 'h0;

        w_rf_awvalid_bus = 'h0;
        w_rf_wvalid_bus  = 'h0;
        w_rf_bready_bus  = 'h0;
        w_rf_arvalid_bus = 'h0;
        w_rf_rready_bus  = 'h0;

        w_li_awvalid_bus = 'h0;
        w_li_wvalid_bus  = 'h0;
        w_li_bready_bus  = 'h0;
        w_li_arvalid_bus = 'h0;
        w_li_rready_bus  = 'h0;

        w_ex_awvalid_bus = 'h0;
        w_ex_wvalid_bus  = 'h0;
        w_ex_bready_bus  = 'h0;
        w_ex_arvalid_bus = 'h0;
        w_ex_rready_bus  = 'h0;

        w_lch_awvalid = 'h0;
        w_lch_wvalid  = 'h0;
        w_lch_bready  = 'h0;
        w_lch_arvalid = 'h0;
        w_lch_rready  = 'h0;

        w_processor_rst_n = 1'b0;
        @(negedge w_processor_clk);
        w_processor_rst_n = 1'b1;

    end

    // tracker
    logic [NUM_DC_CHANNEL-1:0] dc_armed;
    logic [NUM_RF_CHANNEL-1:0] rf_armed;
    logic [NUM_LI_CHANNEL-1:0] li_armed;
    logic [NUM_EX_CHANNEL-1:0] ex_armed;

    int all_empty;

    initial begin

        dc_armed = 'h0;
        rf_armed = 'h0;
        li_armed = 'h0;
        ex_armed = 'h0;
        all_empty = 1;


        forever begin

            @(negedge w_processor_clk);

            for (int i = 0; i < NUM_DC_CHANNEL; i++) begin

                if (!dc_armed[i] && w_dc_armed_bus[i])
                    $display("At %0.3f: DC %0d armed", $realtime, i);
                else if (dc_armed[i] && !w_dc_armed_bus[i])
                    $display("At %0.3f: DC %0d started", $realtime, i);

                dc_armed[i] = w_dc_armed_bus[i];

                if (w_dc_marker_bus[i])
                    $display("At %0.3f: DC %0d marker", $realtime, i);

            end

            for (int i = 0; i < NUM_RF_CHANNEL; i++) begin

                if (!rf_armed[i] && w_rf_armed_bus[i])
                    $display("At %0.3f: RF %0d armed", $realtime, i);
                else if (rf_armed[i] && !w_rf_armed_bus[i])
                    $display("At %0.3f: RF %0d started", $realtime, i);

                rf_armed[i] = w_rf_armed_bus[i];

                if (w_rf_marker_bus[i])
                    $display("At %0.3f: RF %0d marker", $realtime, i);

            end

            for (int i = 0; i < NUM_LI_CHANNEL; i++) begin

                if (!li_armed[i] && w_li_armed_bus[i])
                    $display("At %0.3f: LI %0d armed", $realtime, i);
                else if (li_armed[i] && !w_li_armed_bus[i])
                    $display("At %0.3f: LI %0d started", $realtime, i);

                li_armed[i] = w_li_armed_bus[i];

                if (w_li_marker_bus[i])
                    $display("At %0.3f: LI %0d marker", $realtime, i);

            end

            for (int i = 0; i < NUM_EX_CHANNEL; i++) begin

                if (!ex_armed[i] && w_ex_armed_bus[i])
                    $display("At %0.3f: EX %0d armed", $realtime, i);
                else if (ex_armed[i] && !w_ex_armed_bus[i])
                    $display("At %0.3f: EX %0d started", $realtime, i);

                ex_armed[i] = w_ex_armed_bus[i];

                if (w_ex_marker_bus[i])
                    $display("At %0.3f: EX %0d marker", $realtime, i);

            end

            if (PROCESSOR.LCH.w_all_ready) begin
                $display("At %0.3f: LAUNCH sees all ready", $realtime);
            end

            if (all_empty && !(w_dc_empty_bus == {(NUM_DC_CHANNEL){1'b1}} &&
                w_rf_empty_bus == {(NUM_RF_CHANNEL){1'b1}} &&
                w_li_empty_bus == {(NUM_LI_CHANNEL){1'b1}} &&
                w_ex_empty_bus == {(NUM_EX_CHANNEL){1'b1}})) begin
                $display("At %0.3f: not all empty", $realtime);
                all_empty = 0;
            end
            else if (!all_empty && (w_dc_empty_bus == {(NUM_DC_CHANNEL){1'b1}} &&
                w_rf_empty_bus == {(NUM_RF_CHANNEL){1'b1}} &&
                w_li_empty_bus == {(NUM_LI_CHANNEL){1'b1}} &&
                w_ex_empty_bus == {(NUM_EX_CHANNEL){1'b1}})) begin
                $display("At %0.3f: all empty", $realtime);
                all_empty = 1;
            end

        end
    end

    // module-scope variables for command loop
    logic [31:0] addr, data;
    logic [48:0] read_addr;    // ddr: 49-bit address for "read" command
    logic [31:0] rdata_out;    // ddr: captured read data
    logic [13:0] ddr_read_widx; // ddr: word index into ddr_mem for "read" command
    int unsigned t;
    int rc;
    localparam LINE_MAX = 512;
    byte unsigned line_buf[LINE_MAX];
    string line;

    function automatic string bytes2string(input byte unsigned b[]);
        string s = "";
        for (int i = 0; i < b.size(); i++) begin
            if (b[i] == 0) break;
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
                else if ($sscanf(line, "read 0x%h", read_addr) == 1) begin
                    if (read_addr >= DDR_BASE) begin
                        // direct ddr memory lookup — no axi transaction
                        ddr_read_widx = (read_addr - DDR_BASE) >> 2;
                        if (ddr_read_widx >= DDR_WORDS)
                            $fatal(1, "DDR read overflow: addr=0x%h", read_addr);
                        rdata_out = ddr_mem[ddr_read_widx];
                        $display("DDR read addr=0x%h → 0x%08h", read_addr, rdata_out);
                    end
                    else begin
                        // axil read from pl register space
                        axil_bus_read(read_addr, rdata_out);
                    end
                    rc = cmd_sendline($sformatf("0x%08h\n", rdata_out));
                    if (rc < 0) $fatal(1, "cmd_sendline failed");
                end
                else if ($sscanf(line, "launch %d", t) == 1) begin
                    // Launch fires automatically when all armed channels are ready
                    // (i_trigger is tied to 1 in processor). Wait until LAUNCH state
                    // is reached, then run t additional nanoseconds.
                    wait(PROCESSOR.LCH.r_state == PROCESSOR.LCH.LAUNCH);
                    repeat (t/4) @(negedge w_processor_clk);
                end
                else if ($sscanf(line, "run %d", t) == 1) begin
                    repeat (t/4) @(negedge w_processor_clk);
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
