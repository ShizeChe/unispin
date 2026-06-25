# ---------------------------------------------------------------------------
# Environment
# ---------------------------------------------------------------------------
set RTL_DIR rtl
set SVA_DIR fpv/sva

# Default proof params -- shrunk from the RTL defaults (DEPTH=32, WIDTH=4)
# so proofs converge quickly. Override before sourcing:
#   set FIFO_DEPTH 16 ; set FIFO_WIDTH 16 ; source fifo_check.tcl
if {![info exists FIFO_DEPTH]} { set FIFO_DEPTH 8 }
if {![info exists FIFO_WIDTH]} { set FIFO_WIDTH 8 }

# ---------------------------------------------------------------------------
# Compile
# ---------------------------------------------------------------------------
clear -all

# RTL (Verilog-2001, also accepted by -sv)
analyze -sv $RTL_DIR/fifo.sv

# SVA and bindings (SystemVerilog)
analyze -sv $SVA_DIR/fv_fifo.sv

# ---------------------------------------------------------------------------
# Elaborate
#
# -disable_auto_bbox keeps the data memory in-scope (the auto blackboxer
# would otherwise abstract away the FIFO data array and break the
# data-integrity proofs).
# ---------------------------------------------------------------------------
elaborate -top fifo                                            \
    -disable_auto_bbox                                         \
    -parameter DEPTH                       $FIFO_DEPTH         \
    -parameter WIDTH                       $FIFO_WIDTH         \

# ---------------------------------------------------------------------------
# Clock / reset
# ---------------------------------------------------------------------------
clock i_clk
reset i_rst

# ---------------------------------------------------------------------------
# Design info / sanity
# ---------------------------------------------------------------------------
get_design_info

# ---------------------------------------------------------------------------
# Engine mix + time limits
#   c : condor (heavy)
#   i : induction
#   k : K-induction
#   n : normalisation / property-directed
#   d : directed (fast bug-hunt)
# ---------------------------------------------------------------------------
set_engine_mode {c i k n d}
set_prove_time_limit 5m

# ---------------------------------------------------------------------------
# Run proofs and covers
# ---------------------------------------------------------------------------
prove -all
report -summary

# Uncomment for batch use:
# exit
