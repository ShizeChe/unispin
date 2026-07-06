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
# Must be passed to vcs before anything that uses those macros -- ex_driver.sv
# (pulled in via SRC_UVM) and bram_sequencer.sv both rely on it being defined
# earlier in the single-invocation preprocessor pass, not via `include`.
SRC_SEQ_DEFS := ../sequencer/bram_sequencer.svh

SRC_SEQ := ../../lib/bram/bram.sv \
           ../../lib/misc/edge_detector.sv \
           ../sequencer/bram_sequencer.sv

SRC_EX := ex_core.sv \
          ex_regs.v \
          ex.sv

SRC_UVM := uvm/ex_tb.sv

# Not passed to vcs directly (they're pulled in via `include` from SRC_UVM),
# but listed so make notices when they change and rebuilds.
SRC_UVM_INC := ex.svh \
               uvm/ex_uvm_pkg.sv \
               uvm/ex_test.sv \
               uvm/components/ex_if.sv \
               uvm/components/ex_sequencer.sv \
               uvm/components/ex_driver.sv \
               uvm/components/ex_monitor.sv \
               uvm/components/ex_model.sv \
               uvm/components/ex_scoreboard.sv \
               uvm/components/ex_agent.sv \
               uvm/components/ex_env.sv \
               uvm/transactions/ex_program.sv \
               uvm/transactions/ex_trace.sv

# ── targets ──────────────────────────────────────────────────────────────────

.PHONY: all run gui clean list

all: ex_uvm_test

ex_uvm_test: $(SRC_SEQ_DEFS) $(SRC_UVM) $(SRC_UVM_INC) $(SRC_SEQ) $(SRC_EX)
	$(SIM) $(VCS_FLAGS) $(SRC_SEQ_DEFS) $(SRC_UVM) $(SRC_SEQ) $(SRC_EX) -o $@

# ── simulation ───────────────────────────────────────────────────────────────

TARGET ?= ex_uvm_test

run: ex_uvm_test
	./$(TARGET)

gui: ex_uvm_test
	./$(TARGET) $(VERDI_FLAGS) &

# ── housekeeping ─────────────────────────────────────────────────────────────

list:
	@echo "Targets:  ex_uvm_test"
	@echo "Sources:"
	@echo "  $(SRC_UVM)" | tr ' ' '\n' | sed 's/^/  /'
	@echo "  $(SRC_SEQ) $(SRC_EX)" | tr ' ' '\n' | sed 's/^/  /'

clean:
	rm -rf ex_uvm_test ex_uvm_test.daidir \
	       csrc ucli.key vc_hdrs.h \
	       inter.fsdb novas.conf novas.rc novas_dump.log \
	       verdi_config_file verdiLog sysBusyPLog \
	       .inter.fsdb.tbsim
