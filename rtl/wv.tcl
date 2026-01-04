set nw [wvCreateWindow]
wvOpenFile -win $nw {/home/shizeche/hardware/swashispin/rtl/run.fsdb}
wvRenameGroup -win $nw {G1} {dc}
wvAddGroup -win $nw {rf}
wvAddGroup -win $nw {launch}
wvAddGroup -win $nw {v}

wvSetPosition -win $nw {("v" 0)}
wvAddSignal -win $nw "simulator/vdc\[0:23\]" \
                          "simulator/vdc_digital\[0:23\]\[19:0\]" \
                          "simulator/vrf\[0:5\]" \
                          "simulator/vrf_I\[0:5\]\[13:0\]" \
                          "simulator/vrf_Q\[0:5\]\[13:0\]"

wvCollapseGroup -win $nw "v"

wvSelectGroup -win $nw "launch"
wvAddSubGroup -win $nw "LCH"
wvAddSubGroup -win $nw "AXIL_REGS"

wvSelectGroup -win $nw "launch/AXIL_REGS"
wvAddSubGroup -win $nw "r"
wvAddSubGroup -win $nw "ar"
wvAddSubGroup -win $nw "b"
wvAddSubGroup -win $nw "w"
wvAddSubGroup -win $nw "aw"

wvSetPosition -win $nw {("launch/AXIL_REGS" 0)}
wvAddSignal -win $nw "/simulator/LCH_REGS/AXIL_REGS/i_aclk" \
                          "/simulator/LCH_REGS/AXIL_REGS/i_aresetn" \
                          "/simulator/LCH_REGS/AXIL_REGS/r_regs\[0:3\]\[31:0\]" \
                          "/simulator/LCH_REGS/AXIL_REGS/o_regs\[0:3\]\[31:0\]"

wvSetPosition -win $nw {("launch/AXIL_REGS/aw" 0)}
wvAddSignal -win $nw "/simulator/LCH_REGS/AXIL_REGS/o_awready" \
                          "/simulator/LCH_REGS/AXIL_REGS/i_awvalid" \
                          "/simulator/LCH_REGS/AXIL_REGS/i_awaddr\[3:0\]" \
                          "/simulator/LCH_REGS/AXIL_REGS/w_awireg\[1:0\]" \
                          "/simulator/LCH_REGS/AXIL_REGS/w_awls2b\[1:0\]"

wvSetPosition -win $nw {("launch/AXIL_REGS/w" 0)}
wvAddSignal -win $nw "/simulator/LCH_REGS/AXIL_REGS/o_wready" \
                          "/simulator/LCH_REGS/AXIL_REGS/i_wvalid" \
                          "/simulator/LCH_REGS/AXIL_REGS/i_wdata\[31:0\]" \
                          "/simulator/LCH_REGS/AXIL_REGS/i_wstrb\[3:0\]" \
                          "/simulator/LCH_REGS/AXIL_REGS/w_wdatastrb\[31:0\]"

wvSetPosition -win $nw {("launch/AXIL_REGS/b" 0)}
wvAddSignal -win $nw "/simulator/LCH_REGS/AXIL_REGS/i_bready" \
                          "/simulator/LCH_REGS/AXIL_REGS/o_bvalid" \
                          "/simulator/LCH_REGS/AXIL_REGS/o_bresp\[1:0\]"

wvSetPosition -win $nw {("launch/AXIL_REGS/ar" 0)}
wvAddSignal -win $nw "/simulator/LCH_REGS/AXIL_REGS/o_arready" \
                          "/simulator/LCH_REGS/AXIL_REGS/i_arvalid" \
                          "/simulator/LCH_REGS/AXIL_REGS/i_araddr\[3:0\]" \
                          "/simulator/LCH_REGS/AXIL_REGS/w_arireg\[1:0\]" \
                          "/simulator/LCH_REGS/AXIL_REGS/w_arls2b\[1:0\]"

wvSetPosition -win $nw {("launch/AXIL_REGS/r" 0)}
wvAddSignal -win $nw "/simulator/LCH_REGS/AXIL_REGS/i_rready" \
                          "/simulator/LCH_REGS/AXIL_REGS/o_rvalid" \
                          "/simulator/LCH_REGS/AXIL_REGS/o_rdata\[31:0\]" \
                          "/simulator/LCH_REGS/AXIL_REGS/o_rresp\[1:0\]"

wvSelectGroup -win $nw "launch/LCH"
wvAddSubGroup -win $nw "start"
wvAddSubGroup -win $nw "armed"
wvAddSubGroup -win $nw "new"

