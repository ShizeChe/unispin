SIM   := vcs
CORES := $(shell getconf _NPROCESSORS_ONLN)

VCS_FLAGS := -full64 -sverilog -ntb_opts uvm-1.2 +incdir+uvm +incdir+../../include \
             -timescale=1ns/1ps \
             -debug_acc+all+dmptf +memcbk \
             -debug_region+cell+encrypt \
             -kdb +warn=all -j$(CORES) +v2k

VERDI_FLAGS := +fsdbfile+inter.fsdb +vcs+all -gui -do sim/wv.tcl

# ── source groups ────────────────────────────────────────────────────────────

# Defines the bram_sequencer i_regs map (PCST_*, IST_*, ITERS_REG, ...).
# Must be passed to vcs before anything that uses those macros -- rf_driver.sv
# (in SRC_UVM) and bram_sequencer.sv both rely on it being defined earlier in
# the single-invocation preprocessor pass, not via `include`.
SRC_SEQ_DEFS := ../sequencer/bram_sequencer.svh

SRC_SEQ := ../../lib/bram/bram.sv \
           ../../lib/misc/edge_detector.sv \
           ../sequencer/bram_sequencer.sv

# rf_decode.sv (first here) `includes rf.svh via +incdir+../../include, which
# defines the RF_* parameters/typedefs the uvm sources below reference
# directly without their own `include.
# rf_regs.v (the AXI-Lite register wrapper used by processor.sv) is
# deliberately excluded -- this testbench drives rf's i_seq_regs/i_ctrl_regs
# directly and doesn't need axil_slave_regs pulled in.
SRC_RF := rf_decode.sv \
          rf_ctrl.sv \
          rf_cordic.sv \
          rf_phasor.sv \
          rf_format.sv \
          rf_core.sv \
          rf.sv

SRC_UVM := uvm/rf_tb.sv \
           uvm/transactions/rf_program.sv \
           uvm/transactions/rf_trace.sv \
           uvm/components/rf_sequencer.sv \
           uvm/components/rf_driver.sv \
           uvm/components/rf_monitor.sv \
           uvm/components/rf_model.sv \
           uvm/components/rf_scoreboard.sv \
           uvm/components/rf_agent.sv \
           uvm/components/rf_env.sv \
           uvm/rf_rand_sequence.sv \
           uvm/rf_test.sv

# ── targets ──────────────────────────────────────────────────────────────────

.PHONY: all run gui clean list

all: rf_uvm_test

rf_uvm_test: $(SRC_SEQ_DEFS) $(SRC_SEQ) $(SRC_RF) $(SRC_UVM)
	$(SIM) $(VCS_FLAGS) $(SRC_SEQ_DEFS) $(SRC_SEQ) $(SRC_RF) $(SRC_UVM) -o $@

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
	@echo "  $(SRC_SEQ) $(SRC_RF)" | tr ' ' '\n' | sed 's/^/  /'
	@echo "  $(SRC_UVM)" | tr ' ' '\n' | sed 's/^/  /'

clean:
	rm -rf rf_uvm_test rf_uvm_test.daidir \
	       csrc ucli.key vc_hdrs.h \
	       inter.fsdb novas.conf novas.rc novas_dump.log \
	       verdi_config_file verdiLog sysBusyPLog \
	       .inter.fsdb.tbsim
