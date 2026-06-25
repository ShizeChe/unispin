set RTL_DIR rtl
set SVA_DIR fpv/sva

set FIFO_DEPTH 4
set FIFO_WIDTH 2

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

# Aggressive bug-hunt engines + small time limit.
set_engine_mode {n d}
set_prove_time_limit 30s

prove -all
report -summary