wvSetPosition -win $nw {("launch/LCH" 0)}
wvAddSignal -win $nw "/simulator/LCH/i_clk" \
                          "/simulator/LCH/i_rst" \
                          "/simulator/LCH/r_state" \
                          "/simulator/LCH/w_next_state" \
                          "/simulator/LCH/r_dc_active_mask\[23:0\]" \
                          "/simulator/LCH/r_rf_active_mask\[5:0\]" \
                          "/simulator/LCH/r_li_active_mask\[0:0\]"

wvSetPosition -win $nw {("launch/LCH/new" 0)}
wvAddSignal -win $nw "/simulator/LCH/i_regs\[0:3\]\[31:0\]" \
                          "/simulator/LCH/w_last0" \
                          "/simulator/LCH/w_last0_ff1" \
                          "/simulator/LCH/w_last0_ff2" \
                          "/simulator/LCH/w_new_stream"

wvSetPosition -win $nw {("launch/LCH/armed" 0)}
wvAddSignal -win $nw "/simulator/LCH/i_dc_armed\[23:0\]" \
                          "/simulator/LCH/i_rf_armed\[5:0\]" \
                          "/simulator/LCH/i_li_armed\[0:0\]" \
                          "/simulator/LCH/r_dc_armed\[23:0\]" \
                          "/simulator/LCH/r_rf_armed\[5:0\]" \
                          "/simulator/LCH/r_li_armed\[0:0\]" \
                          "/simulator/LCH/w_dc_ready" \
                          "/simulator/LCH/w_rf_ready" \
                          "/simulator/LCH/w_li_ready" \
                          "/simulator/LCH/w_all_ready"

wvSetPosition -win $nw {("launch/LCH/start" 0)}
wvAddSignal -win $nw "/simulator/LCH/o_dc_start\[23:0\]" \
                          "/simulator/LCH/o_rf_start\[5:0\]" \
                          "/simulator/LCH/o_li_start\[0:0\]"

wvCollapseGroup -win $nw "launch/AXIL_REGS/aw"
wvCollapseGroup -win $nw "launch/AXIL_REGS/w"
wvCollapseGroup -win $nw "launch/AXIL_REGS/b"
wvCollapseGroup -win $nw "launch/AXIL_REGS/ar"
wvCollapseGroup -win $nw "launch/AXIL_REGS/r"
wvCollapseGroup -win $nw "launch/AXIL_REGS"

wvCollapseGroup -win $nw "launch/LCH/new"
wvCollapseGroup -win $nw "launch/LCH/armed"
wvCollapseGroup -win $nw "launch/LCH/start"
wvCollapseGroup -win $nw "launch/LCH"
wvCollapseGroup -win $nw "launch"

