set nw [wvCreateWindow]
wvRenameGroup -win $nw {G1} {uart}
wvAddGroup -win $nw {dc}
wvAddGroup -win $nw {rf}
wvAddGroup -win $nw {li}
wvAddGroup -win $nw {ex}
wvAddGroup -win $nw {launch}
wvAddGroup -win $nw {v}

wvSetPosition -win $nw {("v" 0)}
wvAddSignal -win $nw "simulator/vdc" \
                     "simulator/vdc_digital" \
                     "simulator/vrf" \
                     "simulator/vrf_I" \
                     "simulator/vrf_Q" \
                     "simulator/vex" \
                     "simulator/w_li_sample_mask_bus" \
                     "simulator/w_li_sample_spike_bus" \
                     "simulator/w_phase_obs"

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
                     "/simulator/LCH_REGS/AXIL_REGS/r_regs" \
                     "/simulator/LCH_REGS/AXIL_REGS/o_regs"

wvSetPosition -win $nw {("launch/AXIL_REGS/aw" 0)}
wvAddSignal -win $nw "/simulator/LCH_REGS/AXIL_REGS/o_awready" \
                     "/simulator/LCH_REGS/AXIL_REGS/i_awvalid" \
                     "/simulator/LCH_REGS/AXIL_REGS/i_awaddr" \
                     "/simulator/LCH_REGS/AXIL_REGS/w_awireg" \
                     "/simulator/LCH_REGS/AXIL_REGS/w_awls2b"

wvSetPosition -win $nw {("launch/AXIL_REGS/w" 0)}
wvAddSignal -win $nw "/simulator/LCH_REGS/AXIL_REGS/o_wready" \
                     "/simulator/LCH_REGS/AXIL_REGS/i_wvalid" \
                     "/simulator/LCH_REGS/AXIL_REGS/i_wdata" \
                     "/simulator/LCH_REGS/AXIL_REGS/i_wstrb" \
                     "/simulator/LCH_REGS/AXIL_REGS/w_wdatastrb"

wvSetPosition -win $nw {("launch/AXIL_REGS/b" 0)}
wvAddSignal -win $nw "/simulator/LCH_REGS/AXIL_REGS/i_bready" \
                     "/simulator/LCH_REGS/AXIL_REGS/o_bvalid" \
                     "/simulator/LCH_REGS/AXIL_REGS/o_bresp"

wvSetPosition -win $nw {("launch/AXIL_REGS/ar" 0)}
wvAddSignal -win $nw "/simulator/LCH_REGS/AXIL_REGS/o_arready" \
                     "/simulator/LCH_REGS/AXIL_REGS/i_arvalid" \
                     "/simulator/LCH_REGS/AXIL_REGS/i_araddr" \
                     "/simulator/LCH_REGS/AXIL_REGS/w_arireg" \
                     "/simulator/LCH_REGS/AXIL_REGS/w_arls2b"

wvSetPosition -win $nw {("launch/AXIL_REGS/r" 0)}
wvAddSignal -win $nw "/simulator/LCH_REGS/AXIL_REGS/i_rready" \
                     "/simulator/LCH_REGS/AXIL_REGS/o_rvalid" \
                     "/simulator/LCH_REGS/AXIL_REGS/o_rdata" \
                     "/simulator/LCH_REGS/AXIL_REGS/o_rresp"

wvSelectGroup -win $nw "launch/LCH"
wvAddSubGroup -win $nw "start"
wvAddSubGroup -win $nw "armed"
wvAddSubGroup -win $nw "new"

wvSetPosition -win $nw {("launch/LCH" 0)}
wvAddSignal -win $nw "/simulator/DCRFLI/LCH/i_clk" \
                     "/simulator/DCRFLI/LCH/i_rst" \
                     "/simulator/DCRFLI/LCH/r_state" \
                     "/simulator/DCRFLI/LCH/w_next_state" \
                     "/simulator/DCRFLI/LCH/r_dc_active_mask" \
                     "/simulator/DCRFLI/LCH/r_rf_active_mask" \
                     "/simulator/DCRFLI/LCH/r_li_active_mask" \
                     "/simulator/DCRFLI/LCH/r_ex_active_mask"

wvSetPosition -win $nw {("launch/LCH/new" 0)}
wvAddSignal -win $nw "/simulator/DCRFLI/LCH/i_regs" \
                     "/simulator/DCRFLI/LCH/w_last0" \
                     "/simulator/DCRFLI/LCH/w_last0_ff1" \
                     "/simulator/DCRFLI/LCH/w_last0_ff2" \
                     "/simulator/DCRFLI/LCH/w_new_stream" \
                     "/simulator/DCRFLI/LCH/i_uregs" \
                     "/simulator/DCRFLI/LCH/w_ulast0" \
                     "/simulator/DCRFLI/LCH/w_ulast0_ff1" \
                     "/simulator/DCRFLI/LCH/w_ulast0_ff2" \
                     "/simulator/DCRFLI/LCH/w_new_ustream"

wvSetPosition -win $nw {("launch/LCH/armed" 0)}
wvAddSignal -win $nw "/simulator/DCRFLI/LCH/i_trigger" \
                     "/simulator/DCRFLI/LCH/i_dc_armed" \
                     "/simulator/DCRFLI/LCH/i_rf_armed" \
                     "/simulator/DCRFLI/LCH/i_li_armed" \
                     "/simulator/DCRFLI/LCH/i_ex_armed" \
                     "/simulator/DCRFLI/LCH/r_dc_armed" \
                     "/simulator/DCRFLI/LCH/r_rf_armed" \
                     "/simulator/DCRFLI/LCH/r_li_armed" \
                     "/simulator/DCRFLI/LCH/r_ex_armed" \
                     "/simulator/DCRFLI/LCH/w_dc_ready" \
                     "/simulator/DCRFLI/LCH/w_rf_ready" \
                     "/simulator/DCRFLI/LCH/w_li_ready" \
                     "/simulator/DCRFLI/LCH/w_ex_ready" \
                     "/simulator/DCRFLI/LCH/w_all_ready"

wvSetPosition -win $nw {("launch/LCH/start" 0)}
wvAddSignal -win $nw "/simulator/DCRFLI/LCH/o_dc_start" \
                     "/simulator/DCRFLI/LCH/o_rf_start" \
                     "/simulator/DCRFLI/LCH/o_li_start" \
                     "/simulator/DCRFLI/LCH/o_ex_start"

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

