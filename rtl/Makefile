SIM   := vcs
CORES := $(shell getconf _NPROCESSORS_ONLN)

VCS_FLAGS := -full64 -sverilog +incdir+include \
             -debug_acc+all+dmptf +memcbk \
             -debug_region+cell+encrypt \
             -kdb +warn=all -j$(CORES) +v2k

VERDI_FLAGS := +fsdbfile+inter.fsdb +vcs+all -gui -do sim/wv.tcl

# ── source groups ────────────────────────────────────────────────────────────

SRC_SEQ := lib/bram.sv \
           lib/edge_detector.sv \
           src/bram_sequencer.sv

SRC_DC := src/dc_decode.sv \
          src/dc_spi_master.sv \
          src/dc_core.sv \
          src/dc_ctrl.sv \
          src/dc.sv

SRC_RF := src/rf_decode.sv \
          src/rf_phasor.sv \
          src/rf_cordic.sv \
          src/rf_format.sv \
          src/rf_core.sv \
          src/rf_ctrl.sv \
          src/rf.sv

SRC_LI := src/li_decode.sv \
          src/li_sample.sv \
          src/li_core.sv \
          src/li_ctrl.sv \
          src/li_axi_write.v \
          src/li_save.sv \
          src/li.sv

SRC_EX := src/ex_core.sv \
          src/ex.sv

SRC_PROC := $(SRC_SEQ) $(SRC_DC) $(SRC_RF) $(SRC_LI) $(SRC_EX) \
            src/launch.sv \
            src/processor.sv \
            lib/axil_slave_regs.sv \
            lib/debouncer.sv \
            lib/button_detector.sv \
            lib/bram_fifo.sv \
            lib/bram_2to1.sv \
            lib/bram_fifo_2to1.sv

SRC_REGS := src/dc_regs.v \
            src/rf_regs.v \
            src/li_regs.v \
            src/ex_regs.v \
            src/launch_regs.v

SRC_IO := lib/ad5791.sv \
          lib/zcu216_dac.sv \
          lib/zcu216_adc.sv \
          lib/zcu216_real_dac.sv

# ── targets ──────────────────────────────────────────────────────────────────

.PHONY: all simulator dc_tb rf_tb li_tb ex_tb bram_sequencer_tb launch_tb run gui clean list

all: simulator

simulator: sim/simulator.sv sim/cmd_dpi.c $(SRC_PROC) $(SRC_REGS) $(SRC_IO)
	$(SIM) $(VCS_FLAGS) $^ -o $@

dc_tb: tb/dc_tb.sv $(SRC_SEQ) $(SRC_DC) lib/ad5791.sv
	$(SIM) $(VCS_FLAGS) $^ -o $@

rf_tb: tb/rf_tb.sv $(SRC_SEQ) $(SRC_RF) lib/zcu216_dac.sv
	$(SIM) $(VCS_FLAGS) $^ -o $@

li_tb: tb/li_tb.sv $(SRC_SEQ) $(SRC_LI) lib/zcu216_adc.sv
	$(SIM) $(VCS_FLAGS) $^ -o $@

ex_tb: tb/ex_tb.sv $(SRC_SEQ) $(SRC_EX) lib/zcu216_real_dac.sv
	$(SIM) $(VCS_FLAGS) $^ -o $@

bram_sequencer_tb: tb/bram_sequencer_tb.sv $(SRC_SEQ)
	$(SIM) $(VCS_FLAGS) $^ -o $@

launch_tb: tb/launch_tb.sv src/launch.sv lib/debouncer.sv lib/button_detector.sv
	$(SIM) $(VCS_FLAGS) $^ -o $@

# ── simulation ───────────────────────────────────────────────────────────────

TARGET ?= simulator

run:
	./$(TARGET)

gui:
	./$(TARGET) $(VERDI_FLAGS) &

# ── housekeeping ─────────────────────────────────────────────────────────────

list:
	@echo "Targets:  simulator  dc_tb  rf_tb  li_tb  ex_tb  bram_sequencer_tb  launch_tb"
	@echo "Sources:"
	@ls -1 src/*.sv lib/*.sv sim/*.sv tb/*.sv 2>/dev/null | sed 's/^/  /'

clean:
	rm -rf simulator simulator.daidir \
	       dc_tb dc_tb.daidir \
	       rf_tb rf_tb.daidir \
	       li_tb li_tb.daidir \
	       ex_tb ex_tb.daidir \
	       bram_sequencer_tb bram_sequencer_tb.daidir \
	       launch_tb launch_tb.daidir \
	       csrc ucli.key vc_hdrs.h \
	       inter.fsdb novas.conf novas.rc novas_dump.log \
	       verdi_config_file verdiLog sysBusyPLog \
	       .inter.fsdb.tbsim \
	       vivado.jou vivado.log vivado_pid*.str
