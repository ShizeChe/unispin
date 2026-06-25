set RTL_DIR rtl
set SVA_DIR fpv/sva

if {![info exists FIFO_DEPTH]} { set FIFO_DEPTH 8 }
if {![info exists FIFO_WIDTH]} { set FIFO_WIDTH 8 }

clear -all

analyze -sv $RTL_DIR/fifo.sv
analyze -sv $SVA_DIR/fv_fifo.sv

elaborate -top fifo                                            \
    -disable_auto_bbox                                         \
    -parameter DEPTH                       $FIFO_DEPTH         \
    -parameter WIDTH                       $FIFO_WIDTH         \

clock i_clk
reset i_rst

get_design_info

# Cover-only: disable all assertions, keep cover properties.
assert -disable *
cover  -enable  *

set_engine_mode {c n d}
set_prove_time_limit 2m

prove -all
report -summary