# uart regs
# wvSelectGroup -win $nw "uart"
# wvAddSubGroup -win $nw "UREGS"
# wvAddSubGroup -win $nw "TSMT"
# wvAddSubGroup -win $nw "RECV"
#
# wvSelectGroup -win $nw "uart/RECV"
# wvAddSubGroup -win $nw "RXFIFO"
#
# wvSetPosition -win $nw {("uart/RECV" 0)}
# wvAddSignal -win $nw "/simulator/UREGS/UART/RECV/i_clk" \
#                      "/simulator/UREGS/UART/RECV/i_rst" \
#                      "/simulator/UREGS/UART/RECV/r_state" \
#                      "/simulator/UREGS/UART/RECV/i_rx" \
#                      "/simulator/UREGS/UART/RECV/i_sample_tick" \
#                      "/simulator/UREGS/UART/RECV/r_cycle_counter" \
#                      "/simulator/UREGS/UART/RECV/r_bit_counter" \
#                      "/simulator/UREGS/UART/RECV/w_data_en" \
#                      "/simulator/UREGS/UART/RECV/r_data" \
#                      "/simulator/UREGS/UART/RECV/o_enq_rxq" \
#                      "/simulator/UREGS/UART/RECV/o_data"
#
# wvSetPosition -win $nw {("uart/RECV/RXFIFO" 0)}
# wvAddSignal -win $nw "/simulator/UREGS/UART/RXFIFO/i_clk" \
#                      "/simulator/UREGS/UART/RXFIFO/i_rst" \
#                      "/simulator/UREGS/UART/RXFIFO/r_num_data" \
#                      "/simulator/UREGS/UART/RXFIFO/r_enq_ptr" \
#                      "/simulator/UREGS/UART/RXFIFO/i_enq" \
#                      "/simulator/UREGS/UART/RXFIFO/w_enq_en" \
#                      "/simulator/UREGS/UART/RXFIFO/o_full" \
#                      "/simulator/UREGS/UART/RXFIFO/r_deq_ptr" \
#                      "/simulator/UREGS/UART/RXFIFO/i_deq" \
#                      "/simulator/UREGS/UART/RXFIFO/o_empty" \
#                      "/simulator/UREGS/UART/RXFIFO/r_data"
#
#
# wvSelectGroup -win $nw "uart/TSMT"
# wvAddSubGroup -win $nw "TXFIFO"
#
# wvSetPosition -win $nw {("uart/TSMT" 0)}
# wvAddSignal -win $nw "/simulator/UREGS/UART/TSMT/i_clk" \
#                      "/simulator/UREGS/UART/TSMT/i_rst" \
#                      "/simulator/UREGS/UART/TSMT/r_state" \
#                      "/simulator/UREGS/UART/TSMT/o_tx" \
#                      "/simulator/UREGS/UART/TSMT/i_sample_tick" \
#                      "/simulator/UREGS/UART/TSMT/i_data" \
#                      "/simulator/UREGS/UART/TSMT/o_deq_txq" \
#                      "/simulator/UREGS/UART/TSMT/r_data" \
#                      "/simulator/UREGS/UART/TSMT/r_cycle_counter" \
#                      "/simulator/UREGS/UART/TSMT/r_bit_counter" \
#                      "/simulator/UREGS/UART/TSMT/w_data_en" \
#                      "/simulator/UREGS/UART/TSMT/w_data_shift" \
#                      "/simulator/UREGS/UART/TSMT/r_data"
#
# wvSetPosition -win $nw {("uart/TSMT/TXFIFO" 0)}
# wvAddSignal -win $nw "/simulator/UREGS/UART/TXFIFO/i_clk" \
#                      "/simulator/UREGS/UART/TXFIFO/i_rst" \
#                      "/simulator/UREGS/UART/TXFIFO/r_num_data" \
#                      "/simulator/UREGS/UART/TXFIFO/r_enq_ptr" \
#                      "/simulator/UREGS/UART/TXFIFO/i_enq" \
#                      "/simulator/UREGS/UART/TXFIFO/w_enq_en" \
#                      "/simulator/UREGS/UART/TXFIFO/o_full" \
#                      "/simulator/UREGS/UART/TXFIFO/r_deq_ptr" \
#                      "/simulator/UREGS/UART/TXFIFO/i_deq" \
#                      "/simulator/UREGS/UART/TXFIFO/o_empty" \
#                      "/simulator/UREGS/UART/TXFIFO/r_data"
#
# wvSelectGroup -win $nw "uart/UREGS"
# wvSetPosition -win $nw {("uart/UREGS" 0)}
# wvAddSignal -win $nw "/simulator/UREGS/i_clk" \
#                      "/simulator/UREGS/i_rst" \
#                      "/simulator/UREGS/r_regs" \
#                      "/simulator/UREGS/o_regs" \
#                      "/simulator/UREGS/w_deq_rxq" \
#                      "/simulator/UREGS/w_rxq_data" \
#                      "/simulator/UREGS/w_rxq_empty" \
#                      "/simulator/UREGS/w_enq_txq" \
#                      "/simulator/UREGS/w_txq_data" \
#                      "/simulator/UREGS/w_rxq_empty" \
#                      "/simulator/UREGS/w_latch_op" \
#                      "/simulator/UREGS/r_op" \
#                      "/simulator/UREGS/w_addr" \
#                      "/simulator/UREGS/w_wr" \
#                      "/simulator/UREGS/w_shift_in" \
#                      "/simulator/UREGS/r_wr_data" \
#                      "/simulator/UREGS/w_rd" \
#                      "/simulator/UREGS/w_shift_out" \
#                      "/simulator/UREGS/r_rd_data" \
#                      "/simulator/UREGS/w_bcnt_en" \
#                      "/simulator/UREGS/w_bcnt_clr" \
#                      "/simulator/UREGS/r_bcnt" \
#                      "/simulator/UREGS/r_state"
#
# wvCollapseGroup -win $nw "uart/RECV/RXFIFO"
# wvCollapseGroup -win $nw "uart/RECV"
# wvCollapseGroup -win $nw "uart/TSMT/TXFIFO"
# wvCollapseGroup -win $nw "uart/TSMT"
# wvCollapseGroup -win $nw "uart/UREGS"
# wvCollapseGroup -win $nw "uart"
#
# for {set ch 23} {$ch >= 0} {incr ch -1} {
#
#     wvSelectGroup -win $nw {dc}
#     wvAddSubGroup -win $nw "ch$ch"
#
#     wvSelectGroup -win $nw "dc/ch$ch"
#     wvAddSubGroup -win $nw "DAC"
#     wvAddSubGroup -win $nw "CTRL"
#     wvAddSubGroup -win $nw "CORE"
#     wvAddSubGroup -win $nw "SEQ"
#     wvAddSubGroup -win $nw "AXIL_REGS"
#
#     # AXIL REGS
#     wvSelectGroup -win $nw "dc/ch$ch/AXIL_REGS"
#     wvAddSubGroup -win $nw "r"
#     wvAddSubGroup -win $nw "ar"
#     wvAddSubGroup -win $nw "b"
#     wvAddSubGroup -win $nw "w"
#     wvAddSubGroup -win $nw "aw"
#
#     wvSetPosition -win $nw [format {("dc/ch%d/AXIL_REGS" 0)} $ch]
#     wvAddSignal -win $nw "/simulator/DC_IO_GEN\[$ch\]/REGS/AXIL_REGS/i_aclk" \
#                          "/simulator/DC_IO_GEN\[$ch\]/REGS/AXIL_REGS/i_aresetn" \
#                          "/simulator/DC_IO_GEN\[$ch\]/REGS/AXIL_REGS/r_regs" \
#                          "/simulator/DC_IO_GEN\[$ch\]/REGS/AXIL_REGS/o_regs"
#
#     wvSetPosition -win $nw [format {("dc/ch%d/AXIL_REGS/aw" 0)} $ch]
#     wvAddSignal -win $nw "/simulator/DC_IO_GEN\[$ch\]/REGS/AXIL_REGS/o_awready" \
#                          "/simulator/DC_IO_GEN\[$ch\]/REGS/AXIL_REGS/i_awvalid" \
#                          "/simulator/DC_IO_GEN\[$ch\]/REGS/AXIL_REGS/i_awaddr" \
#                          "/simulator/DC_IO_GEN\[$ch\]/REGS/AXIL_REGS/w_awireg" \
#                          "/simulator/DC_IO_GEN\[$ch\]/REGS/AXIL_REGS/w_awls2b"
#
#     wvSetPosition -win $nw [format {("dc/ch%d/AXIL_REGS/w" 0)} $ch]
#     wvAddSignal -win $nw "/simulator/DC_IO_GEN\[$ch\]/REGS/AXIL_REGS/o_wready" \
#                          "/simulator/DC_IO_GEN\[$ch\]/REGS/AXIL_REGS/i_wvalid" \
#                          "/simulator/DC_IO_GEN\[$ch\]/REGS/AXIL_REGS/i_wdata" \
#                          "/simulator/DC_IO_GEN\[$ch\]/REGS/AXIL_REGS/i_wstrb" \
#                          "/simulator/DC_IO_GEN\[$ch\]/REGS/AXIL_REGS/w_wdatastrb"
#
#     wvSetPosition -win $nw [format {("dc/ch%d/AXIL_REGS/b" 0)} $ch]
#     wvAddSignal -win $nw "/simulator/DC_IO_GEN\[$ch\]/REGS/AXIL_REGS/i_bready" \
#                          "/simulator/DC_IO_GEN\[$ch\]/REGS/AXIL_REGS/o_bvalid" \
#                          "/simulator/DC_IO_GEN\[$ch\]/REGS/AXIL_REGS/o_bresp"
#
#     wvSetPosition -win $nw [format {("dc/ch%d/AXIL_REGS/ar" 0)} $ch]
#     wvAddSignal -win $nw "/simulator/DC_IO_GEN\[$ch\]/REGS/AXIL_REGS/o_arready" \
#                          "/simulator/DC_IO_GEN\[$ch\]/REGS/AXIL_REGS/i_arvalid" \
#                          "/simulator/DC_IO_GEN\[$ch\]/REGS/AXIL_REGS/i_araddr" \
#                          "/simulator/DC_IO_GEN\[$ch\]/REGS/AXIL_REGS/w_arireg" \
#                          "/simulator/DC_IO_GEN\[$ch\]/REGS/AXIL_REGS/w_arls2b"
#
#     wvSetPosition -win $nw [format {("dc/ch%d/AXIL_REGS/r" 0)} $ch]
#     wvAddSignal -win $nw "/simulator/DC_IO_GEN\[$ch\]/REGS/AXIL_REGS/i_rready" \
#                          "/simulator/DC_IO_GEN\[$ch\]/REGS/AXIL_REGS/o_rvalid" \
#                          "/simulator/DC_IO_GEN\[$ch\]/REGS/AXIL_REGS/o_rdata" \
#                          "/simulator/DC_IO_GEN\[$ch\]/REGS/AXIL_REGS/o_rresp"
#
#     # SEQ
#     wvSelectGroup -win $nw "dc/ch$ch/SEQ"
#     wvAddSubGroup -win $nw "out"
#     wvAddSubGroup -win $nw "fetch"
#     wvAddSubGroup -win $nw "new"
#
#     wvSetPosition -win $nw [format {("dc/ch%d/SEQ" 0)} $ch]
#     wvAddSignal -win $nw "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/SEQ/i_clk" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/SEQ/i_rst" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/SEQ/w_propagate"
#
#     wvSetPosition -win $nw [format {("dc/ch%d/SEQ/new" 0)} $ch]
#     wvAddSignal -win $nw "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/SEQ/i_regs" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/SEQ/w_last0" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/SEQ/w_last0_ff1" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/SEQ/w_last0_ff2" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/SEQ/w_new_sequence" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/SEQ/i_uregs" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/SEQ/w_ulast0" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/SEQ/w_ulast0_ff1" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/SEQ/w_ulast0_ff2" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/SEQ/w_new_usequence"
#
#     wvSetPosition -win $nw [format {("dc/ch%d/SEQ/fetch" 0)} $ch]
#     wvAddSignal -win $nw "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/SEQ/r_sequence" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/SEQ/r_iters" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/SEQ/r_iptr" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/SEQ/w_insn_fetch" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/SEQ/w_insn_bubble" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/SEQ/w_iptr_plus1" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/SEQ/w_next_null"
#
#     wvSetPosition -win $nw [format {("dc/ch%d/SEQ/out" 0)} $ch]
#     wvAddSignal -win $nw "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/SEQ/o_empty" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/SEQ/i_next" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/SEQ/o_addr" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/SEQ/o_insn" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/SEQ/r_iptr_modify" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/SEQ/i_insn_modified"
#
#     # CORE
#     wvSelectGroup -win $nw "dc/ch$ch/CORE"
#     wvAddSubGroup -win $nw "hold"
#     wvAddSubGroup -win $nw "spi"
#     wvAddSubGroup -win $nw "iterate"
#     wvAddSubGroup -win $nw "decode"
#
#     wvSetPosition -win $nw [format {("dc/ch%d/CORE" 0)} $ch]
#     wvAddSignal -win $nw "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/CORE/i_clk" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/CORE/i_rst" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/CORE/w_propagate_i2s" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/CORE/w_propagate_s2h" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/CORE/o_empty" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/CORE/i_ctrl"
#
#     wvSetPosition -win $nw [format {("dc/ch%d/CORE/decode" 0)} $ch]
#     wvAddSignal -win $nw "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/CORE/d" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/CORE/i_empty" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/CORE/o_next" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/CORE/i_addr" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/CORE/i_insn" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/CORE/o_insn_modified"
#
#     wvSetPosition -win $nw [format {("dc/ch%d/CORE/iterate" 0)} $ch]
#     wvAddSignal -win $nw "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/CORE/i"
#
#     wvSetPosition -win $nw [format {("dc/ch%d/CORE/spi" 0)} $ch]
#     wvAddSignal -win $nw "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/CORE/s" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/CORE/w_spi_dout" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/CORE/w_spi_done" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/CORE/o_armed" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/CORE/i_start"
#
#     wvSelectGroup -win $nw "dc/ch$ch/CORE/spi"
#     wvAddSubGroup -win $nw "wires"
#     wvSetPosition -win $nw [format {("dc/ch%d/CORE/spi/wires" 0)} $ch]
#     wvAddSignal -win $nw "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/CORE/o_sclk" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/CORE/o_mosi" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/CORE/i_miso" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/CORE/o_cs_n" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/CORE/o_ldac_n"
#
#     wvSetPosition -win $nw [format {("dc/ch%d/CORE/hold" 0)} $ch]
#     wvAddSignal -win $nw "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/CORE/h" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/CORE/o_eop"
#
#     # CTRL
#     wvSelectGroup -win $nw "dc/ch$ch/CTRL"
#     wvAddSubGroup -win $nw "new"
#
#     wvSetPosition -win $nw [format {("dc/ch%d/CTRL" 0)} $ch]
#     wvAddSignal -win $nw "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/CTRL/o_ctrl" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/CTRL/r_dvsr" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/CTRL/r_cs_up_cycles" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/CTRL/r_ldac_cycles"
#
#     wvSetPosition -win $nw [format {("dc/ch%d/CTRL/new" 0)} $ch]
#     wvAddSignal -win $nw "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/CTRL/i_regs" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/CTRL/w_last0" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/CTRL/w_last0_ff1" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/CTRL/w_last0_ff2" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/CTRL/w_new_ctrl" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/CTRL/i_uregs" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/CTRL/w_ulast0" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/CTRL/w_ulast0_ff1" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/CTRL/w_ulast0_ff2" \
#                          "/simulator/DCRFLI/DC_GEN\[$ch\]/DC/CTRL/w_new_uctrl"
#
#     # DAC
#     wvSelectGroup -win $nw "dc/ch$ch/DAC"
#     wvAddSubGroup -win $nw "v"
#     wvAddSubGroup -win $nw "regs"
#     wvAddSubGroup -win $nw "pins"
#
#     wvSetPosition -win $nw [format {("dc/ch%d/DAC" 0)} $ch]
#     wvAddSignal -win $nw "/simulator/DC_IO_GEN\[$ch\]/DAC/valid_transaction" \
#                          "/simulator/DC_IO_GEN\[$ch\]/DAC/input_shift_reg" \
#                          "/simulator/DC_IO_GEN\[$ch\]/DAC/rw" \
#                          "/simulator/DC_IO_GEN\[$ch\]/DAC/addr" \
#                          "/simulator/DC_IO_GEN\[$ch\]/DAC/data" \
#                          "/simulator/DC_IO_GEN\[$ch\]/DAC/rd_data"
#
#     wvSetPosition -win $nw [format {("dc/ch%d/DAC/pins" 0)} $ch]
#     wvAddSignal -win $nw "/simulator/DC_IO_GEN\[$ch\]/DAC/SCLK" \
#                          "/simulator/DC_IO_GEN\[$ch\]/DAC/SDIN" \
#                          "/simulator/DC_IO_GEN\[$ch\]/DAC/SYNC_N" \
#                          "/simulator/DC_IO_GEN\[$ch\]/DAC/SDO" \
#                          "/simulator/DC_IO_GEN\[$ch\]/DAC/LDAC_N" \
#                          "/simulator/DC_IO_GEN\[$ch\]/DAC/CLR_N" \
#                          "/simulator/DC_IO_GEN\[$ch\]/DAC/RESET_N"
#
#     wvSetPosition -win $nw [format {("dc/ch%d/DAC/regs" 0)} $ch]
#     wvAddSignal -win $nw "/simulator/DC_IO_GEN\[$ch\]/DAC/dac_reg" \
#                          "/simulator/DC_IO_GEN\[$ch\]/DAC/ctrl_reg" \
#                          "/simulator/DC_IO_GEN\[$ch\]/DAC/clrcode_reg" \
#                          "/simulator/DC_IO_GEN\[$ch\]/DAC/sw_ctrl_reg" \
#                          "/simulator/DC_IO_GEN\[$ch\]/DAC/dac_input_reg" \
#                          "/simulator/DC_IO_GEN\[$ch\]/DAC/SDODIS" \
#                          "/simulator/DC_IO_GEN\[$ch\]/DAC/DACTRI" \
#                          "/simulator/DC_IO_GEN\[$ch\]/DAC/OPGND"
#
#     wvSetPosition -win $nw [format {("dc/ch%d/DAC/v" 0)} $ch]
#     wvAddSignal -win $nw "/simulator/DC_IO_GEN\[$ch\]/DAC/VOUT" \
#                          "/simulator/DC_IO_GEN\[$ch\]/DAC/VDIGITAL"
#
# }
#
# for {set ch 23} {$ch >= 0} {incr ch -1} {
#
#     wvCollapseGroup -win $nw "dc/ch$ch/AXIL_REGS/aw"
#     wvCollapseGroup -win $nw "dc/ch$ch/AXIL_REGS/w"
#     wvCollapseGroup -win $nw "dc/ch$ch/AXIL_REGS/b"
#     wvCollapseGroup -win $nw "dc/ch$ch/AXIL_REGS/ar"
#     wvCollapseGroup -win $nw "dc/ch$ch/AXIL_REGS/r"
#     wvCollapseGroup -win $nw "dc/ch$ch/AXIL_REGS"
#
#     wvCollapseGroup -win $nw "dc/ch$ch/SEQ/new"
#     wvCollapseGroup -win $nw "dc/ch$ch/SEQ/fetch"
#     wvCollapseGroup -win $nw "dc/ch$ch/SEQ/out"
#     wvCollapseGroup -win $nw "dc/ch$ch/SEQ"
#
#     wvCollapseGroup -win $nw "dc/ch$ch/CORE/decode"
#     wvCollapseGroup -win $nw "dc/ch$ch/CORE/iterate"
#     wvCollapseGroup -win $nw "dc/ch$ch/CORE/spi/wires"
#     wvCollapseGroup -win $nw "dc/ch$ch/CORE/spi"
#     wvCollapseGroup -win $nw "dc/ch$ch/CORE/hold"
#     wvCollapseGroup -win $nw "dc/ch$ch/CORE"
#
#     wvCollapseGroup -win $nw "dc/ch$ch/CTRL/new"
#     wvCollapseGroup -win $nw "dc/ch$ch/CTRL"
#
#     wvCollapseGroup -win $nw "dc/ch$ch/DAC/pins"
#     wvCollapseGroup -win $nw "dc/ch$ch/DAC/regs"
#     wvCollapseGroup -win $nw "dc/ch$ch/DAC/v"
#     wvCollapseGroup -win $nw "dc/ch$ch/DAC"
#
#     wvCollapseGroup -win $nw "dc/ch$ch"
#
# }
#
# wvCollapseGroup -win $nw "dc"