for {set ch 23} {$ch >= 0} {incr ch -1} {

    wvSelectGroup -win $nw {dc}
    wvAddSubGroup -win $nw "ch$ch"

    wvSelectGroup -win $nw "dc/ch$ch"
    wvAddSubGroup -win $nw "DAC"
    wvAddSubGroup -win $nw "CORE"
    wvAddSubGroup -win $nw "SEQ"
    wvAddSubGroup -win $nw "AXIL_REGS"

    wvSelectGroup -win $nw "dc/ch$ch/AXIL_REGS"
    wvAddSubGroup -win $nw "r"
    wvAddSubGroup -win $nw "ar"
    wvAddSubGroup -win $nw "b"
    wvAddSubGroup -win $nw "w"
    wvAddSubGroup -win $nw "aw"

    wvSetPosition -win $nw [format {("dc/ch%d/AXIL_REGS" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DC_GEN\[$ch\]/REGS/AXIL_REGS/i_aclk" \
                              "/simulator/DC_GEN\[$ch\]/REGS/AXIL_REGS/i_aresetn" \
                              "/simulator/DC_GEN\[$ch\]/REGS/AXIL_REGS/r_regs\[0:31\]\[31:0\]" \
                              "/simulator/DC_GEN\[$ch\]/REGS/AXIL_REGS/o_regs\[0:31\]\[31:0\]"

    wvSetPosition -win $nw [format {("dc/ch%d/AXIL_REGS/aw" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DC_GEN\[$ch\]/REGS/AXIL_REGS/o_awready" \
                              "/simulator/DC_GEN\[$ch\]/REGS/AXIL_REGS/i_awvalid" \
                              "/simulator/DC_GEN\[$ch\]/REGS/AXIL_REGS/i_awaddr\[6:0\]" \
                              "/simulator/DC_GEN\[$ch\]/REGS/AXIL_REGS/w_awireg\[4:0\]" \
                              "/simulator/DC_GEN\[$ch\]/REGS/AXIL_REGS/w_awls2b\[1:0\]"

    wvSetPosition -win $nw [format {("dc/ch%d/AXIL_REGS/w" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DC_GEN\[$ch\]/REGS/AXIL_REGS/o_wready" \
                              "/simulator/DC_GEN\[$ch\]/REGS/AXIL_REGS/i_wvalid" \
                              "/simulator/DC_GEN\[$ch\]/REGS/AXIL_REGS/i_wdata\[31:0\]" \
                              "/simulator/DC_GEN\[$ch\]/REGS/AXIL_REGS/i_wstrb\[3:0\]" \
                              "/simulator/DC_GEN\[$ch\]/REGS/AXIL_REGS/w_wdatastrb\[31:0\]"

    wvSetPosition -win $nw [format {("dc/ch%d/AXIL_REGS/b" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DC_GEN\[$ch\]/REGS/AXIL_REGS/i_bready" \
                              "/simulator/DC_GEN\[$ch\]/REGS/AXIL_REGS/o_bvalid" \
                              "/simulator/DC_GEN\[$ch\]/REGS/AXIL_REGS/o_bresp\[1:0\]"

    wvSetPosition -win $nw [format {("dc/ch%d/AXIL_REGS/ar" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DC_GEN\[$ch\]/REGS/AXIL_REGS/o_arready" \
                              "/simulator/DC_GEN\[$ch\]/REGS/AXIL_REGS/i_arvalid" \
                              "/simulator/DC_GEN\[$ch\]/REGS/AXIL_REGS/i_araddr\[6:0\]" \
                              "/simulator/DC_GEN\[$ch\]/REGS/AXIL_REGS/w_arireg\[4:0\]" \
                              "/simulator/DC_GEN\[$ch\]/REGS/AXIL_REGS/w_arls2b\[1:0\]"

    wvSetPosition -win $nw [format {("dc/ch%d/AXIL_REGS/r" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DC_GEN\[$ch\]/REGS/AXIL_REGS/i_rready" \
                              "/simulator/DC_GEN\[$ch\]/REGS/AXIL_REGS/o_rvalid" \
                              "/simulator/DC_GEN\[$ch\]/REGS/AXIL_REGS/o_rdata\[31:0\]" \
                              "/simulator/DC_GEN\[$ch\]/REGS/AXIL_REGS/o_rresp\[1:0\]"

    wvSelectGroup -win $nw "dc/ch$ch/SEQ"
    wvAddSubGroup -win $nw "out"
    wvAddSubGroup -win $nw "fetch"
    wvAddSubGroup -win $nw "new"

    wvSetPosition -win $nw [format {("dc/ch%d/SEQ" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DC_GEN\[$ch\]/DC/SEQ/i_clk" \
                              "/simulator/DC_GEN\[$ch\]/DC/SEQ/i_rst" \
                              "/simulator/DC_GEN\[$ch\]/DC/SEQ/w_propagate"

    wvSetPosition -win $nw [format {("dc/ch%d/SEQ/new" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DC_GEN\[$ch\]/DC/SEQ/i_regs\[0:31\]\[31:0\]" \
                              "/simulator/DC_GEN\[$ch\]/DC/SEQ/w_last0" \
                              "/simulator/DC_GEN\[$ch\]/DC/SEQ/w_last0_ff1" \
                              "/simulator/DC_GEN\[$ch\]/DC/SEQ/w_last0_ff2" \
                              "/simulator/DC_GEN\[$ch\]/DC/SEQ/w_new_sequence"

    wvSetPosition -win $nw [format {("dc/ch%d/SEQ/fetch" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DC_GEN\[$ch\]/DC/SEQ/r_sequence\[0:9\]\[91:0\]" \
                              "/simulator/DC_GEN\[$ch\]/DC/SEQ/r_iters\[10:0\]" \
                              "/simulator/DC_GEN\[$ch\]/DC/SEQ/r_iptr\[3:0\]" \
                              "/simulator/DC_GEN\[$ch\]/DC/SEQ/w_insn_fetch\[91:0\]" \
                              "/simulator/DC_GEN\[$ch\]/DC/SEQ/w_insn_bubble" \
                              "/simulator/DC_GEN\[$ch\]/DC/SEQ/w_iptr_plus1\[3:0\]" \
                              "/simulator/DC_GEN\[$ch\]/DC/SEQ/w_next_null"

    wvSetPosition -win $nw [format {("dc/ch%d/SEQ/out" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DC_GEN\[$ch\]/DC/SEQ/o_empty" \
                              "/simulator/DC_GEN\[$ch\]/DC/SEQ/i_next" \
                              "/simulator/DC_GEN\[$ch\]/DC/SEQ/o_addr\[3:0\]" \
                              "/simulator/DC_GEN\[$ch\]/DC/SEQ/o_insn\[91:0\]" \
                              "/simulator/DC_GEN\[$ch\]/DC/SEQ/r_iptr_modify\[3:0\]" \
                              "/simulator/DC_GEN\[$ch\]/DC/SEQ/i_insn_modified\[91:0\]"

    wvSelectGroup -win $nw "dc/ch$ch/CORE"
    wvAddSubGroup -win $nw "hold"
    wvAddSubGroup -win $nw "spi"
    wvAddSubGroup -win $nw "iterate"
    wvAddSubGroup -win $nw "decode"

    wvSetPosition -win $nw [format {("dc/ch%d/CORE" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DC_GEN\[$ch\]/DC/CORE/i_clk" \
                              "/simulator/DC_GEN\[$ch\]/DC/CORE/i_rst" \
                              "/simulator/DC_GEN\[$ch\]/DC/CORE/w_stall"

    wvSetPosition -win $nw [format {("dc/ch%d/CORE/decode" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DC_GEN\[$ch\]/DC/CORE/d" \
                              "/simulator/DC_GEN\[$ch\]/DC/CORE/i_empty" \
                              "/simulator/DC_GEN\[$ch\]/DC/CORE/o_next" \
                              "/simulator/DC_GEN\[$ch\]/DC/CORE/i_addr\[3:0\]" \
                              "/simulator/DC_GEN\[$ch\]/DC/CORE/i_insn\[91:0\]" \
                              "/simulator/DC_GEN\[$ch\]/DC/CORE/o_insn_modified"

    wvSetPosition -win $nw [format {("dc/ch%d/CORE/iterate" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DC_GEN\[$ch\]/DC/CORE/i"

    wvSetPosition -win $nw [format {("dc/ch%d/CORE/spi" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DC_GEN\[$ch\]/DC/CORE/s" \
                              "/simulator/DC_GEN\[$ch\]/DC/CORE/w_dvsr\[15:0\]" \
                              "/simulator/DC_GEN\[$ch\]/DC/CORE/w_spi_dout\[23:0\]" \
                              "/simulator/DC_GEN\[$ch\]/DC/CORE/w_spi_done" \
                              "/simulator/DC_GEN\[$ch\]/DC/CORE/o_armed" \
                              "/simulator/DC_GEN\[$ch\]/DC/CORE/i_start"
    wvSelectGroup -win $nw "dc/ch$ch/CORE/spi"
    wvAddSubGroup -win $nw "wires"
    wvSetPosition -win $nw [format {("dc/ch%d/CORE/spi/wires" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DC_GEN\[$ch\]/DC/CORE/o_sclk" \
                              "/simulator/DC_GEN\[$ch\]/DC/CORE/o_mosi" \
                              "/simulator/DC_GEN\[$ch\]/DC/CORE/i_miso" \
                              "/simulator/DC_GEN\[$ch\]/DC/CORE/o_cs_n" \
                              "/simulator/DC_GEN\[$ch\]/DC/CORE/o_ldac_n"

    wvSetPosition -win $nw [format {("dc/ch%d/CORE/hold" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DC_GEN\[$ch\]/DC/CORE/h" \
                              "/simulator/DC_GEN\[$ch\]/DC/CORE/o_next" \
                              "/simulator/DC_GEN\[$ch\]/DC/CORE/o_addr\[3:0\]" \
                              "/simulator/DC_GEN\[$ch\]/DC/CORE/o_iter\[9:0\]" \
                              "/simulator/DC_GEN\[$ch\]/DC/CORE/o_spi_din\[23:0\]" \
                              "/simulator/DC_GEN\[$ch\]/DC/CORE/o_spi_rd" \
                              "/simulator/DC_GEN\[$ch\]/DC/CORE/o_spi_dout\[23:0\]" \
                              "/simulator/DC_GEN\[$ch\]/DC/CORE/o_cycles_left\[29:0\]"

    wvSelectGroup -win $nw "dc/ch$ch/DAC"
    wvAddSubGroup -win $nw "v"
    wvAddSubGroup -win $nw "regs"
    wvAddSubGroup -win $nw "pins"

    wvSetPosition -win $nw [format {("dc/ch%d/DAC" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DC_GEN\[$ch\]/DAC/valid_transaction" \
                              "/simulator/DC_GEN\[$ch\]/DAC/input_shift_reg\[23:0\]" \
                              "/simulator/DC_GEN\[$ch\]/DAC/rw" \
                              "/simulator/DC_GEN\[$ch\]/DAC/addr\[2:0\]" \
                              "/simulator/DC_GEN\[$ch\]/DAC/data\[19:0\]" \
                              "/simulator/DC_GEN\[$ch\]/DAC/rd_data\[23:0\]"

    wvSetPosition -win $nw [format {("dc/ch%d/DAC/pins" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DC_GEN\[$ch\]/DAC/SCLK" \
                              "/simulator/DC_GEN\[$ch\]/DAC/SDIN" \
                              "/simulator/DC_GEN\[$ch\]/DAC/SYNC_N" \
                              "/simulator/DC_GEN\[$ch\]/DAC/SDO" \
                              "/simulator/DC_GEN\[$ch\]/DAC/LDAC_N" \
                              "/simulator/DC_GEN\[$ch\]/DAC/CLR_N" \
                              "/simulator/DC_GEN\[$ch\]/DAC/RESET_N"

    wvSetPosition -win $nw [format {("dc/ch%d/DAC/regs" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DC_GEN\[$ch\]/DAC/dac_reg\[19:0\]" \
                              "/simulator/DC_GEN\[$ch\]/DAC/ctrl_reg\[19:0\]" \
                              "/simulator/DC_GEN\[$ch\]/DAC/clrcode_reg\[19:0\]" \
                              "/simulator/DC_GEN\[$ch\]/DAC/sw_ctrl_reg\[19:0\]" \
                              "/simulator/DC_GEN\[$ch\]/DAC/dac_input_reg\[19:0\]" \
                              "/simulator/DC_GEN\[$ch\]/DAC/SDODIS" \
                              "/simulator/DC_GEN\[$ch\]/DAC/DACTRI" \
                              "/simulator/DC_GEN\[$ch\]/DAC/OPGND"

    wvSetPosition -win $nw [format {("dc/ch%d/DAC/v" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DC_GEN\[$ch\]/DAC/VOUT" \
                              "/simulator/DC_GEN\[$ch\]/DAC/VDIGITAL\[19:0\]"

}

for {set ch 23} {$ch >= 0} {incr ch -1} {

    wvCollapseGroup -win $nw "dc/ch$ch/AXIL_REGS/aw"
    wvCollapseGroup -win $nw "dc/ch$ch/AXIL_REGS/w"
    wvCollapseGroup -win $nw "dc/ch$ch/AXIL_REGS/b"
    wvCollapseGroup -win $nw "dc/ch$ch/AXIL_REGS/ar"
    wvCollapseGroup -win $nw "dc/ch$ch/AXIL_REGS/r"
    wvCollapseGroup -win $nw "dc/ch$ch/AXIL_REGS"

    wvCollapseGroup -win $nw "dc/ch$ch/SEQ/new"
    wvCollapseGroup -win $nw "dc/ch$ch/SEQ/fetch"
    wvCollapseGroup -win $nw "dc/ch$ch/SEQ/out"
    wvCollapseGroup -win $nw "dc/ch$ch/SEQ"

    wvCollapseGroup -win $nw "dc/ch$ch/CORE/decode"
    wvCollapseGroup -win $nw "dc/ch$ch/CORE/iterate"
    wvCollapseGroup -win $nw "dc/ch$ch/CORE/spi/wires"
    wvCollapseGroup -win $nw "dc/ch$ch/CORE/spi"
    wvCollapseGroup -win $nw "dc/ch$ch/CORE/hold"
    wvCollapseGroup -win $nw "dc/ch$ch/CORE"

    wvCollapseGroup -win $nw "dc/ch$ch/DAC/pins"
    wvCollapseGroup -win $nw "dc/ch$ch/DAC/regs"
    wvCollapseGroup -win $nw "dc/ch$ch/DAC/v"
    wvCollapseGroup -win $nw "dc/ch$ch/DAC"

    wvCollapseGroup -win $nw "dc/ch$ch"

}

wvCollapseGroup -win $nw "dc"

for {set ch 5} {$ch >= 0} {incr ch -1} {
    wvSelectGroup -win $nw {rf}
    wvAddSubGroup -win $nw "ch$ch"

    wvSelectGroup -win $nw "rf/ch$ch"
    wvAddSubGroup -win $nw "DAC"
    wvAddSubGroup -win $nw "CORE"
    wvAddSubGroup -win $nw "SEQ"
    wvAddSubGroup -win $nw "AXIL_REGS"

    wvSelectGroup -win $nw "rf/ch$ch/AXIL_REGS"
    wvAddSubGroup -win $nw "r"
    wvAddSubGroup -win $nw "ar"
    wvAddSubGroup -win $nw "b"
    wvAddSubGroup -win $nw "w"
    wvAddSubGroup -win $nw "aw"

    wvSetPosition -win $nw [format {("rf/ch%d/AXIL_REGS" 0)} $ch]
    wvAddSignal -win $nw "/simulator/RF_GEN\[$ch\]/REGS/AXIL_REGS/i_aclk" \
                              "/simulator/RF_GEN\[$ch\]/REGS/AXIL_REGS/i_aresetn" \
                              "/simulator/RF_GEN\[$ch\]/REGS/AXIL_REGS/r_regs\[0:65\]\[31:0\]" \
                              "/simulator/RF_GEN\[$ch\]/REGS/AXIL_REGS/o_regs\[0:65\]\[31:0\]"

    wvSetPosition -win $nw [format {("rf/ch%d/AXIL_REGS/aw" 0)} $ch]
    wvAddSignal -win $nw "/simulator/RF_GEN\[$ch\]/REGS/AXIL_REGS/o_awready" \
                              "/simulator/RF_GEN\[$ch\]/REGS/AXIL_REGS/i_awvalid" \
                              "/simulator/RF_GEN\[$ch\]/REGS/AXIL_REGS/i_awaddr\[8:0\]" \
                              "/simulator/RF_GEN\[$ch\]/REGS/AXIL_REGS/w_awireg\[6:0\]" \
                              "/simulator/RF_GEN\[$ch\]/REGS/AXIL_REGS/w_awls2b\[1:0\]"

    wvSetPosition -win $nw [format {("rf/ch%d/AXIL_REGS/w" 0)} $ch]
    wvAddSignal -win $nw "/simulator/RF_GEN\[$ch\]/REGS/AXIL_REGS/o_wready" \
                              "/simulator/RF_GEN\[$ch\]/REGS/AXIL_REGS/i_wvalid" \
                              "/simulator/RF_GEN\[$ch\]/REGS/AXIL_REGS/i_wdata\[31:0\]" \
                              "/simulator/RF_GEN\[$ch\]/REGS/AXIL_REGS/i_wstrb\[3:0\]" \
                              "/simulator/RF_GEN\[$ch\]/REGS/AXIL_REGS/w_wdatastrb\[31:0\]"

    wvSetPosition -win $nw [format {("rf/ch%d/AXIL_REGS/b" 0)} $ch]
    wvAddSignal -win $nw "/simulator/RF_GEN\[$ch\]/REGS/AXIL_REGS/i_bready" \
                              "/simulator/RF_GEN\[$ch\]/REGS/AXIL_REGS/o_bvalid" \
                              "/simulator/RF_GEN\[$ch\]/REGS/AXIL_REGS/o_bresp\[1:0\]"

    wvSetPosition -win $nw [format {("rf/ch%d/AXIL_REGS/ar" 0)} $ch]
    wvAddSignal -win $nw "/simulator/RF_GEN\[$ch\]/REGS/AXIL_REGS/o_arready" \
                              "/simulator/RF_GEN\[$ch\]/REGS/AXIL_REGS/i_arvalid" \
                              "/simulator/RF_GEN\[$ch\]/REGS/AXIL_REGS/i_araddr\[8:0\]" \
                              "/simulator/RF_GEN\[$ch\]/REGS/AXIL_REGS/w_arireg\[6:0\]" \
                              "/simulator/RF_GEN\[$ch\]/REGS/AXIL_REGS/w_arls2b\[1:0\]"

    wvSetPosition -win $nw [format {("rf/ch%d/AXIL_REGS/r" 0)} $ch]
    wvAddSignal -win $nw "/simulator/RF_GEN\[$ch\]/REGS/AXIL_REGS/i_rready" \
                              "/simulator/RF_GEN\[$ch\]/REGS/AXIL_REGS/o_rvalid" \
                              "/simulator/RF_GEN\[$ch\]/REGS/AXIL_REGS/o_rdata\[31:0\]" \
                              "/simulator/RF_GEN\[$ch\]/REGS/AXIL_REGS/o_rresp\[1:0\]"

    wvSelectGroup -win $nw "rf/ch$ch/SEQ"
    wvAddSubGroup -win $nw "out"
    wvAddSubGroup -win $nw "fetch"
    wvAddSubGroup -win $nw "new"

    wvSetPosition -win $nw [format {("rf/ch%d/SEQ" 0)} $ch]
    wvAddSignal -win $nw "/simulator/RF_GEN\[$ch\]/RF/SEQ/i_clk" \
                              "/simulator/RF_GEN\[$ch\]/RF/SEQ/i_rst" \
                              "/simulator/RF_GEN\[$ch\]/RF/SEQ/w_propagate"

    wvSetPosition -win $nw [format {("rf/ch%d/SEQ/new" 0)} $ch]
    wvAddSignal -win $nw "/simulator/RF_GEN\[$ch\]/RF/SEQ/i_regs\[0:65\]\[31:0\]" \
                              "/simulator/RF_GEN\[$ch\]/RF/SEQ/w_last0" \
                              "/simulator/RF_GEN\[$ch\]/RF/SEQ/w_last0_ff1" \
                              "/simulator/RF_GEN\[$ch\]/RF/SEQ/w_last0_ff2" \
                              "/simulator/RF_GEN\[$ch\]/RF/SEQ/w_new_sequence"

    wvSetPosition -win $nw [format {("rf/ch%d/SEQ/fetch" 0)} $ch]
    wvAddSignal -win $nw "/simulator/RF_GEN\[$ch\]/RF/SEQ/r_sequence\[0:15\]\[114:0\]" \
                              "/simulator/RF_GEN\[$ch\]/RF/SEQ/r_iters\[10:0\]" \
                              "/simulator/RF_GEN\[$ch\]/RF/SEQ/r_iptr\[3:0\]" \
                              "/simulator/RF_GEN\[$ch\]/RF/SEQ/w_insn_fetch\[114:0\]" \
                              "/simulator/RF_GEN\[$ch\]/RF/SEQ/w_insn_bubble" \
                              "/simulator/RF_GEN\[$ch\]/RF/SEQ/w_iptr_plus1\[3:0\]" \
                              "/simulator/RF_GEN\[$ch\]/RF/SEQ/w_next_null"

    wvSetPosition -win $nw [format {("rf/ch%d/SEQ/out" 0)} $ch]
    wvAddSignal -win $nw "/simulator/RF_GEN\[$ch\]/RF/SEQ/o_empty" \
                              "/simulator/RF_GEN\[$ch\]/RF/SEQ/i_next" \
                              "/simulator/RF_GEN\[$ch\]/RF/SEQ/o_addr\[3:0\]" \
                              "/simulator/RF_GEN\[$ch\]/RF/SEQ/o_insn\[114:0\]" \
                              "/simulator/RF_GEN\[$ch\]/RF/SEQ/r_iptr_modify\[3:0\]" \
                              "/simulator/RF_GEN\[$ch\]/RF/SEQ/i_insn_modified\[114:0\]"

    wvSelectGroup -win $nw "rf/ch$ch/CORE"
    wvAddSubGroup -win $nw "out"
    wvAddSubGroup -win $nw "result"

    for {set i 15} {$i >= 0} {incr i -1} {
        wvSelectGroup -win $nw "rf/ch$ch/CORE"
        wvAddSubGroup -win $nw "cordic$i"
        wvSetPosition -win $nw [format {("rf/ch%d/CORE/cordic%d" 0)} $ch $i]
        wvAddSignal -win $nw "/simulator/RF_GEN\[$ch\]/RF/CORE/CORDIC_GEN\[0\]/CORDIC/c\[$i\]" \
                                  "/simulator/RF_GEN\[$ch\]/RF/CORE/CORDIC_GEN\[1\]/CORDIC/c\[$i\]" \
                                  "/simulator/RF_GEN\[$ch\]/RF/CORE/CORDIC_GEN\[2\]/CORDIC/c\[$i\]" \
                                  "/simulator/RF_GEN\[$ch\]/RF/CORE/CORDIC_GEN\[3\]/CORDIC/c\[$i\]" \
                                  "/simulator/RF_GEN\[$ch\]/RF/CORE/CORDIC_GEN\[4\]/CORDIC/c\[$i\]" \
                                  "/simulator/RF_GEN\[$ch\]/RF/CORE/CORDIC_GEN\[5\]/CORDIC/c\[$i\]" \
                                  "/simulator/RF_GEN\[$ch\]/RF/CORE/CORDIC_GEN\[6\]/CORDIC/c\[$i\]" \
                                  "/simulator/RF_GEN\[$ch\]/RF/CORE/CORDIC_GEN\[7\]/CORDIC/c\[$i\]"
    }

    wvSelectGroup -win $nw "rf/ch$ch/CORE"
    wvAddSubGroup -win $nw "phase"
    wvAddSubGroup -win $nw "decode"

    wvSetPosition -win $nw [format {("rf/ch%d/CORE" 0)} $ch]
    wvAddSignal -win $nw "/simulator/RF_GEN\[$ch\]/RF/CORE/i_clk" \
                              "/simulator/RF_GEN\[$ch\]/RF/CORE/i_rst" \
                              "/simulator/RF_GEN\[$ch\]/RF/CORE/w_stall"

    wvSetPosition -win $nw [format {("rf/ch%d/CORE/decode" 0)} $ch]
    wvAddSignal -win $nw "/simulator/RF_GEN\[$ch\]/RF/CORE/d" \
                              "/simulator/RF_GEN\[$ch\]/RF/CORE/i_empty" \
                              "/simulator/RF_GEN\[$ch\]/RF/CORE/o_next" \
                              "/simulator/RF_GEN\[$ch\]/RF/CORE/i_addr\[3:0\]" \
                              "/simulator/RF_GEN\[$ch\]/RF/CORE/i_insn" \
                              "/simulator/RF_GEN\[$ch\]/RF/CORE/o_insn_modified"

    wvSetPosition -win $nw [format {("rf/ch%d/CORE/phase" 0)} $ch]
    wvAddSignal -win $nw "/simulator/RF_GEN\[$ch\]/RF/CORE/p"
    wvAddSignal -win $nw "/simulator/RF_GEN\[$ch\]/RF/CORE/w_new_phase"

    wvSetPosition -win $nw [format {("rf/ch%d/CORE/result" 0)} $ch]
    wvAddSignal -win $nw "/simulator/RF_GEN\[$ch\]/RF/CORE/r"
    wvAddSignal -win $nw "/simulator/RF_GEN\[$ch\]/RF/CORE/o_armed"
    wvAddSignal -win $nw "/simulator/RF_GEN\[$ch\]/RF/CORE/i_start"

    wvSetPosition -win $nw [format {("rf/ch%d/CORE/out" 0)} $ch]
    wvAddSignal -win $nw "/simulator/RF_GEN\[$ch\]/RF/CORE/o_addr\[3:0\]"
    wvAddSignal -win $nw "/simulator/RF_GEN\[$ch\]/RF/CORE/o_sample_start\[19:0\]"
    wvAddSignal -win $nw "/simulator/RF_GEN\[$ch\]/RF/CORE/o_sample_end\[19:0\]"
    wvAddSignal -win $nw "/simulator/RF_GEN\[$ch\]/RF/CORE/o_QIx8\[255:0\]"

    wvSelectGroup -win $nw "rf/ch$ch/DAC"
    wvAddSubGroup -win $nw "v"

    wvSetPosition -win $nw [format {("rf/ch%d/DAC" 0)} $ch]
    wvAddSignal -win $nw "/simulator/RF_GEN\[$ch\]/DAC/i_clk" \
                              "/simulator/RF_GEN\[$ch\]/DAC/i_dac_clk" \
                              "/simulator/RF_GEN\[$ch\]/DAC/dac_cycle" \
                              "/simulator/RF_GEN\[$ch\]/DAC/i_QIx8\[255:0\]"

    wvSetPosition -win $nw [format {("rf/ch%d/DAC/v" 0)} $ch]
    wvAddSignal -win $nw "/simulator/RF_GEN\[$ch\]/DAC/w_Ix8\[7:0\]\[13:0\]" \
                              "/simulator/RF_GEN\[$ch\]/DAC/w_Qx8\[7:0\]\[13:0\]" \
                              "/simulator/RF_GEN\[$ch\]/DAC/o_I\[13:0\]" \
                              "/simulator/RF_GEN\[$ch\]/DAC/o_Q\[13:0\]" \
                              "/simulator/RF_GEN\[$ch\]/DAC/I" \
                              "/simulator/RF_GEN\[$ch\]/DAC/Q" \
                              "/simulator/RF_GEN\[$ch\]/DAC/deg" \
                              "/simulator/RF_GEN\[$ch\]/DAC/rad" \
                              "/simulator/RF_GEN\[$ch\]/DAC/nco_i" \
                              "/simulator/RF_GEN\[$ch\]/DAC/nco_q" \
                              "/simulator/RF_GEN\[$ch\]/DAC/o_vrf"



}

for {set ch 5} {$ch >= 0} {incr ch -1} {

    wvCollapseGroup -win $nw "rf/ch$ch/AXIL_REGS/aw"
    wvCollapseGroup -win $nw "rf/ch$ch/AXIL_REGS/w"
    wvCollapseGroup -win $nw "rf/ch$ch/AXIL_REGS/b"
    wvCollapseGroup -win $nw "rf/ch$ch/AXIL_REGS/ar"
    wvCollapseGroup -win $nw "rf/ch$ch/AXIL_REGS/r"
    wvCollapseGroup -win $nw "rf/ch$ch/AXIL_REGS"

    wvCollapseGroup -win $nw "rf/ch$ch/SEQ/new"
    wvCollapseGroup -win $nw "rf/ch$ch/SEQ/fetch"
    wvCollapseGroup -win $nw "rf/ch$ch/SEQ/out"
    wvCollapseGroup -win $nw "rf/ch$ch/SEQ"

    wvCollapseGroup -win $nw "rf/ch$ch/CORE/decode"
    wvCollapseGroup -win $nw "rf/ch$ch/CORE/phase"
    for {set i 0} {$i <= 15} {incr i 1} {
        wvCollapseGroup -win $nw "rf/ch$ch/CORE/cordic$i"
    }
    wvCollapseGroup -win $nw "rf/ch$ch/CORE/result"
    wvCollapseGroup -win $nw "rf/ch$ch/CORE/out"
    wvCollapseGroup -win $nw "rf/ch$ch/CORE"

    wvCollapseGroup -win $nw "rf/ch$ch/DAC/v"
    wvCollapseGroup -win $nw "rf/ch$ch/DAC"

    wvCollapseGroup -win $nw "rf/ch$ch"

}

wvCollapseGroup -win $nw "rf"

