SIM   := vcs
CORES := $(shell getconf _NPROCESSORS_ONLN)

VCS_FLAGS := -full64 -sverilog -ntb_opts uvm-1.2 +incdir+uvm \
             -timescale=1ns/1ps \
             -debug_acc+all+dmptf +memcbk \
             -debug_region+cell+encrypt \
             -kdb +warn=all -j$(CORES) +v2k

VERDI_FLAGS := +fsdbfile+inter.fsdb +vcs+all -gui -do sim/wv.tcl

# ── source groups ────────────────────────────────────────────────────────────

# Defines the bram_sequencer i_regs map (PCST_*, IST_*, ITERS_REG, ...).
# Must be passed to vcs before anything that uses those macros -- rf_driver.sv
# (pulled in via SRC_UVM) and bram_sequencer.sv both rely on it being defined
# earlier in the single-invocation preprocessor pass, not via `include`.
SRC_SEQ_DEFS := ../sequencer/bram_sequencer.svh

SRC_SEQ := ../../lib/bram/bram.sv \
           ../../lib/misc/edge_detector.sv \
           ../sequencer/bram_sequencer.sv

SRC_RF := rf_decode.sv \
          rf_ctrl.sv \
          rf_cordic.sv \
          rf_phasor.sv \
          rf_format.sv \
          rf_core.sv \
          rf_regs.v \
          rf.sv

SRC_UVM := uvm/rf_tb.sv

# Not passed to vcs directly (they're pulled in via `include` from SRC_UVM),
# but listed so make notices when they change and rebuilds.
SRC_UVM_INC := rf.svh \
               uvm/rf_uvm_pkg.sv \
               uvm/rf_test.sv \
               uvm/components/rf_if.sv \
               uvm/components/rf_sequencer.sv \
               uvm/components/rf_driver.sv \
               uvm/components/rf_monitor.sv \
               uvm/components/rf_model.sv \
               uvm/components/rf_scoreboard.sv \
               uvm/components/rf_agent.sv \
               uvm/components/rf_env.sv \
               uvm/transactions/rf_program.sv \
               uvm/transactions/rf_trace.sv

# ── targets ──────────────────────────────────────────────────────────────────

.PHONY: all run gui clean list

all: rf_uvm_test

rf_uvm_test: $(SRC_SEQ_DEFS) $(SRC_UVM) $(SRC_UVM_INC) $(SRC_SEQ) $(SRC_RF)
	$(SIM) $(VCS_FLAGS) $(SRC_SEQ_DEFS) $(SRC_UVM) $(SRC_SEQ) $(SRC_RF) -o $@

# ── simulation ───────────────────────────────────────────────────────────────

TARGET ?= rf_uvm_test

run: rf_uvm_test
	./$(TARGET)

gui: rf_uvm_test
	./$(TARGET) $(VERDI_FLAGS) &

# ── housekeeping ─────────────────────────────────────────────────────────────

list:
	@echo "Targets:  rf_uvm_test"
	@echo "Sources:"
	@echo "  $(SRC_UVM)" | tr ' ' '\n' | sed 's/^/  /'
	@echo "  $(SRC_SEQ) $(SRC_RF)" | tr ' ' '\n' | sed 's/^/  /'

clean:
	rm -rf rf_uvm_test rf_uvm_test.daidir \
	       csrc ucli.key vc_hdrs.h \
	       inter.fsdb novas.conf novas.rc novas_dump.log \
	       verdi_config_file verdiLog sysBusyPLog \
	       .inter.fsdb.tbsim
