# Top-level variables
SIM = vcs
SRC = $(wildcard lib/*.sv design/*.sv)
TB ?= swashispin_tb.sv
TB_SRC := tb/$(TB)
TARGET = $(TB)
CORES = $(shell getconf _NPROCESSORS_ONLN)

VCS_FLAGS = -full64 -sverilog -debug_acc+all+dmptf -debug_region+cell+encrypt -kdb +warn=all -j$(CORES) +v2k
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

