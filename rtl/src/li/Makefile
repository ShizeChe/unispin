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
# Must be passed to vcs before anything that uses those macros -- li_driver.sv
# (in SRC_UVM) and bram_sequencer.sv both rely on it being defined earlier in
# the single-invocation preprocessor pass, not via `include`.
SRC_SEQ_DEFS := ../sequencer/bram_sequencer.svh

SRC_SEQ := ../../lib/bram/bram.sv \
           ../../lib/bram/bram_2to1.sv \
           ../../lib/bram_fifo_2to1/bram_fifo_2to1.sv \
           ../../lib/misc/edge_detector.sv \
           ../sequencer/bram_sequencer.sv

# li_decode.sv (first here) `includes li.svh via +incdir+../../include, which
# defines the LI_* parameters/typedefs the uvm sources below reference
# directly without their own `include.
# li_axi_write.v isn't instantiated anywhere under li.sv's hierarchy (it's
# used standalone at the processor level), so it's excluded here.
SRC_LI := li_decode.sv \
          li_ctrl.sv \
          li_core.sv \
          li_sample.sv \
          li_save.sv \
          li.sv

SRC_UVM := uvm/li_tb.sv \
           uvm/transactions/li_program.sv \
           uvm/transactions/li_trace.sv \
           uvm/components/li_sequencer.sv \
           uvm/components/li_driver.sv \
           uvm/components/li_monitor.sv \
           uvm/components/li_model.sv \
           uvm/components/li_scoreboard.sv \
           uvm/components/li_agent.sv \
           uvm/components/li_env.sv \
           uvm/li_rand_sequence.sv \
           uvm/li_test.sv

# ── targets ──────────────────────────────────────────────────────────────────

.PHONY: all run gui clean list

all: li_uvm_test

li_uvm_test: $(SRC_SEQ_DEFS) $(SRC_SEQ) $(SRC_LI) $(SRC_UVM)
	$(SIM) $(VCS_FLAGS) $(SRC_SEQ_DEFS) $(SRC_SEQ) $(SRC_LI) $(SRC_UVM) -o $@

# ── simulation ───────────────────────────────────────────────────────────────

TARGET ?= li_uvm_test

run: li_uvm_test
	./$(TARGET)

gui: li_uvm_test
	./$(TARGET) $(VERDI_FLAGS) &

# ── housekeeping ─────────────────────────────────────────────────────────────

list:
	@echo "Targets:  li_uvm_test"
	@echo "Sources:"
	@echo "  $(SRC_SEQ) $(SRC_LI)" | tr ' ' '\n' | sed 's/^/  /'
	@echo "  $(SRC_UVM)" | tr ' ' '\n' | sed 's/^/  /'

clean:
	rm -rf li_uvm_test li_uvm_test.daidir \
	       csrc ucli.key vc_hdrs.h \
	       inter.fsdb novas.conf novas.rc novas_dump.log \
	       verdi_config_file verdiLog sysBusyPLog \
	       .inter.fsdb.tbsim
