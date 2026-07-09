set nw [wvCreateWindow]
wvRenameGroup -win $nw {G1} {dc}

wvSelectGroup -win $nw {dc}
wvAddSubGroup -win $nw "DAC"
wvAddSubGroup -win $nw "CTRL"
wvAddSubGroup -win $nw "CORE"
wvAddSubGroup -win $nw "SEQ"

# SEQ -- bram_sequencer's three pipeline stages: pc stage (p), insn stage
# (i, PCMEM lookup), out stage (o, IMEM lookup)
wvSelectGroup -win $nw "dc/SEQ"
wvAddSubGroup -win $nw "out"
wvAddSubGroup -win $nw "insn"
wvAddSubGroup -win $nw "pc"

wvSetPosition -win $nw {("dc/SEQ" 0)}
wvAddSignal -win $nw "/dc_tb/DUT/SEQ/i_clk" \
                     "/dc_tb/DUT/SEQ/i_rst" \
                     "/dc_tb/DUT/SEQ/i_regs" \
                     "/dc_tb/DUT/SEQ/w_propagate"

wvSetPosition -win $nw {("dc/SEQ/pc" 0)}
wvAddSignal -win $nw "/dc_tb/DUT/SEQ/p" \
                     "/dc_tb/DUT/SEQ/w_iters" \
                     "/dc_tb/DUT/SEQ/w_depth" \
                     "/dc_tb/DUT/SEQ/w_start_strb" \
                     "/dc_tb/DUT/SEQ/w_halt_strb" \
                     "/dc_tb/DUT/SEQ/o_active" \
                     "/dc_tb/DUT/SEQ/o_iters" \
                     "/dc_tb/DUT/SEQ/o_pcmem_depth"

wvSetPosition -win $nw {("dc/SEQ/insn" 0)}
wvAddSignal -win $nw "/dc_tb/DUT/SEQ/i" \
                     "/dc_tb/DUT/SEQ/w_pcmem_wr" \
                     "/dc_tb/DUT/SEQ/w_pcmem_wr_addr" \
                     "/dc_tb/DUT/SEQ/w_pcmem_wr_data" \
                     "/dc_tb/DUT/SEQ/w_pcmem_rd_addr" \
                     "/dc_tb/DUT/SEQ/w_pcld_strb" \
                     "/dc_tb/DUT/SEQ/w_pcld_rd" \
                     "/dc_tb/DUT/SEQ/o_pc_rd"

wvSetPosition -win $nw {("dc/SEQ/out" 0)}
wvAddSignal -win $nw "/dc_tb/DUT/SEQ/o" \
                     "/dc_tb/DUT/SEQ/w_imem_wr" \
                     "/dc_tb/DUT/SEQ/w_imem_wr_addr" \
                     "/dc_tb/DUT/SEQ/w_imem_wr_data" \
                     "/dc_tb/DUT/SEQ/w_imem_rd_addr" \
                     "/dc_tb/DUT/SEQ/w_ild_strb" \
                     "/dc_tb/DUT/SEQ/w_ild_rd" \
                     "/dc_tb/DUT/SEQ/i_next" \
                     "/dc_tb/DUT/SEQ/i_insn_modified" \
                     "/dc_tb/DUT/SEQ/o_pc_addr" \
                     "/dc_tb/DUT/SEQ/o_pc" \
                     "/dc_tb/DUT/SEQ/o_insn" \
                     "/dc_tb/DUT/SEQ/o_insn_rd" \
                     "/dc_tb/DUT/SEQ/o_empty"

# CORE
wvSelectGroup -win $nw "dc/CORE"
wvAddSubGroup -win $nw "hold"
wvAddSubGroup -win $nw "spi"
wvAddSubGroup -win $nw "iterate"
wvAddSubGroup -win $nw "decode"

wvSetPosition -win $nw {("dc/CORE" 0)}
wvAddSignal -win $nw "/dc_tb/DUT/CORE/i_clk" \
                     "/dc_tb/DUT/CORE/i_rst" \
                     "/dc_tb/DUT/CORE/w_propagate_i2s" \
                     "/dc_tb/DUT/CORE/w_propagate_s2h" \
                     "/dc_tb/DUT/CORE/o_empty" \
                     "/dc_tb/DUT/CORE/i_ctrl"

wvSetPosition -win $nw {("dc/CORE/decode" 0)}
wvAddSignal -win $nw "/dc_tb/DUT/CORE/d" \
                     "/dc_tb/DUT/CORE/i_empty" \
                     "/dc_tb/DUT/CORE/o_next" \
                     "/dc_tb/DUT/CORE/i_addr" \
                     "/dc_tb/DUT/CORE/i_insn" \
                     "/dc_tb/DUT/CORE/o_insn_modified"

wvSetPosition -win $nw {("dc/CORE/iterate" 0)}
wvAddSignal -win $nw "/dc_tb/DUT/CORE/i"

