TOP  = dc_tb
SRCS = ../sequencer/bram_sequencer.svh \
       ../../lib/bram/bram.sv \
       ../../lib/misc/edge_detector.sv \
       ../sequencer/bram_sequencer.sv \
       dc.svh \
       dc_decode.sv \
       dc_spi_master.sv \
       dc_core.sv \
       dc_ctrl.sv \
       dc.sv \
	   ../../lib/ad_vip/ad5791.sv \
       uvm/dc_tb.sv \
       uvm/transactions/dc_program.sv \
       uvm/transactions/dc_trace.sv \
       uvm/components/dc_sequencer.sv \
       uvm/components/dc_driver.sv \
       uvm/components/dc_monitor.sv \
       uvm/components/dc_model.sv \
       uvm/components/dc_scoreboard.sv \
       uvm/components/dc_agent.sv \
       uvm/components/dc_env.sv \
       uvm/dc_rand_sequence.sv \
       uvm/dc_test.sv

UVM_TEST  ?= dc_base_test
SEED      ?= 1
VERBOSITY ?= UVM_MEDIUM

VCS      = vcs
VFLAGS   = -full64 -sverilog -timescale=1ns/1ps \
           -debug_access+all -kdb \
           -ntb_opts uvm-1.2 \
           +incdir+uvm \
           +v2k +warn=all

SIM      = ./$(TOP)
SIMFLAGS = +UVM_TESTNAME=$(UVM_TEST) \
           +UVM_VERBOSITY=$(VERBOSITY) \
           -sv_seed $(SEED)

.PHONY: all compile sim gui clean

all: compile

compile: $(SIM)

$(SIM): $(SRCS)
	$(VCS) $(VFLAGS) -top $(TOP) $(SRCS) -o $(SIM)

sim: $(SIM)
	$(SIM) $(SIMFLAGS) | tee sim.log

gui: $(SIM)
	$(SIM) $(SIMFLAGS) -gui -verdi &

clean:
	rm -rf $(SIM) $(TOP).daidir csrc ucli.key vc_hdrs.h DVEfiles \
	       novas* *.fsdb verdiLog nWaveLog .verdi sim.log