for {set ch 5} {$ch >= 0} {incr ch -1} {
    wvSelectGroup -win $nw {rf}
    wvAddSubGroup -win $nw "ch$ch"

    wvSelectGroup -win $nw "rf/ch$ch"
    wvAddSubGroup -win $nw "DAC"
    wvAddSubGroup -win $nw "CTRL"
    wvAddSubGroup -win $nw "CORE"
    wvAddSubGroup -win $nw "SEQ"
    wvAddSubGroup -win $nw "AXIL_REGS"

    # AXIL REGS
    wvSelectGroup -win $nw "rf/ch$ch/AXIL_REGS"
    wvAddSubGroup -win $nw "r"
    wvAddSubGroup -win $nw "ar"
    wvAddSubGroup -win $nw "b"
    wvAddSubGroup -win $nw "w"
    wvAddSubGroup -win $nw "aw"

    wvSetPosition -win $nw [format {("rf/ch%d/AXIL_REGS" 0)} $ch]
    wvAddSignal -win $nw "/simulator/RF_IO_GEN\[$ch\]/REGS/AXIL_REGS/i_aclk" \
                         "/simulator/RF_IO_GEN\[$ch\]/REGS/AXIL_REGS/i_aresetn" \
                         "/simulator/RF_IO_GEN\[$ch\]/REGS/AXIL_REGS/r_regs" \
                         "/simulator/RF_IO_GEN\[$ch\]/REGS/AXIL_REGS/o_regs"

    wvSetPosition -win $nw [format {("rf/ch%d/AXIL_REGS/aw" 0)} $ch]
    wvAddSignal -win $nw "/simulator/RF_IO_GEN\[$ch\]/REGS/AXIL_REGS/o_awready" \
                         "/simulator/RF_IO_GEN\[$ch\]/REGS/AXIL_REGS/i_awvalid" \
                         "/simulator/RF_IO_GEN\[$ch\]/REGS/AXIL_REGS/i_awaddr" \
                         "/simulator/RF_IO_GEN\[$ch\]/REGS/AXIL_REGS/w_awireg" \
                         "/simulator/RF_IO_GEN\[$ch\]/REGS/AXIL_REGS/w_awls2b"

    wvSetPosition -win $nw [format {("rf/ch%d/AXIL_REGS/w" 0)} $ch]
    wvAddSignal -win $nw "/simulator/RF_IO_GEN\[$ch\]/REGS/AXIL_REGS/o_wready" \
                         "/simulator/RF_IO_GEN\[$ch\]/REGS/AXIL_REGS/i_wvalid" \
                         "/simulator/RF_IO_GEN\[$ch\]/REGS/AXIL_REGS/i_wdata" \
                         "/simulator/RF_IO_GEN\[$ch\]/REGS/AXIL_REGS/i_wstrb" \
                         "/simulator/RF_IO_GEN\[$ch\]/REGS/AXIL_REGS/w_wdatastrb"

    wvSetPosition -win $nw [format {("rf/ch%d/AXIL_REGS/b" 0)} $ch]
    wvAddSignal -win $nw "/simulator/RF_IO_GEN\[$ch\]/REGS/AXIL_REGS/i_bready" \
                         "/simulator/RF_IO_GEN\[$ch\]/REGS/AXIL_REGS/o_bvalid" \
                         "/simulator/RF_IO_GEN\[$ch\]/REGS/AXIL_REGS/o_bresp"

    wvSetPosition -win $nw [format {("rf/ch%d/AXIL_REGS/ar" 0)} $ch]
    wvAddSignal -win $nw "/simulator/RF_IO_GEN\[$ch\]/REGS/AXIL_REGS/o_arready" \
                         "/simulator/RF_IO_GEN\[$ch\]/REGS/AXIL_REGS/i_arvalid" \
                         "/simulator/RF_IO_GEN\[$ch\]/REGS/AXIL_REGS/i_araddr" \
                         "/simulator/RF_IO_GEN\[$ch\]/REGS/AXIL_REGS/w_arireg" \
                         "/simulator/RF_IO_GEN\[$ch\]/REGS/AXIL_REGS/w_arls2b"

    wvSetPosition -win $nw [format {("rf/ch%d/AXIL_REGS/r" 0)} $ch]
    wvAddSignal -win $nw "/simulator/RF_IO_GEN\[$ch\]/REGS/AXIL_REGS/i_rready" \
                         "/simulator/RF_IO_GEN\[$ch\]/REGS/AXIL_REGS/o_rvalid" \
                         "/simulator/RF_IO_GEN\[$ch\]/REGS/AXIL_REGS/o_rdata" \
                         "/simulator/RF_IO_GEN\[$ch\]/REGS/AXIL_REGS/o_rresp"

    # SEQ
    wvSelectGroup -win $nw "rf/ch$ch/SEQ"
    wvAddSubGroup -win $nw "out"
    wvAddSubGroup -win $nw "fetch"
    wvAddSubGroup -win $nw "new"

    wvSetPosition -win $nw [format {("rf/ch%d/SEQ" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/SEQ/i_clk" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/SEQ/i_rst" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/SEQ/w_propagate"

    wvSetPosition -win $nw [format {("rf/ch%d/SEQ/new" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/SEQ/i_regs" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/SEQ/w_last0" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/SEQ/w_last0_ff1" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/SEQ/w_last0_ff2" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/SEQ/w_new_sequence" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/SEQ/i_uregs" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/SEQ/w_ulast0" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/SEQ/w_ulast0_ff1" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/SEQ/w_ulast0_ff2" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/SEQ/w_new_usequence"

    wvSetPosition -win $nw [format {("rf/ch%d/SEQ/fetch" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/SEQ/r_sequence" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/SEQ/r_iters" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/SEQ/r_iptr" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/SEQ/w_insn_fetch" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/SEQ/w_insn_bubble" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/SEQ/w_iptr_plus1" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/SEQ/w_next_null"

    wvSetPosition -win $nw [format {("rf/ch%d/SEQ/out" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/SEQ/o_empty" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/SEQ/i_next" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/SEQ/o_addr" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/SEQ/o_insn" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/SEQ/r_iptr_modify" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/SEQ/i_insn_modified"

    # CORE
    wvSelectGroup -win $nw "rf/ch$ch/CORE"
    wvAddSubGroup -win $nw "out"
    wvAddSubGroup -win $nw "result"

    for {set i 15} {$i >= 0} {incr i -1} {
        wvSelectGroup -win $nw "rf/ch$ch/CORE"
        wvAddSubGroup -win $nw "cordic$i"
        wvSetPosition -win $nw [format {("rf/ch%d/CORE/cordic%d" 0)} $ch $i]
        wvAddSignal -win $nw "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/CORE/CORDIC_GEN\[0\]/CORDIC/c\[$i\]" \
                             "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/CORE/CORDIC_GEN\[1\]/CORDIC/c\[$i\]" \
                             "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/CORE/CORDIC_GEN\[2\]/CORDIC/c\[$i\]" \
                             "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/CORE/CORDIC_GEN\[3\]/CORDIC/c\[$i\]" \
                             "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/CORE/CORDIC_GEN\[4\]/CORDIC/c\[$i\]" \
                             "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/CORE/CORDIC_GEN\[5\]/CORDIC/c\[$i\]" \
                             "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/CORE/CORDIC_GEN\[6\]/CORDIC/c\[$i\]" \
                             "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/CORE/CORDIC_GEN\[7\]/CORDIC/c\[$i\]"
    }

    wvSelectGroup -win $nw "rf/ch$ch/CORE"
    wvAddSubGroup -win $nw "phase"
    wvAddSubGroup -win $nw "decode"

    wvSetPosition -win $nw [format {("rf/ch%d/CORE" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/CORE/i_clk" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/CORE/i_rst" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/CORE/w_stall" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/CORE/o_empty" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/CORE/i_ctrl"

    wvSetPosition -win $nw [format {("rf/ch%d/CORE/decode" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/CORE/d" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/CORE/i_empty" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/CORE/o_next" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/CORE/i_addr" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/CORE/i_insn" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/CORE/o_insn_modified"

    wvSetPosition -win $nw [format {("rf/ch%d/CORE/phase" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/CORE/p" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/CORE/w_new_phase"

    wvSetPosition -win $nw [format {("rf/ch%d/CORE/result" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/CORE/r" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/CORE/w_addr" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/CORE/w_sample_start" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/CORE/w_sample_end" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/CORE/w_QIx8" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/CORE/o_armed" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/CORE/i_start"

    wvSetPosition -win $nw [format {("rf/ch%d/CORE/out" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/CORE/o" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/CORE/o_QIx8" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/CORE/o_eop"

    # CTRL
    wvSelectGroup -win $nw "rf/ch$ch/CTRL"
    wvAddSubGroup -win $nw "update"
    wvAddSubGroup -win $nw "new"

    wvSelectGroup -win $nw "rf/ch$ch/CTRL/update"
    wvAddSubGroup -win $nw "fsm"
    wvAddSubGroup -win $nw "nco"

    wvSetPosition -win $nw [format {("rf/ch%d/CTRL" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/CTRL/o_ctrl" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/CTRL/r_default_I" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/CTRL/r_default_Q"

    wvSetPosition -win $nw [format {("rf/ch%d/CTRL/new" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/CTRL/i_regs" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/CTRL/w_last0" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/CTRL/w_last0_ff1" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/CTRL/w_last0_ff2" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/CTRL/w_new_ctrl" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/CTRL/i_uregs" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/CTRL/w_ulast0" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/CTRL/w_ulast0_ff1" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/CTRL/w_ulast0_ff2" \
                         "/simulator/DCRFLI/RF_GEN\[$ch\]/RF/CTRL/w_new_uctrl"

    # DAC
    wvSelectGroup -win $nw "rf/ch$ch/DAC"
    wvAddSubGroup -win $nw "update"
    wvAddSubGroup -win $nw "v"

    wvSelectGroup -win $nw "rf/ch$ch/DAC/update"
    wvAddSubGroup -win $nw "loop"

    wvSetPosition -win $nw [format {("rf/ch%d/DAC" 0)} $ch]
    wvAddSignal -win $nw "/simulator/RF_IO_GEN\[$ch\]/DAC/i_clk" \
                         "/simulator/RF_IO_GEN\[$ch\]/DAC/i_dac_clk" \
                         "/simulator/RF_IO_GEN\[$ch\]/DAC/dac_cycle" \
                         "/simulator/RF_IO_GEN\[$ch\]/DAC/i_QIx8"

    wvSetPosition -win $nw [format {("rf/ch%d/DAC/v" 0)} $ch]
    wvAddSignal -win $nw "/simulator/RF_IO_GEN\[$ch\]/DAC/w_Ix8" \
                         "/simulator/RF_IO_GEN\[$ch\]/DAC/w_Qx8" \
                         "/simulator/RF_IO_GEN\[$ch\]/DAC/o_I" \
                         "/simulator/RF_IO_GEN\[$ch\]/DAC/o_Q" \
                         "/simulator/RF_IO_GEN\[$ch\]/DAC/I" \
                         "/simulator/RF_IO_GEN\[$ch\]/DAC/Q" \
                         "/simulator/RF_IO_GEN\[$ch\]/DAC/deg" \
                         "/simulator/RF_IO_GEN\[$ch\]/DAC/rad" \
                         "/simulator/RF_IO_GEN\[$ch\]/DAC/nco_i" \
                         "/simulator/RF_IO_GEN\[$ch\]/DAC/nco_q" \
                         "/simulator/RF_IO_GEN\[$ch\]/DAC/o_vrf"

    wvSetPosition -win $nw [format {("rf/ch%d/DAC/update" 0)} $ch]
    wvAddSignal -win $nw "/simulator/RF_IO_GEN\[$ch\]/DAC/i_nco_req" \
                         "/simulator/RF_IO_GEN\[$ch\]/DAC/o_nco_busy" \
                         "/simulator/RF_IO_GEN\[$ch\]/DAC/i_nco_freq" \
                         "/simulator/RF_IO_GEN\[$ch\]/DAC/i_nco_phase" \
                         "/simulator/RF_IO_GEN\[$ch\]/DAC/i_nco_en" \
                         "/simulator/RF_IO_GEN\[$ch\]/DAC/freq" \
                         "/simulator/RF_IO_GEN\[$ch\]/DAC/phase" \
                         "/simulator/RF_IO_GEN\[$ch\]/DAC/en" \
                         "/simulator/RF_IO_GEN\[$ch\]/DAC/deg_incr"

    wvSetPosition -win $nw [format {("rf/ch%d/DAC/update/loop" 0)} $ch]
    wvAddSignal -win $nw "/simulator/RF_IO_GEN\[$ch\]/DAC/state" \
                         "/simulator/RF_IO_GEN\[$ch\]/DAC/ifreq" \
                         "/simulator/RF_IO_GEN\[$ch\]/DAC/iphase" \
                         "/simulator/RF_IO_GEN\[$ch\]/DAC/ien" \
                         "/simulator/RF_IO_GEN\[$ch\]/DAC/hold_cycles" \
                         "/simulator/RF_IO_GEN\[$ch\]/DAC/busy_cycles"

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

    wvCollapseGroup -win $nw "rf/ch$ch/CTRL/update/nco"
    wvCollapseGroup -win $nw "rf/ch$ch/CTRL/update/fsm"
    wvCollapseGroup -win $nw "rf/ch$ch/CTRL/update"
    wvCollapseGroup -win $nw "rf/ch$ch/CTRL/new"
    wvCollapseGroup -win $nw "rf/ch$ch/CTRL"

    wvCollapseGroup -win $nw "rf/ch$ch/DAC/update/loop"
    wvCollapseGroup -win $nw "rf/ch$ch/DAC/update"
    wvCollapseGroup -win $nw "rf/ch$ch/DAC/v"
    wvCollapseGroup -win $nw "rf/ch$ch/DAC"

    wvCollapseGroup -win $nw "rf/ch$ch"

}

wvCollapseGroup -win $nw "rf"

# li
for {set ch 1} {$ch >= 0} {incr ch -1} {

    wvSelectGroup -win $nw {li}
    wvAddSubGroup -win $nw "ch$ch"

    wvSelectGroup -win $nw "li/ch$ch"
    wvAddSubGroup -win $nw "ADC"
    wvAddSubGroup -win $nw "CTRL"
    wvAddSubGroup -win $nw "CORE"
    wvAddSubGroup -win $nw "SEQ"
    wvAddSubGroup -win $nw "AXIL_REGS"

    # AXIL REGS
    wvSelectGroup -win $nw "li/ch$ch/AXIL_REGS"
    wvAddSubGroup -win $nw "r"
    wvAddSubGroup -win $nw "ar"
    wvAddSubGroup -win $nw "b"
    wvAddSubGroup -win $nw "w"
    wvAddSubGroup -win $nw "aw"

    wvSetPosition -win $nw [format {("li/ch%d/AXIL_REGS" 0)} $ch]
    wvAddSignal -win $nw "/simulator/LI_IO_GEN\[$ch\]/REGS/AXIL_REGS/i_aclk" \
                         "/simulator/LI_IO_GEN\[$ch\]/REGS/AXIL_REGS/i_aresetn" \
                         "/simulator/LI_IO_GEN\[$ch\]/REGS/AXIL_REGS/r_regs" \
                         "/simulator/LI_IO_GEN\[$ch\]/REGS/AXIL_REGS/o_regs"

    wvSetPosition -win $nw [format {("li/ch%d/AXIL_REGS/aw" 0)} $ch]
    wvAddSignal -win $nw "/simulator/LI_IO_GEN\[$ch\]/REGS/AXIL_REGS/o_awready" \
                         "/simulator/LI_IO_GEN\[$ch\]/REGS/AXIL_REGS/i_awvalid" \
                         "/simulator/LI_IO_GEN\[$ch\]/REGS/AXIL_REGS/i_awaddr" \
                         "/simulator/LI_IO_GEN\[$ch\]/REGS/AXIL_REGS/w_awireg" \
                         "/simulator/LI_IO_GEN\[$ch\]/REGS/AXIL_REGS/w_awls2b"

    wvSetPosition -win $nw [format {("li/ch%d/AXIL_REGS/w" 0)} $ch]
    wvAddSignal -win $nw "/simulator/LI_IO_GEN\[$ch\]/REGS/AXIL_REGS/o_wready" \
                         "/simulator/LI_IO_GEN\[$ch\]/REGS/AXIL_REGS/i_wvalid" \
                         "/simulator/LI_IO_GEN\[$ch\]/REGS/AXIL_REGS/i_wdata" \
                         "/simulator/LI_IO_GEN\[$ch\]/REGS/AXIL_REGS/i_wstrb" \
                         "/simulator/LI_IO_GEN\[$ch\]/REGS/AXIL_REGS/w_wdatastrb"

    wvSetPosition -win $nw [format {("li/ch%d/AXIL_REGS/b" 0)} $ch]
    wvAddSignal -win $nw "/simulator/LI_IO_GEN\[$ch\]/REGS/AXIL_REGS/i_bready" \
                         "/simulator/LI_IO_GEN\[$ch\]/REGS/AXIL_REGS/o_bvalid" \
                         "/simulator/LI_IO_GEN\[$ch\]/REGS/AXIL_REGS/o_bresp"

    wvSetPosition -win $nw [format {("li/ch%d/AXIL_REGS/ar" 0)} $ch]
    wvAddSignal -win $nw "/simulator/LI_IO_GEN\[$ch\]/REGS/AXIL_REGS/o_arready" \
                         "/simulator/LI_IO_GEN\[$ch\]/REGS/AXIL_REGS/i_arvalid" \
                         "/simulator/LI_IO_GEN\[$ch\]/REGS/AXIL_REGS/i_araddr" \
                         "/simulator/LI_IO_GEN\[$ch\]/REGS/AXIL_REGS/w_arireg" \
                         "/simulator/LI_IO_GEN\[$ch\]/REGS/AXIL_REGS/w_arls2b"

    wvSetPosition -win $nw [format {("li/ch%d/AXIL_REGS/r" 0)} $ch]
    wvAddSignal -win $nw "/simulator/LI_IO_GEN\[$ch\]/REGS/AXIL_REGS/i_rready" \
                         "/simulator/LI_IO_GEN\[$ch\]/REGS/AXIL_REGS/o_rvalid" \
                         "/simulator/LI_IO_GEN\[$ch\]/REGS/AXIL_REGS/o_rdata" \
                         "/simulator/LI_IO_GEN\[$ch\]/REGS/AXIL_REGS/o_rresp"

    # SEQ
    wvSelectGroup -win $nw "li/ch$ch/SEQ"
    wvAddSubGroup -win $nw "out"
    wvAddSubGroup -win $nw "fetch"
    wvAddSubGroup -win $nw "new"

    wvSetPosition -win $nw [format {("li/ch%d/SEQ" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/SEQ/i_clk" \
                         "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/SEQ/i_rst" \
                         "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/SEQ/w_propagate"

    wvSetPosition -win $nw [format {("li/ch%d/SEQ/new" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/SEQ/i_regs" \
                         "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/SEQ/w_last0" \
                         "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/SEQ/w_last0_ff1" \
                         "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/SEQ/w_last0_ff2" \
                         "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/SEQ/w_new_sequence" \
                         "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/SEQ/i_uregs" \
                         "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/SEQ/w_ulast0" \
                         "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/SEQ/w_ulast0_ff1" \
                         "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/SEQ/w_ulast0_ff2" \
                         "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/SEQ/w_new_usequence"

    wvSetPosition -win $nw [format {("li/ch%d/SEQ/fetch" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/SEQ/r_sequence" \
                         "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/SEQ/r_iters" \
                         "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/SEQ/r_iptr" \
                         "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/SEQ/w_insn_fetch" \
                         "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/SEQ/w_insn_bubble" \
                         "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/SEQ/w_iptr_plus1" \
                         "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/SEQ/w_next_null"

    wvSetPosition -win $nw [format {("li/ch%d/SEQ/out" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/SEQ/o_empty" \
                         "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/SEQ/i_next" \
                         "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/SEQ/o_addr" \
                         "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/SEQ/o_insn" \
                         "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/SEQ/r_iptr_modify" \
                         "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/SEQ/i_insn_modified"

    # CORE
    wvSelectGroup -win $nw "li/ch$ch/CORE"
    wvAddSubGroup -win $nw "out"
    wvAddSubGroup -win $nw "buffer"
    wvAddSubGroup -win $nw "align"
    wvAddSubGroup -win $nw "pack"
    wvAddSubGroup -win $nw "sample"
    wvAddSubGroup -win $nw "decode"

    wvSetPosition -win $nw [format {("li/ch%d/CORE" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/CORE/i_clk" \
                         "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/CORE/i_rst" \
                         "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/CORE/w_stall" \
                         "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/CORE/o_empty"

    wvSetPosition -win $nw [format {("li/ch%d/CORE/decode" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/CORE/d" \
                         "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/CORE/i_empty" \
                         "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/CORE/o_next" \
                         "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/CORE/i_addr" \
                         "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/CORE/i_insn" \
                         "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/CORE/o_insn_modified" \
                         "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/CORE/o_armed" \
                         "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/CORE/i_start"

    wvSetPosition -win $nw [format {("li/ch%d/CORE/sample" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/CORE/s" \
                         "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/CORE/i_QIx4" \
                         "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/CORE/o_sample_mask"

    wvSetPosition -win $nw [format {("li/ch%d/CORE/pack" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/CORE/p"

    wvSetPosition -win $nw [format {("li/ch%d/CORE/align" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/CORE/a"

    wvSetPosition -win $nw [format {("li/ch%d/CORE/buffer" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/CORE/b"

    wvSetPosition -win $nw [format {("li/ch%d/CORE/out" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/CORE/o" \
                         "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/CORE/o_QIx4" \
                         "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/CORE/o_validx4" \
                         "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/CORE/o_last" \
                         "/simulator/DCRFLI/LI_GEN\[$ch\]/LI/CORE/o_eop"

    # CTRL
    wvSelectGroup -win $nw "li/ch$ch/CTRL"

    # ADC
    wvSelectGroup -win $nw "li/ch$ch/ADC"

    wvSetPosition -win $nw [format {("li/ch%d/ADC" 0)} $ch]
    wvAddSignal -win $nw "/simulator/LI_IO_GEN\[$ch\]/ADC/i_clk" \
                         "/simulator/LI_IO_GEN\[$ch\]/ADC/i_adc_clk" \
                         "/simulator/LI_IO_GEN\[$ch\]/ADC/adc_cycle" \
                         "/simulator/LI_IO_GEN\[$ch\]/ADC/i_vli" \
                         "/simulator/LI_IO_GEN\[$ch\]/ADC/o_QIx4" \
                         "/simulator/LI_IO_GEN\[$ch\]/ADC/i_sample_mask" \
                         "/simulator/LI_IO_GEN\[$ch\]/ADC/r_sample_mask" \
                         "/simulator/LI_IO_GEN\[$ch\]/ADC/o_sample_spike" \
                         "/simulator/LI_IO_GEN\[$ch\]/ADC/s"

}

for {set ch 1} {$ch >= 0} {incr ch -1} {

    wvCollapseGroup -win $nw "li/ch$ch/AXIL_REGS/aw"
    wvCollapseGroup -win $nw "li/ch$ch/AXIL_REGS/w"
    wvCollapseGroup -win $nw "li/ch$ch/AXIL_REGS/b"
    wvCollapseGroup -win $nw "li/ch$ch/AXIL_REGS/ar"
    wvCollapseGroup -win $nw "li/ch$ch/AXIL_REGS/r"
    wvCollapseGroup -win $nw "li/ch$ch/AXIL_REGS"

    wvCollapseGroup -win $nw "li/ch$ch/SEQ/new"
    wvCollapseGroup -win $nw "li/ch$ch/SEQ/fetch"
    wvCollapseGroup -win $nw "li/ch$ch/SEQ/out"
    wvCollapseGroup -win $nw "li/ch$ch/SEQ"

    wvCollapseGroup -win $nw "li/ch$ch/CORE/decode"
    wvCollapseGroup -win $nw "li/ch$ch/CORE/sample"
    wvCollapseGroup -win $nw "li/ch$ch/CORE/pack"
    wvCollapseGroup -win $nw "li/ch$ch/CORE/align"
    wvCollapseGroup -win $nw "li/ch$ch/CORE/buffer"
    wvCollapseGroup -win $nw "li/ch$ch/CORE/out"
    wvCollapseGroup -win $nw "li/ch$ch/CORE"

    wvCollapseGroup -win $nw "li/ch$ch/ADC"

    wvCollapseGroup -win $nw "li/ch$ch"

}

wvCollapseGroup -win $nw "li"

# ex
for {set ch 1} {$ch >= 0} {incr ch -1} {

    wvSelectGroup -win $nw {ex}
    wvAddSubGroup -win $nw "ch$ch"

    wvSelectGroup -win $nw "ex/ch$ch"
    wvAddSubGroup -win $nw "DAC"
    wvAddSubGroup -win $nw "CORE"
    wvAddSubGroup -win $nw "SEQ"
    wvAddSubGroup -win $nw "AXIL_REGS"

    # AXIL REGS
    wvSelectGroup -win $nw "ex/ch$ch/AXIL_REGS"
    wvAddSubGroup -win $nw "r"
    wvAddSubGroup -win $nw "ar"
    wvAddSubGroup -win $nw "b"
    wvAddSubGroup -win $nw "w"
    wvAddSubGroup -win $nw "aw"

    wvSetPosition -win $nw [format {("ex/ch%d/AXIL_REGS" 0)} $ch]
    wvAddSignal -win $nw "/simulator/EX_IO_GEN\[$ch\]/REGS/AXIL_REGS/i_aclk" \
                         "/simulator/EX_IO_GEN\[$ch\]/REGS/AXIL_REGS/i_aresetn" \
                         "/simulator/EX_IO_GEN\[$ch\]/REGS/AXIL_REGS/r_regs" \
                         "/simulator/EX_IO_GEN\[$ch\]/REGS/AXIL_REGS/o_regs"

    wvSetPosition -win $nw [format {("ex/ch%d/AXIL_REGS/aw" 0)} $ch]
    wvAddSignal -win $nw "/simulator/EX_IO_GEN\[$ch\]/REGS/AXIL_REGS/o_awready" \
                         "/simulator/EX_IO_GEN\[$ch\]/REGS/AXIL_REGS/i_awvalid" \
                         "/simulator/EX_IO_GEN\[$ch\]/REGS/AXIL_REGS/i_awaddr" \
                         "/simulator/EX_IO_GEN\[$ch\]/REGS/AXIL_REGS/w_awireg" \
                         "/simulator/EX_IO_GEN\[$ch\]/REGS/AXIL_REGS/w_awls2b"

    wvSetPosition -win $nw [format {("ex/ch%d/AXIL_REGS/w" 0)} $ch]
    wvAddSignal -win $nw "/simulator/EX_IO_GEN\[$ch\]/REGS/AXIL_REGS/o_wready" \
                         "/simulator/EX_IO_GEN\[$ch\]/REGS/AXIL_REGS/i_wvalid" \
                         "/simulator/EX_IO_GEN\[$ch\]/REGS/AXIL_REGS/i_wdata" \
                         "/simulator/EX_IO_GEN\[$ch\]/REGS/AXIL_REGS/i_wstrb" \
                         "/simulator/EX_IO_GEN\[$ch\]/REGS/AXIL_REGS/w_wdatastrb"

    wvSetPosition -win $nw [format {("ex/ch%d/AXIL_REGS/b" 0)} $ch]
    wvAddSignal -win $nw "/simulator/EX_IO_GEN\[$ch\]/REGS/AXIL_REGS/i_bready" \
                         "/simulator/EX_IO_GEN\[$ch\]/REGS/AXIL_REGS/o_bvalid" \
                         "/simulator/EX_IO_GEN\[$ch\]/REGS/AXIL_REGS/o_bresp"

    wvSetPosition -win $nw [format {("ex/ch%d/AXIL_REGS/ar" 0)} $ch]
    wvAddSignal -win $nw "/simulator/EX_IO_GEN\[$ch\]/REGS/AXIL_REGS/o_arready" \
                         "/simulator/EX_IO_GEN\[$ch\]/REGS/AXIL_REGS/i_arvalid" \
                         "/simulator/EX_IO_GEN\[$ch\]/REGS/AXIL_REGS/i_araddr" \
                         "/simulator/EX_IO_GEN\[$ch\]/REGS/AXIL_REGS/w_arireg" \
                         "/simulator/EX_IO_GEN\[$ch\]/REGS/AXIL_REGS/w_arls2b"

    wvSetPosition -win $nw [format {("ex/ch%d/AXIL_REGS/r" 0)} $ch]
    wvAddSignal -win $nw "/simulator/EX_IO_GEN\[$ch\]/REGS/AXIL_REGS/i_rready" \
                         "/simulator/EX_IO_GEN\[$ch\]/REGS/AXIL_REGS/o_rvalid" \
                         "/simulator/EX_IO_GEN\[$ch\]/REGS/AXIL_REGS/o_rdata" \
                         "/simulator/EX_IO_GEN\[$ch\]/REGS/AXIL_REGS/o_rresp"

    # SEQ
    wvSelectGroup -win $nw "ex/ch$ch/SEQ"
    wvAddSubGroup -win $nw "out"
    wvAddSubGroup -win $nw "fetch"
    wvAddSubGroup -win $nw "new"

    wvSetPosition -win $nw [format {("ex/ch%d/SEQ" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DCRFLI/EX_GEN\[$ch\]/EX/SEQ/i_clk" \
                         "/simulator/DCRFLI/EX_GEN\[$ch\]/EX/SEQ/i_rst" \
                         "/simulator/DCRFLI/EX_GEN\[$ch\]/EX/SEQ/w_propagate"

    wvSetPosition -win $nw [format {("ex/ch%d/SEQ/new" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DCRFLI/EX_GEN\[$ch\]/EX/SEQ/i_regs" \
                         "/simulator/DCRFLI/EX_GEN\[$ch\]/EX/SEQ/w_last0" \
                         "/simulator/DCRFLI/EX_GEN\[$ch\]/EX/SEQ/w_last0_ff1" \
                         "/simulator/DCRFLI/EX_GEN\[$ch\]/EX/SEQ/w_last0_ff2" \
                         "/simulator/DCRFLI/EX_GEN\[$ch\]/EX/SEQ/w_new_sequence" \
                         "/simulator/DCRFLI/EX_GEN\[$ch\]/EX/SEQ/i_uregs" \
                         "/simulator/DCRFLI/EX_GEN\[$ch\]/EX/SEQ/w_ulast0" \
                         "/simulator/DCRFLI/EX_GEN\[$ch\]/EX/SEQ/w_ulast0_ff1" \
                         "/simulator/DCRFLI/EX_GEN\[$ch\]/EX/SEQ/w_ulast0_ff2" \
                         "/simulator/DCRFLI/EX_GEN\[$ch\]/EX/SEQ/w_new_usequence"

    wvSetPosition -win $nw [format {("ex/ch%d/SEQ/fetch" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DCRFLI/EX_GEN\[$ch\]/EX/SEQ/r_sequence" \
                         "/simulator/DCRFLI/EX_GEN\[$ch\]/EX/SEQ/r_iters" \
                         "/simulator/DCRFLI/EX_GEN\[$ch\]/EX/SEQ/r_iptr" \
                         "/simulator/DCRFLI/EX_GEN\[$ch\]/EX/SEQ/w_insn_fetch" \
                         "/simulator/DCRFLI/EX_GEN\[$ch\]/EX/SEQ/w_insn_bubble" \
                         "/simulator/DCRFLI/EX_GEN\[$ch\]/EX/SEQ/w_iptr_plus1" \
                         "/simulator/DCRFLI/EX_GEN\[$ch\]/EX/SEQ/w_next_null"

    wvSetPosition -win $nw [format {("ex/ch%d/SEQ/out" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DCRFLI/EX_GEN\[$ch\]/EX/SEQ/o_empty" \
                         "/simulator/DCRFLI/EX_GEN\[$ch\]/EX/SEQ/i_next" \
                         "/simulator/DCRFLI/EX_GEN\[$ch\]/EX/SEQ/o_addr" \
                         "/simulator/DCRFLI/EX_GEN\[$ch\]/EX/SEQ/o_insn" \
                         "/simulator/DCRFLI/EX_GEN\[$ch\]/EX/SEQ/r_iptr_modify" \
                         "/simulator/DCRFLI/EX_GEN\[$ch\]/EX/SEQ/i_insn_modified"

    # CORE
    wvSelectGroup -win $nw "ex/ch$ch/CORE"
    wvAddSubGroup -win $nw "out"
    wvAddSubGroup -win $nw "count"
    wvAddSubGroup -win $nw "decode"

    wvSetPosition -win $nw [format {("ex/ch%d/CORE" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DCRFLI/EX_GEN\[$ch\]/EX/CORE/i_clk" \
                         "/simulator/DCRFLI/EX_GEN\[$ch\]/EX/CORE/i_rst" \
                         "/simulator/DCRFLI/EX_GEN\[$ch\]/EX/CORE/w_stall" \
                         "/simulator/DCRFLI/EX_GEN\[$ch\]/EX/CORE/o_empty"

    wvSetPosition -win $nw [format {("ex/ch%d/CORE/decode" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DCRFLI/EX_GEN\[$ch\]/EX/CORE/d" \
                         "/simulator/DCRFLI/EX_GEN\[$ch\]/EX/CORE/i_empty" \
                         "/simulator/DCRFLI/EX_GEN\[$ch\]/EX/CORE/o_next" \
                         "/simulator/DCRFLI/EX_GEN\[$ch\]/EX/CORE/i_addr" \
                         "/simulator/DCRFLI/EX_GEN\[$ch\]/EX/CORE/i_insn" \
                         "/simulator/DCRFLI/EX_GEN\[$ch\]/EX/CORE/o_insn_modified" \
                         "/simulator/DCRFLI/EX_GEN\[$ch\]/EX/CORE/i_start"

    wvSetPosition -win $nw [format {("ex/ch%d/CORE/count" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DCRFLI/EX_GEN\[$ch\]/EX/CORE/c"

    wvSetPosition -win $nw [format {("ex/ch%d/CORE/out" 0)} $ch]
    wvAddSignal -win $nw "/simulator/DCRFLI/EX_GEN\[$ch\]/EX/CORE/o" \
                         "/simulator/DCRFLI/EX_GEN\[$ch\]/EX/CORE/o_realx16" \
                         "/simulator/DCRFLI/EX_GEN\[$ch\]/EX/CORE/o_eop"

    # DAC
    wvSelectGroup -win $nw "ex/ch$ch/DAC"

    wvSetPosition -win $nw [format {("ex/ch%d/DAC" 0)} $ch]
    wvAddSignal -win $nw "/simulator/EX_IO_GEN\[$ch\]/DAC/i_clk" \
                         "/simulator/EX_IO_GEN\[$ch\]/DAC/i_dac_clk" \
                         "/simulator/EX_IO_GEN\[$ch\]/DAC/dac_cycle" \
                         "/simulator/EX_IO_GEN\[$ch\]/DAC/i_realx16" \
                         "/simulator/EX_IO_GEN\[$ch\]/DAC/w_realx16" \
                         "/simulator/EX_IO_GEN\[$ch\]/DAC/o_vex"

}

for {set ch 1} {$ch >= 0} {incr ch -1} {

    wvCollapseGroup -win $nw "ex/ch$ch/AXIL_REGS/aw"
    wvCollapseGroup -win $nw "ex/ch$ch/AXIL_REGS/w"
    wvCollapseGroup -win $nw "ex/ch$ch/AXIL_REGS/b"
    wvCollapseGroup -win $nw "ex/ch$ch/AXIL_REGS/ar"
    wvCollapseGroup -win $nw "ex/ch$ch/AXIL_REGS/r"
    wvCollapseGroup -win $nw "ex/ch$ch/AXIL_REGS"

    wvCollapseGroup -win $nw "ex/ch$ch/SEQ/new"
    wvCollapseGroup -win $nw "ex/ch$ch/SEQ/fetch"
    wvCollapseGroup -win $nw "ex/ch$ch/SEQ/out"
    wvCollapseGroup -win $nw "ex/ch$ch/SEQ"

    wvCollapseGroup -win $nw "ex/ch$ch/CORE/decode"
    wvCollapseGroup -win $nw "ex/ch$ch/CORE/count"
    wvCollapseGroup -win $nw "ex/ch$ch/CORE/out"
    wvCollapseGroup -win $nw "ex/ch$ch/CORE"

    wvCollapseGroup -win $nw "ex/ch$ch/DAC"

    wvCollapseGroup -win $nw "ex/ch$ch"

}

wvCollapseGroup -win $nw "ex"

wvAddGroup -win $nw {btn}

wvSetPosition -win $nw {("btn" 0)}
wvAddSignal -win $nw "simulator/DCRFLI/BTN/i_clk" \
                     "simulator/DCRFLI/BTN/i_rst" \
                     "simulator/DCRFLI/BTN/i_btn\[0\]" \
                     "simulator/DCRFLI/BTN/w_btn_steady\[0\]" \
                     "simulator/DCRFLI/BTN/r_ff1\[0\]" \
                     "simulator/DCRFLI/BTN/r_ff2\[0\]" \
                     "simulator/DCRFLI/BTN/o_pressed\[0\]" \

wvCollapseGroup -win $nw "btn"

