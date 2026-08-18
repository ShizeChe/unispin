create_project pl ./pl -part xczu49dr-ffvf1760-2-e -force
set_property board_part xilinx.com:zcu216:part0:2.0 [current_project]

set_property include_dirs {../src/dc ../src/rf ../src/ex ../src/li ../src/launch ../src/sequencer} [get_filesets sources_1]

add_files [glob ../src/sequencer/bram_sequencer.svh]
add_files [glob ../src/sequencer/bram_sequencer.sv]

add_files [glob ../src/dc/*.v]
add_files [glob ../src/dc/*.sv]
add_files [glob ../src/dc/*.svh]

add_files [glob ../src/rf/*.v]
add_files [glob ../src/rf/*.sv]
add_files [glob ../src/rf/*.svh]

add_files [glob ../src/ex/*.v]
add_files [glob ../src/ex/*.sv]
add_files [glob ../src/ex/*.svh]

add_files [glob ../src/li/*.v]
add_files [glob ../src/li/*.sv]
add_files [glob ../src/li/*.svh]

add_files [glob ../src/launch/*.v]
add_files [glob ../src/launch/*.sv]
add_files [glob ../src/launch/*.svh]

add_files [glob ../src/nco/*.v]
add_files [glob ../src/nco/*.sv]

add_files [glob ../src/processor/*.sv]

add_files [glob ../lib/axil_slave_regs/axil_slave_regs.sv]
add_files [glob ../lib/misc/edge_detector.sv]
add_files [glob ../lib/bram/bram.sv]
add_files [glob ../lib/bram/bram_2to1.sv]
add_files [glob ../lib/bram_fifo_2to1/bram_fifo_2to1.sv]

add_files [glob ./*.sv]

add_files [glob ./*.xdc]

update_compile_order -fileset sources_1

source ./bd.tcl
make_wrapper -files [get_files ./pl/pl.srcs/sources_1/bd/bd/bd.bd] -top
add_files -norecurse ./pl/pl.gen/sources_1/bd/bd/hdl/bd_wrapper.v
update_compile_order -fileset sources_1
close_bd_design [get_bd_designs bd]
