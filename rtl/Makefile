# Top-level variables
SIM := vcs
# SRC := $(wildcard src/dc*) $(wildcard src/rf*) $(wildcard src/li*) $(wildcard src/ex*) $(wildcard src/launch*) src/sequencer.sv src/uart_regs.sv sim/cmd_dpi.c lib/axil_slave_regs.sv lib/debouncer.sv lib/button_detector.sv lib/ad5791.sv lib/zcu216_dac.sv lib/fifo.sv lib/baudx16_generator.sv lib/transmitter.sv lib/receiver.sv lib/uart.sv lib/zcu216_adc.sv lib/zcu216_real_dac.sv lib/bram.sv lib/bram_fifo.sv lib/phase_observe.sv
# SRC := src/dc_decode.sv src/dc_spi_master.sv src/dc_core.sv src/sequencer.sv src/dc_ctrl.sv src/dc.sv lib/ad5791.sv
# SRC := src/rf_decode.sv src/rf_phasor.sv src/rf_cordic.sv src/rf_core.sv src/sequencer.sv src/rf_nco_update.sv src/rf_ctrl.sv src/rf_format.sv src/rf.sv lib/zcu216_dac.sv
# SRC :=  src/li.sv src/sequencer.sv src/li_core.sv src/li_ctrl.sv src/li_decode.sv src/li_sample.sv
# SRC := lib/bram.sv lib/bram_fifo.sv
SRC := src/rf_phasor.sv

TB ?= rf_phasor_tb
# TB_SRC := sim/$(TB).sv
TB_SRC := tb/$(TB).sv
TARGET := $(TB)
CORES := $(shell getconf _NPROCESSORS_ONLN)

VCS_FLAGS = -full64 -sverilog +incdir+include -debug_acc+all+dmptf -debug_region+cell+encrypt -kdb +warn=all -j$(CORES) +v2k
VERDI_FLAGS = +fsdbfile+dump.fsdb +vcs+all -gui

all: $(TARGET)

$(TARGET):
	@echo "[VCS] Compiling for $(MODULE)..."
	@echo "SRC=$(SRC), TB_SRC=$(TB_SRC)"
	$(SIM) $(VCS_FLAGS) $(SRC) $(TB_SRC) -o $@

.PHONY: clean run list gui

run:
	./$(TARGET)

gui:
	./$(TARGET) $(VERDI_FLAGS) &

list:
	@echo "Available design modules:"
	@ls -1 design/ | awk '{print "\t" $$0}'
	@echo "Available library modules:"
	@ls -1 lib/    | awk '{print "\t" $$0}'
	@echo "Available testbenches:"
	@ls -1 tb/     | awk '{print "\t" $$0}'

clean: 
	rm -rf build/*
	rm -rf csrc
	rm $(TARGET)
	rm -rf $(TARGET)*
	rm -rf sysBusyPLog
	rm -rf novas*
	rm -rf ucli.key
	rm -rf verdi*
	rm -rf inter.fsdb
	rm -rf *dump
	rm -rf obj_dir

