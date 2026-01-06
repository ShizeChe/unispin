start_gui

create_project swashispin_pl /home/shizeche/hardware/xilinx/projects/swashispin_pl -part xczu49dr-ffvf1760-2-e

set_property board_part xilinx.com:zcu216:part0:2.0 [current_project]

add_files -norecurse {/home/shizeche/hardware/swashispin/rtl/include/rf.svh /home/shizeche/hardware/swashispin/rtl/include/launch.svh /home/shizeche/hardware/swashispin/rtl/include/dc.svh}

add_files -norecurse {/home/shizeche/hardware/swashispin/rtl/lib/axil_slave_regs.sv /home/shizeche/hardware/swashispin/rtl/src/dc_decode.sv /home/shizeche/hardware/swashispin/rtl/src/rf_decode.sv /home/shizeche/hardware/swashispin/rtl/src/rf_regs.v /home/shizeche/hardware/swashispin/rtl/src/dc_spi_master.sv /home/shizeche/hardware/swashispin/rtl/src/rf_cordic.sv /home/shizeche/hardware/swashispin/rtl/src/rf_core.sv /home/shizeche/hardware/swashispin/rtl/src/li_core.sv /home/shizeche/hardware/swashispin/rtl/src/rf.sv /home/shizeche/hardware/swashispin/rtl/src/dc.sv /home/shizeche/hardware/swashispin/rtl/src/dc_regs.v /home/shizeche/hardware/swashispin/rtl/src/launch.sv /home/shizeche/hardware/swashispin/rtl/src/dc_core.sv /home/shizeche/hardware/swashispin/rtl/src/rf_phasor.sv /home/shizeche/hardware/swashispin/rtl/src/launch_regs.v /home/shizeche/hardware/swashispin/rtl/src/sequencer.sv}

update_compile_order -fileset sources_1
remove_files  /home/shizeche/hardware/swashispin/rtl/src/li_core.sv
update_compile_order -fileset sources_1

create_bd_design "bd"

startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:3.5 zynq_ultra_ps_e_0
endgroup

apply_bd_automation -rule xilinx.com:bd_rule:zynq_ultra_ps_e -config {apply_board_preset "1" }  [get_bd_cells zynq_ultra_ps_e_0]
create_bd_cell -type module -reference dc_regs dc_regs_0
create_bd_cell -type module -reference launch_regs launch_regs_0
