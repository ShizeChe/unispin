# Top-level variables
SIM := vcs
SRC := $(wildcard src/dc*) $(wildcard src/rf*) $(wildcard src/launch*) src/sequencer.sv lib/axil_slave_regs.sv lib/ad5791.sv lib/zcu216_dac.sv
# SRC := design/launch.sv design/dc_stream.sv design/dc_core.sv design/dc.sv design/rf_stream.sv design/rf_core.sv design/rf.sv lib/spi_master.sv lib/parabolic_counter.sv lib/cordic.sv lib/ad5541a.sv lib/zcu216_dac.sv
# SRC := design/launch.sv design/dc_stream.sv design/dc_core.sv design/dc.sv lib/spi_master.sv
# SRC := src/sequencer.sv src/rf_decode.sv src/rf_cordic.sv src/rf_phasor.sv lib/zcu216_dac.sv src/rf_core.sv
# SRC := src/sequencer.sv src/dc_decode.sv src/dc_spi_master.sv lib/ad5791.sv src/dc_core.sv

# SRC := $(filter-out design/uart.sv design/axi_lite_slave.sv lib/baud,$(SRC))
TB ?= simulator
TB_SRC := tb/$(TB).sv
TARGET := $(TB)
CORES := $(shell getconf _NPROCESSORS_ONLN)

VCS_FLAGS = -full64 -sverilog -debug_acc+all+dmptf -debug_region+cell+encrypt -kdb +warn=all -j$(CORES) +v2k \
			-Mdir=build -o build/simv
VERDI_FLAGS = +fsdbfile+build/dump.fsdb +vcs+all -gui

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