wvSetPosition -win $nw {("dc/CORE/spi" 0)}
wvAddSignal -win $nw "/dc_tb/DUT/CORE/s" \
                     "/dc_tb/DUT/CORE/w_spi_dout" \
                     "/dc_tb/DUT/CORE/w_spi_done" \
                     "/dc_tb/DUT/CORE/o_armed" \
                     "/dc_tb/DUT/CORE/i_start" \
                     "/dc_tb/DUT/CORE/o_marker"

wvSelectGroup -win $nw "dc/CORE/spi"
wvAddSubGroup -win $nw "wires"
wvSetPosition -win $nw {("dc/CORE/spi/wires" 0)}
wvAddSignal -win $nw "/dc_tb/DUT/CORE/o_sclk" \
                     "/dc_tb/DUT/CORE/o_mosi" \
                     "/dc_tb/DUT/CORE/i_miso" \
                     "/dc_tb/DUT/CORE/o_cs_n" \
                     "/dc_tb/DUT/CORE/o_ldac_n"

wvSetPosition -win $nw {("dc/CORE/hold" 0)}
wvAddSignal -win $nw "/dc_tb/DUT/CORE/h" \
                     "/dc_tb/DUT/CORE/o_eop"

# CTRL
wvSelectGroup -win $nw "dc/CTRL"

wvSetPosition -win $nw {("dc/CTRL" 0)}
wvAddSignal -win $nw "/dc_tb/DUT/CTRL/i_clk" \
                     "/dc_tb/DUT/CTRL/i_rst" \
                     "/dc_tb/DUT/CTRL/i_regs" \
                     "/dc_tb/DUT/CTRL/w_new_ctrl" \
                     "/dc_tb/DUT/CTRL/o_ctrl" \
                     "/dc_tb/DUT/CTRL/r_dvsr" \
                     "/dc_tb/DUT/CTRL/r_cs_up_cycles" \
                     "/dc_tb/DUT/CTRL/r_ldac_cycles"

# DAC
wvSelectGroup -win $nw "dc/DAC"
wvAddSubGroup -win $nw "v"
wvAddSubGroup -win $nw "regs"
wvAddSubGroup -win $nw "pins"

wvSetPosition -win $nw {("dc/DAC" 0)}
wvAddSignal -win $nw "/dc_tb/DAC/valid_transaction" \
                     "/dc_tb/DAC/input_shift_reg" \
                     "/dc_tb/DAC/rw" \
                     "/dc_tb/DAC/addr" \
                     "/dc_tb/DAC/data" \
                     "/dc_tb/DAC/rd_data"

wvSetPosition -win $nw {("dc/DAC/pins" 0)}
wvAddSignal -win $nw "/dc_tb/DAC/SCLK" \
                     "/dc_tb/DAC/SDIN" \
                     "/dc_tb/DAC/SYNC_N" \
                     "/dc_tb/DAC/SDO" \
                     "/dc_tb/DAC/LDAC_N" \
                     "/dc_tb/DAC/CLR_N" \
                     "/dc_tb/DAC/RESET_N"

wvSetPosition -win $nw {("dc/DAC/regs" 0)}
wvAddSignal -win $nw "/dc_tb/DAC/dac_reg" \
                     "/dc_tb/DAC/ctrl_reg" \
                     "/dc_tb/DAC/clrcode_reg" \
                     "/dc_tb/DAC/sw_ctrl_reg" \
                     "/dc_tb/DAC/dac_input_reg" \
                     "/dc_tb/DAC/SDODIS" \
                     "/dc_tb/DAC/DACTRI" \
                     "/dc_tb/DAC/OPGND"

wvSetPosition -win $nw {("dc/DAC/v" 0)}
wvAddSignal -win $nw "/dc_tb/DAC/VOUT" \
                     "/dc_tb/DAC/VDIGITAL"

wvCollapseGroup -win $nw "dc/SEQ/pc"
wvCollapseGroup -win $nw "dc/SEQ/insn"
wvCollapseGroup -win $nw "dc/SEQ/out"
wvCollapseGroup -win $nw "dc/SEQ"

wvCollapseGroup -win $nw "dc/CORE/decode"
wvCollapseGroup -win $nw "dc/CORE/iterate"
wvCollapseGroup -win $nw "dc/CORE/spi/wires"
wvCollapseGroup -win $nw "dc/CORE/spi"
wvCollapseGroup -win $nw "dc/CORE/hold"
wvCollapseGroup -win $nw "dc/CORE"

wvCollapseGroup -win $nw "dc/CTRL"

wvCollapseGroup -win $nw "dc/DAC/pins"
wvCollapseGroup -win $nw "dc/DAC/regs"
wvCollapseGroup -win $nw "dc/DAC/v"
wvCollapseGroup -win $nw "dc/DAC"

wvCollapseGroup -win $nw "dc"
