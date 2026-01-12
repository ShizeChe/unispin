create_project pl ./pl -part xczu49dr-ffvf1760-2-e -force
set_property board_part xilinx.com:zcu216:part0:2.0 [current_project]

set_property include_dirs {../include} [get_filesets sources_1]
add_files [glob ../include/*.svh]
add_files [glob ../include/*.vh]
add_files [glob ../src/*.sv]
add_files [glob ../src/*.v]
add_files [glob ./*.xdc]
remove_files  ../include/li.svh
remove_files  ../src/li_core.sv
remove_files  ../src/dcrfli.sv
add_files [glob ../lib/axil_slave_regs.sv]
add_files [glob ../lib/debouncer.sv]
add_files [glob ../lib/button_detector.sv]
add_files [glob ./*.sv]
update_compile_order -fileset sources_1

source ./bd.tcl
make_wrapper -files [get_files ./pl/pl.srcs/sources_1/bd/bd/bd.bd] -top
add_files -norecurse ./pl/pl.gen/sources_1/bd/bd/hdl/bd_wrapper.v
update_compile_order -fileset sources_1
close_bd_design [get_bd_designs bd]
