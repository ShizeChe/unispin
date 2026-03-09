
################################################################
# This is a generated script based on design: bd
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2024.2
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   if { [string compare $scripts_vivado_version $current_vivado_version] > 0 } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2042 -severity "ERROR" " This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Sourcing the script failed since it was created with a future version of Vivado."}

   } else {
     catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   }

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source bd_script.tcl


# The design that will be created by this Tcl script contains the following 
# module references:
# dc_regs, launch_regs, rf_regs, dc_regs, dc_regs, dc_regs, dc_regs, dc_regs, dc_regs, dc_regs, dc_regs, dc_regs, dc_regs, dc_regs, dc_regs, dc_regs, dc_regs, dc_regs, dc_regs, dc_regs, dc_regs, dc_regs, dc_regs, dc_regs, dc_regs, dc_regs, rf_regs, rf_regs, rf_regs, rf_regs, rf_regs, li_regs, li_regs, li_axi_write, li_axi_write

# Please add the sources of those modules before sourcing this Tcl script.

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xczu49dr-ffvf1760-2-e
   set_property BOARD_PART xilinx.com:zcu216:part0:2.0 [current_project]
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name bd

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_gid_msg -ssname BD::TCL -id 2006 -severity "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:zynq_ultra_ps_e:3.5\
xilinx.com:ip:smartconnect:1.0\
xilinx.com:ip:proc_sys_reset:5.0\
xilinx.com:ip:usp_rf_data_converter:2.6\
"

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

##################################################################
# CHECK Modules
##################################################################
set bCheckModules 1
if { $bCheckModules == 1 } {
   set list_check_mods "\ 
dc_regs\
launch_regs\
rf_regs\
dc_regs\
dc_regs\
dc_regs\
dc_regs\
dc_regs\
dc_regs\
dc_regs\
dc_regs\
dc_regs\
dc_regs\
dc_regs\
dc_regs\
dc_regs\
dc_regs\
dc_regs\
dc_regs\
dc_regs\
dc_regs\
dc_regs\
dc_regs\
dc_regs\
dc_regs\
dc_regs\
rf_regs\
rf_regs\
rf_regs\
rf_regs\
rf_regs\
li_regs\
li_regs\
li_axi_write\
li_axi_write\
"

   set list_mods_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2020 -severity "INFO" "Checking if the following modules exist in the project's sources: $list_check_mods ."

   foreach mod_vlnv $list_check_mods {
      if { [can_resolve_reference $mod_vlnv] == 0 } {
         lappend list_mods_missing $mod_vlnv
      }
   }

   if { $list_mods_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2021 -severity "ERROR" "The following module(s) are not found in the project: $list_mods_missing" }
      common::send_gid_msg -ssname BD::TCL -id 2022 -severity "INFO" "Please add source files for the missing module(s) above."
      set bCheckIPsPassed 0
   }
}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set s00_axis_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s00_axis_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {250000000} \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {0} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {32} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
   ] $s00_axis_0

  set s02_axis_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s02_axis_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {250000000} \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {0} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {32} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
   ] $s02_axis_0

  set s10_axis_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s10_axis_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {250000000} \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {0} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {32} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
   ] $s10_axis_0

  set s12_axis_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s12_axis_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {250000000} \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {0} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {32} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
   ] $s12_axis_0

  set s20_axis_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s20_axis_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {250000000} \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {0} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {32} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
   ] $s20_axis_0

  set s22_axis_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s22_axis_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {250000000} \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {0} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {32} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
   ] $s22_axis_0

  set vout00_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 vout00_0 ]

  set vout01_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 vout01_0 ]

  set vout02_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 vout02_0 ]

  set vout03_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 vout03_0 ]

  set vout10_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 vout10_0 ]

  set vout11_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 vout11_0 ]

  set vout12_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 vout12_0 ]

  set vout13_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 vout13_0 ]

  set vout20_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 vout20_0 ]

  set vout21_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 vout21_0 ]

  set vout22_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 vout22_0 ]

  set vout23_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 vout23_0 ]

  set adc1_clk_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 adc1_clk_0 ]

  set dac1_clk_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 dac1_clk_0 ]

  set vin10_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 vin10_0 ]

  set vin11_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 vin11_0 ]

  set sysref_in_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_usp_rf_data_converter:diff_pins_rtl:1.0 sysref_in_0 ]

  set dac0_nco_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:rfdc_nco_pins_rtl:1.0 dac0_nco_0 ]

  set dac1_nco_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:rfdc_nco_pins_rtl:1.0 dac1_nco_0 ]

  set dac2_nco_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:rfdc_nco_pins_rtl:1.0 dac2_nco_0 ]

  set m10_axis_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m10_axis_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {250000000} \
   ] $m10_axis_0

  set m11_axis_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m11_axis_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {250000000} \
   ] $m11_axis_0

  set dac3_nco_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:rfdc_nco_pins_rtl:1.0 dac3_nco_0 ]

  set adc1_nco_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:rfdc_nco_pins_rtl:1.0 adc1_nco_0 ]

  set s30_axis_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s30_axis_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {250000000} \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {0} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {32} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
   ] $s30_axis_0

  set s31_axis_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s31_axis_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {250000000} \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {0} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {32} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
   ] $s31_axis_0

  set s32_axis_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s32_axis_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {250000000} \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {0} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {32} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
   ] $s32_axis_0

  set s33_axis_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s33_axis_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {250000000} \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {0} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {32} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
   ] $s33_axis_0

  set vout30_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 vout30_0 ]

  set vout31_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 vout31_0 ]

  set vout32_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 vout32_0 ]

  set vout33_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 vout33_0 ]


  # Create ports
  set dcrfli_clk [ create_bd_port -dir I -type clk -freq_hz 250000000 dcrfli_clk ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {s00_axis_0:s02_axis_0:s10_axis_0:s12_axis_0:s20_axis_0:s22_axis_0:m10_axis_0:m11_axis_0:s30_axis_0:s31_axis_0:s32_axis_0:s33_axis_0} \
 ] $dcrfli_clk
  set clk_dac1_0 [ create_bd_port -dir O -type clk clk_dac1_0 ]
  set o_dc_seq_regs0 [ create_bd_port -dir O -from 1023 -to 0 o_dc_seq_regs0 ]
  set o_dc_seq_regs1 [ create_bd_port -dir O -from 1023 -to 0 o_dc_seq_regs1 ]
  set o_dc_seq_regs2 [ create_bd_port -dir O -from 1023 -to 0 o_dc_seq_regs2 ]
  set o_dc_seq_regs3 [ create_bd_port -dir O -from 1023 -to 0 o_dc_seq_regs3 ]
  set o_dc_seq_regs4 [ create_bd_port -dir O -from 1023 -to 0 o_dc_seq_regs4 ]
  set o_dc_seq_regs5 [ create_bd_port -dir O -from 1023 -to 0 o_dc_seq_regs5 ]
  set o_dc_seq_regs6 [ create_bd_port -dir O -from 1023 -to 0 o_dc_seq_regs6 ]
  set o_dc_seq_regs7 [ create_bd_port -dir O -from 1023 -to 0 o_dc_seq_regs7 ]
  set o_dc_seq_regs8 [ create_bd_port -dir O -from 1023 -to 0 o_dc_seq_regs8 ]
  set o_dc_seq_regs9 [ create_bd_port -dir O -from 1023 -to 0 o_dc_seq_regs9 ]
  set o_dc_seq_regs10 [ create_bd_port -dir O -from 1023 -to 0 o_dc_seq_regs10 ]
  set o_dc_seq_regs11 [ create_bd_port -dir O -from 1023 -to 0 o_dc_seq_regs11 ]
  set o_dc_seq_regs12 [ create_bd_port -dir O -from 1023 -to 0 o_dc_seq_regs12 ]
  set o_dc_seq_regs13 [ create_bd_port -dir O -from 1023 -to 0 o_dc_seq_regs13 ]
  set o_dc_seq_regs14 [ create_bd_port -dir O -from 1023 -to 0 o_dc_seq_regs14 ]
  set o_dc_seq_regs15 [ create_bd_port -dir O -from 1023 -to 0 o_dc_seq_regs15 ]
  set o_dc_seq_regs16 [ create_bd_port -dir O -from 1023 -to 0 o_dc_seq_regs16 ]
  set o_dc_seq_regs17 [ create_bd_port -dir O -from 1023 -to 0 o_dc_seq_regs17 ]
  set o_dc_seq_regs18 [ create_bd_port -dir O -from 1023 -to 0 o_dc_seq_regs18 ]
  set o_dc_seq_regs19 [ create_bd_port -dir O -from 1023 -to 0 o_dc_seq_regs19 ]
  set o_dc_seq_regs20 [ create_bd_port -dir O -from 1023 -to 0 o_dc_seq_regs20 ]
  set o_dc_seq_regs21 [ create_bd_port -dir O -from 1023 -to 0 o_dc_seq_regs21 ]
  set o_dc_seq_regs22 [ create_bd_port -dir O -from 1023 -to 0 o_dc_seq_regs22 ]
  set o_dc_seq_regs23 [ create_bd_port -dir O -from 1023 -to 0 o_dc_seq_regs23 ]
  set o_dc_ctrl_regs0 [ create_bd_port -dir O -from 127 -to 0 o_dc_ctrl_regs0 ]
  set o_dc_ctrl_regs1 [ create_bd_port -dir O -from 127 -to 0 o_dc_ctrl_regs1 ]
  set o_dc_ctrl_regs2 [ create_bd_port -dir O -from 127 -to 0 o_dc_ctrl_regs2 ]
  set o_dc_ctrl_regs3 [ create_bd_port -dir O -from 127 -to 0 o_dc_ctrl_regs3 ]
  set o_dc_ctrl_regs4 [ create_bd_port -dir O -from 127 -to 0 o_dc_ctrl_regs4 ]
  set o_dc_ctrl_regs5 [ create_bd_port -dir O -from 127 -to 0 o_dc_ctrl_regs5 ]
  set o_dc_ctrl_regs6 [ create_bd_port -dir O -from 127 -to 0 o_dc_ctrl_regs6 ]
  set o_dc_ctrl_regs7 [ create_bd_port -dir O -from 127 -to 0 o_dc_ctrl_regs7 ]
  set o_dc_ctrl_regs8 [ create_bd_port -dir O -from 127 -to 0 o_dc_ctrl_regs8 ]
  set o_dc_ctrl_regs9 [ create_bd_port -dir O -from 127 -to 0 o_dc_ctrl_regs9 ]
  set o_dc_ctrl_regs10 [ create_bd_port -dir O -from 127 -to 0 o_dc_ctrl_regs10 ]
  set o_dc_ctrl_regs11 [ create_bd_port -dir O -from 127 -to 0 o_dc_ctrl_regs11 ]
  set o_dc_ctrl_regs12 [ create_bd_port -dir O -from 127 -to 0 o_dc_ctrl_regs12 ]
  set o_dc_ctrl_regs13 [ create_bd_port -dir O -from 127 -to 0 o_dc_ctrl_regs13 ]
  set o_dc_ctrl_regs14 [ create_bd_port -dir O -from 127 -to 0 o_dc_ctrl_regs14 ]
  set o_dc_ctrl_regs15 [ create_bd_port -dir O -from 127 -to 0 o_dc_ctrl_regs15 ]
  set o_dc_ctrl_regs16 [ create_bd_port -dir O -from 127 -to 0 o_dc_ctrl_regs16 ]
  set o_dc_ctrl_regs17 [ create_bd_port -dir O -from 127 -to 0 o_dc_ctrl_regs17 ]
  set o_dc_ctrl_regs18 [ create_bd_port -dir O -from 127 -to 0 o_dc_ctrl_regs18 ]
  set o_dc_ctrl_regs19 [ create_bd_port -dir O -from 127 -to 0 o_dc_ctrl_regs19 ]
  set o_dc_ctrl_regs20 [ create_bd_port -dir O -from 127 -to 0 o_dc_ctrl_regs20 ]
  set o_dc_ctrl_regs21 [ create_bd_port -dir O -from 127 -to 0 o_dc_ctrl_regs21 ]
  set o_dc_ctrl_regs22 [ create_bd_port -dir O -from 127 -to 0 o_dc_ctrl_regs22 ]
  set o_dc_ctrl_regs23 [ create_bd_port -dir O -from 127 -to 0 o_dc_ctrl_regs23 ]
  set o_rf_seq_regs0 [ create_bd_port -dir O -from 2111 -to 0 o_rf_seq_regs0 ]
  set o_rf_seq_regs1 [ create_bd_port -dir O -from 2111 -to 0 o_rf_seq_regs1 ]
  set o_rf_seq_regs2 [ create_bd_port -dir O -from 2111 -to 0 o_rf_seq_regs2 ]
  set o_rf_seq_regs3 [ create_bd_port -dir O -from 2111 -to 0 o_rf_seq_regs3 ]
  set o_rf_seq_regs4 [ create_bd_port -dir O -from 2111 -to 0 o_rf_seq_regs4 ]
  set o_rf_seq_regs5 [ create_bd_port -dir O -from 2111 -to 0 o_rf_seq_regs5 ]
  set o_rf_ctrl_regs0 [ create_bd_port -dir O -from 191 -to 0 o_rf_ctrl_regs0 ]
  set o_rf_ctrl_regs1 [ create_bd_port -dir O -from 191 -to 0 o_rf_ctrl_regs1 ]
  set o_rf_ctrl_regs2 [ create_bd_port -dir O -from 191 -to 0 o_rf_ctrl_regs2 ]
  set o_rf_ctrl_regs3 [ create_bd_port -dir O -from 191 -to 0 o_rf_ctrl_regs3 ]
  set o_rf_ctrl_regs4 [ create_bd_port -dir O -from 191 -to 0 o_rf_ctrl_regs4 ]
  set o_rf_ctrl_regs5 [ create_bd_port -dir O -from 191 -to 0 o_rf_ctrl_regs5 ]
  set o_lch_regs [ create_bd_port -dir O -from 127 -to 0 o_lch_regs ]
  set dcrfli_rst_n [ create_bd_port -dir O -from 0 -to 0 dcrfli_rst_n ]
  set o_li_seq_regs0 [ create_bd_port -dir O -from 1087 -to 0 o_li_seq_regs0 ]
  set o_li_ctrl_regs0 [ create_bd_port -dir O -from 95 -to 0 o_li_ctrl_regs0 ]
  set o_li_seq_regs1 [ create_bd_port -dir O -from 1087 -to 0 o_li_seq_regs1 ]
  set o_li_ctrl_regs1 [ create_bd_port -dir O -from 95 -to 0 o_li_ctrl_regs1 ]
  set i_li_validx4_0 [ create_bd_port -dir I -from 3 -to 0 i_li_validx4_0 ]
  set i_li_validx4_1 [ create_bd_port -dir I -from 3 -to 0 i_li_validx4_1 ]
  set i_li_last_0 [ create_bd_port -dir I i_li_last_0 ]
  set i_li_QIx4_0 [ create_bd_port -dir I -from 127 -to 0 i_li_QIx4_0 ]
  set i_li_ctrl_0 [ create_bd_port -dir I -from 85 -to 0 i_li_ctrl_0 ]
  set i_li_QIx4_1 [ create_bd_port -dir I -from 127 -to 0 i_li_QIx4_1 ]
  set i_li_last_1 [ create_bd_port -dir I i_li_last_1 ]
  set i_li_ctrl_1 [ create_bd_port -dir I -from 85 -to 0 i_li_ctrl_1 ]

  # Create instance: zynq_ultra_ps_e_0, and set properties
  set zynq_ultra_ps_e_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:3.5 zynq_ultra_ps_e_0 ]
  set_property -dict [list \
    CONFIG.PSU_BANK_0_IO_STANDARD {LVCMOS18} \
    CONFIG.PSU_BANK_1_IO_STANDARD {LVCMOS18} \
    CONFIG.PSU_BANK_2_IO_STANDARD {LVCMOS18} \
    CONFIG.PSU_DDR_RAM_HIGHADDR {0xFFFFFFFF} \
    CONFIG.PSU_DDR_RAM_HIGHADDR_OFFSET {0x800000000} \
    CONFIG.PSU_DDR_RAM_LOWADDR_OFFSET {0x80000000} \
    CONFIG.PSU_DYNAMIC_DDR_CONFIG_EN {1} \
    CONFIG.PSU_MIO_13_POLARITY {Default} \
    CONFIG.PSU_MIO_20_POLARITY {Default} \
    CONFIG.PSU_MIO_21_POLARITY {Default} \
    CONFIG.PSU_MIO_22_INPUT_TYPE {cmos} \
    CONFIG.PSU_MIO_22_POLARITY {Default} \
    CONFIG.PSU_MIO_23_POLARITY {Default} \
    CONFIG.PSU_MIO_24_POLARITY {Default} \
    CONFIG.PSU_MIO_25_POLARITY {Default} \
    CONFIG.PSU_MIO_26_POLARITY {Default} \
    CONFIG.PSU_MIO_27_POLARITY {Default} \
    CONFIG.PSU_MIO_28_POLARITY {Default} \
    CONFIG.PSU_MIO_29_POLARITY {Default} \
    CONFIG.PSU_MIO_30_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_30_POLARITY {Default} \
    CONFIG.PSU_MIO_30_SLEW {fast} \
    CONFIG.PSU_MIO_31_POLARITY {Default} \
    CONFIG.PSU_MIO_32_POLARITY {Default} \
    CONFIG.PSU_MIO_33_POLARITY {Default} \
    CONFIG.PSU_MIO_34_POLARITY {Default} \
    CONFIG.PSU_MIO_35_POLARITY {Default} \
    CONFIG.PSU_MIO_36_POLARITY {Default} \
    CONFIG.PSU_MIO_37_POLARITY {Default} \
    CONFIG.PSU_MIO_38_POLARITY {Default} \
    CONFIG.PSU_MIO_43_POLARITY {Default} \
    CONFIG.PSU_MIO_44_POLARITY {Default} \
    CONFIG.PSU_MIO_TREE_PERIPHERALS {Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Feedback Clk#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad\
SPI Flash#Quad SPI Flash#GPIO0 MIO#I2C 0#I2C 0#I2C 1#I2C 1#UART 0#UART 0#GPIO0 MIO#GPIO0 MIO#GPIO0 MIO#GPIO0 MIO#GPIO0 MIO#GPIO0 MIO#GPIO1 MIO#GPIO1 MIO#GPIO1 MIO#GPIO1 MIO#GPIO1 MIO#GPIO1 MIO#GPIO1 MIO#GPIO1\
MIO#GPIO1 MIO#GPIO1 MIO#GPIO1 MIO#GPIO1 MIO#GPIO1 MIO#SD 1#SD 1#SD 1#SD 1#GPIO1 MIO#GPIO1 MIO#SD 1#SD 1#SD 1#SD 1#SD 1#SD 1#SD 1#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#Gem\
3#Gem 3#Gem 3#Gem 3#Gem 3#Gem 3#Gem 3#Gem 3#Gem 3#Gem 3#Gem 3#Gem 3#MDIO 3#MDIO 3} \
    CONFIG.PSU_MIO_TREE_SIGNALS {sclk_out#miso_mo1#mo2#mo3#mosi_mi0#n_ss_out#clk_for_lpbk#n_ss_out_upper#mo_upper[0]#mo_upper[1]#mo_upper[2]#mo_upper[3]#sclk_out_upper#gpio0[13]#scl_out#sda_out#scl_out#sda_out#rxd#txd#gpio0[20]#gpio0[21]#gpio0[22]#gpio0[23]#gpio0[24]#gpio0[25]#gpio1[26]#gpio1[27]#gpio1[28]#gpio1[29]#gpio1[30]#gpio1[31]#gpio1[32]#gpio1[33]#gpio1[34]#gpio1[35]#gpio1[36]#gpio1[37]#gpio1[38]#sdio1_data_out[4]#sdio1_data_out[5]#sdio1_data_out[6]#sdio1_data_out[7]#gpio1[43]#gpio1[44]#sdio1_cd_n#sdio1_data_out[0]#sdio1_data_out[1]#sdio1_data_out[2]#sdio1_data_out[3]#sdio1_cmd_out#sdio1_clk_out#ulpi_clk_in#ulpi_dir#ulpi_tx_data[2]#ulpi_nxt#ulpi_tx_data[0]#ulpi_tx_data[1]#ulpi_stp#ulpi_tx_data[3]#ulpi_tx_data[4]#ulpi_tx_data[5]#ulpi_tx_data[6]#ulpi_tx_data[7]#rgmii_tx_clk#rgmii_txd[0]#rgmii_txd[1]#rgmii_txd[2]#rgmii_txd[3]#rgmii_tx_ctl#rgmii_rx_clk#rgmii_rxd[0]#rgmii_rxd[1]#rgmii_rxd[2]#rgmii_rxd[3]#rgmii_rx_ctl#gem3_mdc#gem3_mdio_out}\
\
    CONFIG.PSU_SD1_INTERNAL_BUS_WIDTH {8} \
    CONFIG.PSU_USB3__DUAL_CLOCK_ENABLE {1} \
    CONFIG.PSU__ACT_DDR_FREQ_MHZ {1049.989502} \
    CONFIG.PSU__CAN1__PERIPHERAL__ENABLE {0} \
    CONFIG.PSU__CRF_APB__ACPU_CTRL__ACT_FREQMHZ {1199.988037} \
    CONFIG.PSU__CRF_APB__ACPU_CTRL__FREQMHZ {1200} \
    CONFIG.PSU__CRF_APB__ACPU_CTRL__SRCSEL {APLL} \
    CONFIG.PSU__CRF_APB__APLL_CTRL__SRCSEL {PSS_REF_CLK} \
    CONFIG.PSU__CRF_APB__DBG_FPD_CTRL__ACT_FREQMHZ {249.997498} \
    CONFIG.PSU__CRF_APB__DBG_FPD_CTRL__FREQMHZ {250} \
    CONFIG.PSU__CRF_APB__DBG_FPD_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRF_APB__DBG_TRACE_CTRL__FREQMHZ {250} \
    CONFIG.PSU__CRF_APB__DBG_TRACE_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRF_APB__DBG_TSTMP_CTRL__ACT_FREQMHZ {249.997498} \
    CONFIG.PSU__CRF_APB__DBG_TSTMP_CTRL__FREQMHZ {250} \
    CONFIG.PSU__CRF_APB__DBG_TSTMP_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRF_APB__DDR_CTRL__ACT_FREQMHZ {524.994751} \
    CONFIG.PSU__CRF_APB__DDR_CTRL__FREQMHZ {1066} \
    CONFIG.PSU__CRF_APB__DDR_CTRL__SRCSEL {DPLL} \
    CONFIG.PSU__CRF_APB__DPDMA_REF_CTRL__ACT_FREQMHZ {599.994019} \
    CONFIG.PSU__CRF_APB__DPDMA_REF_CTRL__FREQMHZ {600} \
    CONFIG.PSU__CRF_APB__DPDMA_REF_CTRL__SRCSEL {APLL} \
    CONFIG.PSU__CRF_APB__DPLL_CTRL__SRCSEL {PSS_REF_CLK} \
    CONFIG.PSU__CRF_APB__DP_AUDIO_REF_CTRL__SRCSEL {RPLL} \
    CONFIG.PSU__CRF_APB__DP_STC_REF_CTRL__SRCSEL {RPLL} \
    CONFIG.PSU__CRF_APB__DP_VIDEO_REF_CTRL__SRCSEL {VPLL} \
    CONFIG.PSU__CRF_APB__GDMA_REF_CTRL__ACT_FREQMHZ {599.994019} \
    CONFIG.PSU__CRF_APB__GDMA_REF_CTRL__FREQMHZ {600} \
    CONFIG.PSU__CRF_APB__GDMA_REF_CTRL__SRCSEL {APLL} \
    CONFIG.PSU__CRF_APB__GPU_REF_CTRL__FREQMHZ {500} \
    CONFIG.PSU__CRF_APB__GPU_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRF_APB__SATA_REF_CTRL__ACT_FREQMHZ {249.997498} \
    CONFIG.PSU__CRF_APB__SATA_REF_CTRL__FREQMHZ {250} \
    CONFIG.PSU__CRF_APB__SATA_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRF_APB__TOPSW_LSBUS_CTRL__ACT_FREQMHZ {99.999001} \
    CONFIG.PSU__CRF_APB__TOPSW_LSBUS_CTRL__FREQMHZ {100} \
    CONFIG.PSU__CRF_APB__TOPSW_LSBUS_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRF_APB__TOPSW_MAIN_CTRL__ACT_FREQMHZ {524.994751} \
    CONFIG.PSU__CRF_APB__TOPSW_MAIN_CTRL__FREQMHZ {533.33} \
    CONFIG.PSU__CRF_APB__TOPSW_MAIN_CTRL__SRCSEL {DPLL} \
    CONFIG.PSU__CRF_APB__VPLL_CTRL__SRCSEL {PSS_REF_CLK} \
    CONFIG.PSU__CRL_APB__ADMA_REF_CTRL__ACT_FREQMHZ {499.994995} \
    CONFIG.PSU__CRL_APB__ADMA_REF_CTRL__FREQMHZ {500} \
    CONFIG.PSU__CRL_APB__ADMA_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__AMS_REF_CTRL__ACT_FREQMHZ {49.999500} \
    CONFIG.PSU__CRL_APB__CAN1_REF_CTRL__FREQMHZ {100} \
    CONFIG.PSU__CRL_APB__CAN1_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__CPU_R5_CTRL__ACT_FREQMHZ {499.994995} \
    CONFIG.PSU__CRL_APB__CPU_R5_CTRL__FREQMHZ {500} \
    CONFIG.PSU__CRL_APB__CPU_R5_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__DBG_LPD_CTRL__ACT_FREQMHZ {249.997498} \
    CONFIG.PSU__CRL_APB__DBG_LPD_CTRL__FREQMHZ {250} \
    CONFIG.PSU__CRL_APB__DBG_LPD_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__DLL_REF_CTRL__ACT_FREQMHZ {1499.984985} \
    CONFIG.PSU__CRL_APB__GEM3_REF_CTRL__ACT_FREQMHZ {124.998749} \
    CONFIG.PSU__CRL_APB__GEM3_REF_CTRL__FREQMHZ {125} \
    CONFIG.PSU__CRL_APB__GEM3_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__GEM_TSU_REF_CTRL__ACT_FREQMHZ {249.997498} \
    CONFIG.PSU__CRL_APB__GEM_TSU_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__I2C0_REF_CTRL__ACT_FREQMHZ {99.999001} \
    CONFIG.PSU__CRL_APB__I2C0_REF_CTRL__FREQMHZ {100} \
    CONFIG.PSU__CRL_APB__I2C0_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__I2C1_REF_CTRL__ACT_FREQMHZ {99.999001} \
    CONFIG.PSU__CRL_APB__I2C1_REF_CTRL__FREQMHZ {100} \
    CONFIG.PSU__CRL_APB__I2C1_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__IOPLL_CTRL__SRCSEL {PSS_REF_CLK} \
    CONFIG.PSU__CRL_APB__IOU_SWITCH_CTRL__ACT_FREQMHZ {249.997498} \
    CONFIG.PSU__CRL_APB__IOU_SWITCH_CTRL__FREQMHZ {250} \
    CONFIG.PSU__CRL_APB__IOU_SWITCH_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__LPD_LSBUS_CTRL__ACT_FREQMHZ {99.999001} \
    CONFIG.PSU__CRL_APB__LPD_LSBUS_CTRL__FREQMHZ {100} \
    CONFIG.PSU__CRL_APB__LPD_LSBUS_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__LPD_SWITCH_CTRL__ACT_FREQMHZ {499.994995} \
    CONFIG.PSU__CRL_APB__LPD_SWITCH_CTRL__FREQMHZ {500} \
    CONFIG.PSU__CRL_APB__LPD_SWITCH_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__PCAP_CTRL__ACT_FREQMHZ {187.498123} \
    CONFIG.PSU__CRL_APB__PCAP_CTRL__FREQMHZ {200} \
    CONFIG.PSU__CRL_APB__PCAP_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__PL0_REF_CTRL__ACT_FREQMHZ {99.999001} \
    CONFIG.PSU__CRL_APB__PL0_REF_CTRL__FREQMHZ {100} \
    CONFIG.PSU__CRL_APB__PL0_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__QSPI_REF_CTRL__ACT_FREQMHZ {124.998749} \
    CONFIG.PSU__CRL_APB__QSPI_REF_CTRL__FREQMHZ {125} \
    CONFIG.PSU__CRL_APB__QSPI_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__RPLL_CTRL__SRCSEL {PSS_REF_CLK} \
    CONFIG.PSU__CRL_APB__SDIO1_REF_CTRL__ACT_FREQMHZ {187.498123} \
    CONFIG.PSU__CRL_APB__SDIO1_REF_CTRL__FREQMHZ {200} \
    CONFIG.PSU__CRL_APB__SDIO1_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__TIMESTAMP_REF_CTRL__ACT_FREQMHZ {99.999001} \
    CONFIG.PSU__CRL_APB__TIMESTAMP_REF_CTRL__FREQMHZ {100} \
    CONFIG.PSU__CRL_APB__TIMESTAMP_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__UART0_REF_CTRL__ACT_FREQMHZ {99.999001} \
    CONFIG.PSU__CRL_APB__UART0_REF_CTRL__FREQMHZ {100} \
    CONFIG.PSU__CRL_APB__UART0_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__UART1_REF_CTRL__FREQMHZ {100} \
    CONFIG.PSU__CRL_APB__UART1_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__USB0_BUS_REF_CTRL__ACT_FREQMHZ {249.997498} \
    CONFIG.PSU__CRL_APB__USB0_BUS_REF_CTRL__FREQMHZ {250} \
    CONFIG.PSU__CRL_APB__USB0_BUS_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__USB3_DUAL_REF_CTRL__ACT_FREQMHZ {19.999800} \
    CONFIG.PSU__CRL_APB__USB3_DUAL_REF_CTRL__FREQMHZ {20} \
    CONFIG.PSU__CRL_APB__USB3_DUAL_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__USB3__ENABLE {1} \
    CONFIG.PSU__CSUPMU__PERIPHERAL__VALID {1} \
    CONFIG.PSU__DDRC__BG_ADDR_COUNT {1} \
    CONFIG.PSU__DDRC__BRC_MAPPING {ROW_BANK_COL} \
    CONFIG.PSU__DDRC__BUS_WIDTH {64 Bit} \
    CONFIG.PSU__DDRC__CL {15} \
    CONFIG.PSU__DDRC__CLOCK_STOP_EN {0} \
    CONFIG.PSU__DDRC__COMPONENTS {UDIMM} \
    CONFIG.PSU__DDRC__CWL {11} \
    CONFIG.PSU__DDRC__DDR4_ADDR_MAPPING {0} \
    CONFIG.PSU__DDRC__DDR4_CAL_MODE_ENABLE {0} \
    CONFIG.PSU__DDRC__DDR4_CRC_CONTROL {0} \
    CONFIG.PSU__DDRC__DDR4_T_REF_MODE {0} \
    CONFIG.PSU__DDRC__DDR4_T_REF_RANGE {Normal (0-85)} \
    CONFIG.PSU__DDRC__DEVICE_CAPACITY {8192 MBits} \
    CONFIG.PSU__DDRC__DM_DBI {DM_NO_DBI} \
    CONFIG.PSU__DDRC__DRAM_WIDTH {16 Bits} \
    CONFIG.PSU__DDRC__ECC {Disabled} \
    CONFIG.PSU__DDRC__FGRM {1X} \
    CONFIG.PSU__DDRC__LP_ASR {manual normal} \
    CONFIG.PSU__DDRC__MEMORY_TYPE {DDR 4} \
    CONFIG.PSU__DDRC__PARITY_ENABLE {0} \
    CONFIG.PSU__DDRC__PER_BANK_REFRESH {0} \
    CONFIG.PSU__DDRC__PHY_DBI_MODE {0} \
    CONFIG.PSU__DDRC__RANK_ADDR_COUNT {0} \
    CONFIG.PSU__DDRC__ROW_ADDR_COUNT {16} \
    CONFIG.PSU__DDRC__SELF_REF_ABORT {0} \
    CONFIG.PSU__DDRC__SPEED_BIN {DDR4_2133P} \
    CONFIG.PSU__DDRC__STATIC_RD_MODE {0} \
    CONFIG.PSU__DDRC__TRAIN_DATA_EYE {1} \
    CONFIG.PSU__DDRC__TRAIN_READ_GATE {1} \
    CONFIG.PSU__DDRC__TRAIN_WRITE_LEVEL {1} \
    CONFIG.PSU__DDRC__T_FAW {30.0} \
    CONFIG.PSU__DDRC__T_RAS_MIN {33} \
    CONFIG.PSU__DDRC__T_RC {46.5} \
    CONFIG.PSU__DDRC__T_RCD {15} \
    CONFIG.PSU__DDRC__T_RP {15} \
    CONFIG.PSU__DDRC__VREF {1} \
    CONFIG.PSU__DDR_HIGH_ADDRESS_GUI_ENABLE {1} \
    CONFIG.PSU__DDR__INTERFACE__FREQMHZ {533.000} \
    CONFIG.PSU__DLL__ISUSED {1} \
    CONFIG.PSU__ENET3__FIFO__ENABLE {0} \
    CONFIG.PSU__ENET3__GRP_MDIO__ENABLE {1} \
    CONFIG.PSU__ENET3__GRP_MDIO__IO {MIO 76 .. 77} \
    CONFIG.PSU__ENET3__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__ENET3__PERIPHERAL__IO {MIO 64 .. 75} \
    CONFIG.PSU__ENET3__PTP__ENABLE {0} \
    CONFIG.PSU__ENET3__TSU__ENABLE {0} \
    CONFIG.PSU__FPDMASTERS_COHERENCY {0} \
    CONFIG.PSU__FPD_SLCR__WDT1__ACT_FREQMHZ {99.999001} \
    CONFIG.PSU__FPGA_PL0_ENABLE {1} \
    CONFIG.PSU__GEM3_COHERENCY {0} \
    CONFIG.PSU__GEM3_ROUTE_THROUGH_FPD {0} \
    CONFIG.PSU__GEM__TSU__ENABLE {0} \
    CONFIG.PSU__GPIO0_MIO__IO {MIO 0 .. 25} \
    CONFIG.PSU__GPIO0_MIO__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__GPIO1_MIO__IO {MIO 26 .. 51} \
    CONFIG.PSU__GPIO1_MIO__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__I2C0__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__I2C0__PERIPHERAL__IO {MIO 14 .. 15} \
    CONFIG.PSU__I2C1__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__I2C1__PERIPHERAL__IO {MIO 16 .. 17} \
    CONFIG.PSU__IOU_SLCR__IOU_TTC_APB_CLK__TTC0_SEL {APB} \
    CONFIG.PSU__IOU_SLCR__IOU_TTC_APB_CLK__TTC1_SEL {APB} \
    CONFIG.PSU__IOU_SLCR__IOU_TTC_APB_CLK__TTC2_SEL {APB} \
    CONFIG.PSU__IOU_SLCR__IOU_TTC_APB_CLK__TTC3_SEL {APB} \
    CONFIG.PSU__IOU_SLCR__TTC0__ACT_FREQMHZ {100.000000} \
    CONFIG.PSU__IOU_SLCR__TTC1__ACT_FREQMHZ {100.000000} \
    CONFIG.PSU__IOU_SLCR__TTC2__ACT_FREQMHZ {100.000000} \
    CONFIG.PSU__IOU_SLCR__TTC3__ACT_FREQMHZ {100.000000} \
    CONFIG.PSU__IOU_SLCR__WDT0__ACT_FREQMHZ {99.999001} \
    CONFIG.PSU__LPD_SLCR__CSUPMU__ACT_FREQMHZ {100.000000} \
    CONFIG.PSU__MAXIGP0__DATA_WIDTH {128} \
    CONFIG.PSU__OVERRIDE__BASIC_CLOCK {0} \
    CONFIG.PSU__PL_CLK0_BUF {TRUE} \
    CONFIG.PSU__PMU_COHERENCY {0} \
    CONFIG.PSU__PMU__AIBACK__ENABLE {0} \
    CONFIG.PSU__PMU__EMIO_GPI__ENABLE {0} \
    CONFIG.PSU__PMU__EMIO_GPO__ENABLE {0} \
    CONFIG.PSU__PMU__GPI0__ENABLE {0} \
    CONFIG.PSU__PMU__GPI1__ENABLE {0} \
    CONFIG.PSU__PMU__GPI2__ENABLE {0} \
    CONFIG.PSU__PMU__GPI3__ENABLE {0} \
    CONFIG.PSU__PMU__GPI4__ENABLE {0} \
    CONFIG.PSU__PMU__GPI5__ENABLE {0} \
    CONFIG.PSU__PMU__GPO0__ENABLE {0} \
    CONFIG.PSU__PMU__GPO1__ENABLE {0} \
    CONFIG.PSU__PMU__GPO2__ENABLE {0} \
    CONFIG.PSU__PMU__GPO3__ENABLE {0} \
    CONFIG.PSU__PMU__GPO4__ENABLE {0} \
    CONFIG.PSU__PMU__GPO5__ENABLE {0} \
    CONFIG.PSU__PMU__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__PMU__PLERROR__ENABLE {0} \
    CONFIG.PSU__PRESET_APPLIED {1} \
    CONFIG.PSU__PROTECTION__MASTERS {USB1:NonSecure;0|USB0:NonSecure;1|S_AXI_LPD:NA;0|S_AXI_HPC1_FPD:NA;0|S_AXI_HPC0_FPD:NA;0|S_AXI_HP3_FPD:NA;0|S_AXI_HP2_FPD:NA;0|S_AXI_HP1_FPD:NA;1|S_AXI_HP0_FPD:NA;1|S_AXI_ACP:NA;0|S_AXI_ACE:NA;0|SD1:NonSecure;1|SD0:NonSecure;0|SATA1:NonSecure;1|SATA0:NonSecure;1|RPU1:Secure;1|RPU0:Secure;1|QSPI:NonSecure;1|PMU:NA;1|PCIe:NonSecure;0|NAND:NonSecure;0|LDMA:NonSecure;1|GPU:NonSecure;1|GEM3:NonSecure;1|GEM2:NonSecure;0|GEM1:NonSecure;0|GEM0:NonSecure;0|FDMA:NonSecure;1|DP:NonSecure;0|DAP:NA;1|Coresight:NA;1|CSU:NA;1|APU:NA;1}\
\
    CONFIG.PSU__PROTECTION__SLAVES {LPD;USB3_1_XHCI;FE300000;FE3FFFFF;0|LPD;USB3_1;FF9E0000;FF9EFFFF;0|LPD;USB3_0_XHCI;FE200000;FE2FFFFF;1|LPD;USB3_0;FF9D0000;FF9DFFFF;1|LPD;UART1;FF010000;FF01FFFF;0|LPD;UART0;FF000000;FF00FFFF;1|LPD;TTC3;FF140000;FF14FFFF;1|LPD;TTC2;FF130000;FF13FFFF;1|LPD;TTC1;FF120000;FF12FFFF;1|LPD;TTC0;FF110000;FF11FFFF;1|FPD;SWDT1;FD4D0000;FD4DFFFF;1|LPD;SWDT0;FF150000;FF15FFFF;1|LPD;SPI1;FF050000;FF05FFFF;0|LPD;SPI0;FF040000;FF04FFFF;0|FPD;SMMU_REG;FD5F0000;FD5FFFFF;1|FPD;SMMU;FD800000;FDFFFFFF;1|FPD;SIOU;FD3D0000;FD3DFFFF;1|FPD;SERDES;FD400000;FD47FFFF;1|LPD;SD1;FF170000;FF17FFFF;1|LPD;SD0;FF160000;FF16FFFF;0|FPD;SATA;FD0C0000;FD0CFFFF;1|LPD;RTC;FFA60000;FFA6FFFF;1|LPD;RSA_CORE;FFCE0000;FFCEFFFF;1|LPD;RPU;FF9A0000;FF9AFFFF;1|LPD;R5_TCM_RAM_GLOBAL;FFE00000;FFE3FFFF;1|LPD;R5_1_Instruction_Cache;FFEC0000;FFECFFFF;1|LPD;R5_1_Data_Cache;FFED0000;FFEDFFFF;1|LPD;R5_1_BTCM_GLOBAL;FFEB0000;FFEBFFFF;1|LPD;R5_1_ATCM_GLOBAL;FFE90000;FFE9FFFF;1|LPD;R5_0_Instruction_Cache;FFE40000;FFE4FFFF;1|LPD;R5_0_Data_Cache;FFE50000;FFE5FFFF;1|LPD;R5_0_BTCM_GLOBAL;FFE20000;FFE2FFFF;1|LPD;R5_0_ATCM_GLOBAL;FFE00000;FFE0FFFF;1|LPD;QSPI_Linear_Address;C0000000;DFFFFFFF;1|LPD;QSPI;FF0F0000;FF0FFFFF;1|LPD;PMU_RAM;FFDC0000;FFDDFFFF;1|LPD;PMU_GLOBAL;FFD80000;FFDBFFFF;1|FPD;PCIE_MAIN;FD0E0000;FD0EFFFF;0|FPD;PCIE_LOW;E0000000;EFFFFFFF;0|FPD;PCIE_HIGH2;8000000000;BFFFFFFFFF;0|FPD;PCIE_HIGH1;600000000;7FFFFFFFF;0|FPD;PCIE_DMA;FD0F0000;FD0FFFFF;0|FPD;PCIE_ATTRIB;FD480000;FD48FFFF;0|LPD;OCM_XMPU_CFG;FFA70000;FFA7FFFF;1|LPD;OCM_SLCR;FF960000;FF96FFFF;1|OCM;OCM;FFFC0000;FFFFFFFF;1|LPD;NAND;FF100000;FF10FFFF;0|LPD;MBISTJTAG;FFCF0000;FFCFFFFF;1|LPD;LPD_XPPU_SINK;FF9C0000;FF9CFFFF;1|LPD;LPD_XPPU;FF980000;FF98FFFF;1|LPD;LPD_SLCR_SECURE;FF4B0000;FF4DFFFF;1|LPD;LPD_SLCR;FF410000;FF4AFFFF;1|LPD;LPD_GPV;FE100000;FE1FFFFF;1|LPD;LPD_DMA_7;FFAF0000;FFAFFFFF;1|LPD;LPD_DMA_6;FFAE0000;FFAEFFFF;1|LPD;LPD_DMA_5;FFAD0000;FFADFFFF;1|LPD;LPD_DMA_4;FFAC0000;FFACFFFF;1|LPD;LPD_DMA_3;FFAB0000;FFABFFFF;1|LPD;LPD_DMA_2;FFAA0000;FFAAFFFF;1|LPD;LPD_DMA_1;FFA90000;FFA9FFFF;1|LPD;LPD_DMA_0;FFA80000;FFA8FFFF;1|LPD;IPI_CTRL;FF380000;FF3FFFFF;1|LPD;IOU_SLCR;FF180000;FF23FFFF;1|LPD;IOU_SECURE_SLCR;FF240000;FF24FFFF;1|LPD;IOU_SCNTRS;FF260000;FF26FFFF;1|LPD;IOU_SCNTR;FF250000;FF25FFFF;1|LPD;IOU_GPV;FE000000;FE0FFFFF;1|LPD;I2C1;FF030000;FF03FFFF;1|LPD;I2C0;FF020000;FF02FFFF;1|FPD;GPU;FD4B0000;FD4BFFFF;0|LPD;GPIO;FF0A0000;FF0AFFFF;1|LPD;GEM3;FF0E0000;FF0EFFFF;1|LPD;GEM2;FF0D0000;FF0DFFFF;0|LPD;GEM1;FF0C0000;FF0CFFFF;0|LPD;GEM0;FF0B0000;FF0BFFFF;0|FPD;FPD_XMPU_SINK;FD4F0000;FD4FFFFF;1|FPD;FPD_XMPU_CFG;FD5D0000;FD5DFFFF;1|FPD;FPD_SLCR_SECURE;FD690000;FD6CFFFF;1|FPD;FPD_SLCR;FD610000;FD68FFFF;1|FPD;FPD_DMA_CH7;FD570000;FD57FFFF;1|FPD;FPD_DMA_CH6;FD560000;FD56FFFF;1|FPD;FPD_DMA_CH5;FD550000;FD55FFFF;1|FPD;FPD_DMA_CH4;FD540000;FD54FFFF;1|FPD;FPD_DMA_CH3;FD530000;FD53FFFF;1|FPD;FPD_DMA_CH2;FD520000;FD52FFFF;1|FPD;FPD_DMA_CH1;FD510000;FD51FFFF;1|FPD;FPD_DMA_CH0;FD500000;FD50FFFF;1|LPD;EFUSE;FFCC0000;FFCCFFFF;1|FPD;Display\
Port;FD4A0000;FD4AFFFF;0|FPD;DPDMA;FD4C0000;FD4CFFFF;0|FPD;DDR_XMPU5_CFG;FD050000;FD05FFFF;1|FPD;DDR_XMPU4_CFG;FD040000;FD04FFFF;1|FPD;DDR_XMPU3_CFG;FD030000;FD03FFFF;1|FPD;DDR_XMPU2_CFG;FD020000;FD02FFFF;1|FPD;DDR_XMPU1_CFG;FD010000;FD01FFFF;1|FPD;DDR_XMPU0_CFG;FD000000;FD00FFFF;1|FPD;DDR_QOS_CTRL;FD090000;FD09FFFF;1|FPD;DDR_PHY;FD080000;FD08FFFF;1|DDR;DDR_LOW;0;7FFFFFFF;1|DDR;DDR_HIGH;800000000;87FFFFFFF;1|FPD;DDDR_CTRL;FD070000;FD070FFF;1|LPD;Coresight;FE800000;FEFFFFFF;1|LPD;CSU_DMA;FFC80000;FFC9FFFF;1|LPD;CSU;FFCA0000;FFCAFFFF;1|LPD;CRL_APB;FF5E0000;FF85FFFF;1|FPD;CRF_APB;FD1A0000;FD2DFFFF;1|FPD;CCI_REG;FD5E0000;FD5EFFFF;1|LPD;CAN1;FF070000;FF07FFFF;0|LPD;CAN0;FF060000;FF06FFFF;0|FPD;APU;FD5C0000;FD5CFFFF;1|LPD;APM_INTC_IOU;FFA20000;FFA2FFFF;1|LPD;APM_FPD_LPD;FFA30000;FFA3FFFF;1|FPD;APM_5;FD490000;FD49FFFF;1|FPD;APM_0;FD0B0000;FD0BFFFF;1|LPD;APM2;FFA10000;FFA1FFFF;1|LPD;APM1;FFA00000;FFA0FFFF;1|LPD;AMS;FFA50000;FFA5FFFF;1|FPD;AFI_5;FD3B0000;FD3BFFFF;1|FPD;AFI_4;FD3A0000;FD3AFFFF;1|FPD;AFI_3;FD390000;FD39FFFF;1|FPD;AFI_2;FD380000;FD38FFFF;1|FPD;AFI_1;FD370000;FD37FFFF;1|FPD;AFI_0;FD360000;FD36FFFF;1|LPD;AFIFM6;FF9B0000;FF9BFFFF;1|FPD;ACPU_GIC;F9010000;F907FFFF;1}\
\
    CONFIG.PSU__PSS_REF_CLK__FREQMHZ {33.333} \
    CONFIG.PSU__QSPI_COHERENCY {0} \
    CONFIG.PSU__QSPI_ROUTE_THROUGH_FPD {0} \
    CONFIG.PSU__QSPI__GRP_FBCLK__ENABLE {1} \
    CONFIG.PSU__QSPI__GRP_FBCLK__IO {MIO 6} \
    CONFIG.PSU__QSPI__PERIPHERAL__DATA_MODE {x4} \
    CONFIG.PSU__QSPI__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__QSPI__PERIPHERAL__IO {MIO 0 .. 12} \
    CONFIG.PSU__QSPI__PERIPHERAL__MODE {Dual Parallel} \
    CONFIG.PSU__SATA__LANE0__ENABLE {0} \
    CONFIG.PSU__SATA__LANE1__IO {GT Lane3} \
    CONFIG.PSU__SATA__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__SATA__REF_CLK_FREQ {125} \
    CONFIG.PSU__SATA__REF_CLK_SEL {Ref Clk3} \
    CONFIG.PSU__SAXIGP2__DATA_WIDTH {128} \
    CONFIG.PSU__SAXIGP3__DATA_WIDTH {128} \
    CONFIG.PSU__SD1_COHERENCY {0} \
    CONFIG.PSU__SD1_ROUTE_THROUGH_FPD {0} \
    CONFIG.PSU__SD1__CLK_100_SDR_OTAP_DLY {0x3} \
    CONFIG.PSU__SD1__CLK_200_SDR_OTAP_DLY {0x3} \
    CONFIG.PSU__SD1__CLK_50_DDR_ITAP_DLY {0x3D} \
    CONFIG.PSU__SD1__CLK_50_DDR_OTAP_DLY {0x4} \
    CONFIG.PSU__SD1__CLK_50_SDR_ITAP_DLY {0x15} \
    CONFIG.PSU__SD1__CLK_50_SDR_OTAP_DLY {0x5} \
    CONFIG.PSU__SD1__DATA_TRANSFER_MODE {8Bit} \
    CONFIG.PSU__SD1__GRP_CD__ENABLE {1} \
    CONFIG.PSU__SD1__GRP_CD__IO {MIO 45} \
    CONFIG.PSU__SD1__GRP_POW__ENABLE {0} \
    CONFIG.PSU__SD1__GRP_WP__ENABLE {0} \
    CONFIG.PSU__SD1__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__SD1__PERIPHERAL__IO {MIO 39 .. 51} \
    CONFIG.PSU__SD1__SLOT_TYPE {SD 3.0} \
    CONFIG.PSU__SWDT0__CLOCK__ENABLE {0} \
    CONFIG.PSU__SWDT0__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__SWDT0__RESET__ENABLE {0} \
    CONFIG.PSU__SWDT1__CLOCK__ENABLE {0} \
    CONFIG.PSU__SWDT1__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__SWDT1__RESET__ENABLE {0} \
    CONFIG.PSU__TSU__BUFG_PORT_PAIR {0} \
    CONFIG.PSU__TTC0__CLOCK__ENABLE {0} \
    CONFIG.PSU__TTC0__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__TTC0__WAVEOUT__ENABLE {0} \
    CONFIG.PSU__TTC1__CLOCK__ENABLE {0} \
    CONFIG.PSU__TTC1__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__TTC1__WAVEOUT__ENABLE {0} \
    CONFIG.PSU__TTC2__CLOCK__ENABLE {0} \
    CONFIG.PSU__TTC2__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__TTC2__WAVEOUT__ENABLE {0} \
    CONFIG.PSU__TTC3__CLOCK__ENABLE {0} \
    CONFIG.PSU__TTC3__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__TTC3__WAVEOUT__ENABLE {0} \
    CONFIG.PSU__UART0__BAUD_RATE {115200} \
    CONFIG.PSU__UART0__MODEM__ENABLE {0} \
    CONFIG.PSU__UART0__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__UART0__PERIPHERAL__IO {MIO 18 .. 19} \
    CONFIG.PSU__USB0_COHERENCY {0} \
    CONFIG.PSU__USB0__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__USB0__PERIPHERAL__IO {MIO 52 .. 63} \
    CONFIG.PSU__USB0__REF_CLK_FREQ {26} \
    CONFIG.PSU__USB0__REF_CLK_SEL {Ref Clk2} \
    CONFIG.PSU__USB2_0__EMIO__ENABLE {0} \
    CONFIG.PSU__USB3_0__EMIO__ENABLE {0} \
    CONFIG.PSU__USB3_0__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__USB3_0__PERIPHERAL__IO {GT Lane2} \
    CONFIG.PSU__USB__RESET__MODE {Boot Pin} \
    CONFIG.PSU__USB__RESET__POLARITY {Active Low} \
    CONFIG.PSU__USE__IRQ0 {0} \
    CONFIG.PSU__USE__M_AXI_GP0 {1} \
    CONFIG.PSU__USE__M_AXI_GP1 {0} \
    CONFIG.PSU__USE__M_AXI_GP2 {0} \
    CONFIG.PSU__USE__S_AXI_GP2 {1} \
    CONFIG.PSU__USE__S_AXI_GP3 {1} \
  ] $zynq_ultra_ps_e_0


  # Create instance: dc_regs_0, and set properties
  set block_name dc_regs
  set block_cell_name dc_regs_0
  if { [catch {set dc_regs_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $dc_regs_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: launch_regs_0, and set properties
  set block_name launch_regs
  set block_cell_name launch_regs_0
  if { [catch {set launch_regs_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $launch_regs_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: rf_regs_0, and set properties
  set block_name rf_regs
  set block_cell_name rf_regs_0
  if { [catch {set rf_regs_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $rf_regs_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: smartconnect_0, and set properties
  set smartconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_0 ]
  set_property -dict [list \
    CONFIG.NUM_CLKS {2} \
    CONFIG.NUM_MI {34} \
    CONFIG.NUM_SI {1} \
  ] $smartconnect_0


  # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0 ]

  # Create instance: dc_regs_1, and set properties
  set block_name dc_regs
  set block_cell_name dc_regs_1
  if { [catch {set dc_regs_1 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $dc_regs_1 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: dc_regs_2, and set properties
  set block_name dc_regs
  set block_cell_name dc_regs_2
  if { [catch {set dc_regs_2 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $dc_regs_2 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: dc_regs_3, and set properties
  set block_name dc_regs
  set block_cell_name dc_regs_3
  if { [catch {set dc_regs_3 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $dc_regs_3 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: dc_regs_4, and set properties
  set block_name dc_regs
  set block_cell_name dc_regs_4
  if { [catch {set dc_regs_4 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $dc_regs_4 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: dc_regs_5, and set properties
  set block_name dc_regs
  set block_cell_name dc_regs_5
  if { [catch {set dc_regs_5 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $dc_regs_5 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: dc_regs_6, and set properties
  set block_name dc_regs
  set block_cell_name dc_regs_6
  if { [catch {set dc_regs_6 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $dc_regs_6 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: dc_regs_7, and set properties
  set block_name dc_regs
  set block_cell_name dc_regs_7
  if { [catch {set dc_regs_7 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $dc_regs_7 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: dc_regs_8, and set properties
  set block_name dc_regs
  set block_cell_name dc_regs_8
  if { [catch {set dc_regs_8 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $dc_regs_8 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: dc_regs_9, and set properties
  set block_name dc_regs
  set block_cell_name dc_regs_9
  if { [catch {set dc_regs_9 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $dc_regs_9 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: dc_regs_10, and set properties
  set block_name dc_regs
  set block_cell_name dc_regs_10
  if { [catch {set dc_regs_10 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $dc_regs_10 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: dc_regs_11, and set properties
  set block_name dc_regs
  set block_cell_name dc_regs_11
  if { [catch {set dc_regs_11 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $dc_regs_11 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: dc_regs_12, and set properties
  set block_name dc_regs
  set block_cell_name dc_regs_12
  if { [catch {set dc_regs_12 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $dc_regs_12 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: dc_regs_13, and set properties
  set block_name dc_regs
  set block_cell_name dc_regs_13
  if { [catch {set dc_regs_13 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $dc_regs_13 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: dc_regs_14, and set properties
  set block_name dc_regs
  set block_cell_name dc_regs_14
  if { [catch {set dc_regs_14 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $dc_regs_14 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: dc_regs_15, and set properties
  set block_name dc_regs
  set block_cell_name dc_regs_15
  if { [catch {set dc_regs_15 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $dc_regs_15 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: dc_regs_16, and set properties
  set block_name dc_regs
  set block_cell_name dc_regs_16
  if { [catch {set dc_regs_16 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $dc_regs_16 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: dc_regs_17, and set properties
  set block_name dc_regs
  set block_cell_name dc_regs_17
  if { [catch {set dc_regs_17 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $dc_regs_17 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: dc_regs_18, and set properties
  set block_name dc_regs
  set block_cell_name dc_regs_18
  if { [catch {set dc_regs_18 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $dc_regs_18 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: dc_regs_19, and set properties
  set block_name dc_regs
  set block_cell_name dc_regs_19
  if { [catch {set dc_regs_19 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $dc_regs_19 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: dc_regs_20, and set properties
  set block_name dc_regs
  set block_cell_name dc_regs_20
  if { [catch {set dc_regs_20 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $dc_regs_20 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: dc_regs_21, and set properties
  set block_name dc_regs
  set block_cell_name dc_regs_21
  if { [catch {set dc_regs_21 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $dc_regs_21 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: dc_regs_22, and set properties
  set block_name dc_regs
  set block_cell_name dc_regs_22
  if { [catch {set dc_regs_22 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $dc_regs_22 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: dc_regs_23, and set properties
  set block_name dc_regs
  set block_cell_name dc_regs_23
  if { [catch {set dc_regs_23 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $dc_regs_23 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: rf_regs_1, and set properties
  set block_name rf_regs
  set block_cell_name rf_regs_1
  if { [catch {set rf_regs_1 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $rf_regs_1 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: rf_regs_2, and set properties
  set block_name rf_regs
  set block_cell_name rf_regs_2
  if { [catch {set rf_regs_2 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $rf_regs_2 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: rf_regs_3, and set properties
  set block_name rf_regs
  set block_cell_name rf_regs_3
  if { [catch {set rf_regs_3 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $rf_regs_3 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: rf_regs_4, and set properties
  set block_name rf_regs
  set block_cell_name rf_regs_4
  if { [catch {set rf_regs_4 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $rf_regs_4 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: rf_regs_5, and set properties
  set block_name rf_regs
  set block_cell_name rf_regs_5
  if { [catch {set rf_regs_5 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $rf_regs_5 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: usp_rf_data_converter_0, and set properties
  set usp_rf_data_converter_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:usp_rf_data_converter:2.6 usp_rf_data_converter_0 ]
  set_property -dict [list \
    CONFIG.ADC1_Outclk_Freq {250.000} \
    CONFIG.ADC_Data_Type10 {1} \
    CONFIG.ADC_Data_Type11 {1} \
    CONFIG.ADC_Data_Width10 {8} \
    CONFIG.ADC_Decimation_Mode10 {2} \
    CONFIG.ADC_Decimation_Mode11 {2} \
    CONFIG.ADC_Mixer_Type10 {2} \
    CONFIG.ADC_Mixer_Type11 {2} \
    CONFIG.ADC_NCO_Freq10 {0.01} \
    CONFIG.ADC_NCO_Freq11 {0.01} \
    CONFIG.ADC_NCO_RTS {true} \
    CONFIG.ADC_Slice00_Enable {false} \
    CONFIG.ADC_Slice01_Enable {false} \
    CONFIG.ADC_Slice02_Enable {false} \
    CONFIG.ADC_Slice03_Enable {false} \
    CONFIG.ADC_Slice10_Enable {true} \
    CONFIG.ADC_Slice11_Enable {true} \
    CONFIG.ADC_Slice12_Enable {false} \
    CONFIG.ADC_Slice13_Enable {false} \
    CONFIG.ADC_Slice20_Enable {false} \
    CONFIG.ADC_Slice21_Enable {false} \
    CONFIG.ADC_Slice30_Enable {false} \
    CONFIG.ADC_Slice31_Enable {false} \
    CONFIG.DAC0_Clock_Source {5} \
    CONFIG.DAC0_Sampling_Rate {4} \
    CONFIG.DAC0_VOP {40.5} \
    CONFIG.DAC1_Clock_Dist {1} \
    CONFIG.DAC1_Sampling_Rate {4} \
    CONFIG.DAC1_VOP {40.5} \
    CONFIG.DAC2_Clock_Source {5} \
    CONFIG.DAC2_Sampling_Rate {4} \
    CONFIG.DAC2_VOP {40.5} \
    CONFIG.DAC3_Clock_Source {5} \
    CONFIG.DAC3_Sampling_Rate {4} \
    CONFIG.DAC3_VOP {40.5} \
    CONFIG.DAC_Data_Type00 {1} \
    CONFIG.DAC_Data_Type02 {1} \
    CONFIG.DAC_Data_Type10 {1} \
    CONFIG.DAC_Data_Type12 {1} \
    CONFIG.DAC_Data_Type20 {1} \
    CONFIG.DAC_Data_Type22 {1} \
    CONFIG.DAC_Data_Width30 {16} \
    CONFIG.DAC_Interpolation_Mode30 {1} \
    CONFIG.DAC_Interpolation_Mode31 {1} \
    CONFIG.DAC_Mixer_Mode30 {2} \
    CONFIG.DAC_Mixer_Mode31 {2} \
    CONFIG.DAC_Mixer_Type00 {2} \
    CONFIG.DAC_Mixer_Type02 {2} \
    CONFIG.DAC_Mixer_Type10 {2} \
    CONFIG.DAC_Mixer_Type12 {2} \
    CONFIG.DAC_Mixer_Type20 {2} \
    CONFIG.DAC_Mixer_Type22 {2} \
    CONFIG.DAC_Mixer_Type30 {1} \
    CONFIG.DAC_Mixer_Type31 {1} \
    CONFIG.DAC_Mixer_Type32 {2} \
    CONFIG.DAC_Mixer_Type33 {2} \
    CONFIG.DAC_Mode30 {0} \
    CONFIG.DAC_NCO_Freq00 {0.01} \
    CONFIG.DAC_NCO_Freq02 {0.01} \
    CONFIG.DAC_NCO_Freq10 {0.01} \
    CONFIG.DAC_NCO_Freq12 {0.01} \
    CONFIG.DAC_NCO_Freq20 {0.01} \
    CONFIG.DAC_NCO_Freq22 {0.01} \
    CONFIG.DAC_NCO_Freq32 {0.01} \
    CONFIG.DAC_NCO_Freq33 {0.01} \
    CONFIG.DAC_NCO_RTS {true} \
    CONFIG.DAC_RTS {false} \
    CONFIG.DAC_Slice00_Enable {true} \
    CONFIG.DAC_Slice01_Enable {true} \
    CONFIG.DAC_Slice02_Enable {true} \
    CONFIG.DAC_Slice03_Enable {true} \
    CONFIG.DAC_Slice10_Enable {true} \
    CONFIG.DAC_Slice11_Enable {true} \
    CONFIG.DAC_Slice12_Enable {true} \
    CONFIG.DAC_Slice13_Enable {true} \
    CONFIG.DAC_Slice20_Enable {true} \
    CONFIG.DAC_Slice21_Enable {true} \
    CONFIG.DAC_Slice22_Enable {true} \
    CONFIG.DAC_Slice23_Enable {true} \
    CONFIG.DAC_Slice30_Enable {true} \
    CONFIG.DAC_Slice31_Enable {true} \
    CONFIG.DAC_Slice32_Enable {true} \
    CONFIG.DAC_Slice33_Enable {true} \
    CONFIG.DAC_VOP_RTS {false} \
  ] $usp_rf_data_converter_0


  # Create instance: proc_sys_reset_1, and set properties
  set proc_sys_reset_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_1 ]

  # Create instance: li_regs_0, and set properties
  set block_name li_regs
  set block_cell_name li_regs_0
  if { [catch {set li_regs_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $li_regs_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: li_regs_1, and set properties
  set block_name li_regs
  set block_cell_name li_regs_1
  if { [catch {set li_regs_1 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $li_regs_1 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: li_axi_write_0, and set properties
  set block_name li_axi_write
  set block_cell_name li_axi_write_0
  if { [catch {set li_axi_write_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $li_axi_write_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.FREQ_HZ {250000000} \
 ] [get_bd_intf_pins /li_axi_write_0/m_axi]

  # Create instance: li_axi_write_1, and set properties
  set block_name li_axi_write
  set block_cell_name li_axi_write_1
  if { [catch {set li_axi_write_1 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $li_axi_write_1 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.FREQ_HZ {250000000} \
 ] [get_bd_intf_pins /li_axi_write_1/m_axi]

  # Create interface connections
  connect_bd_intf_net -intf_net adc1_clk_0_1 [get_bd_intf_ports adc1_clk_0] [get_bd_intf_pins usp_rf_data_converter_0/adc1_clk]
  connect_bd_intf_net -intf_net adc1_nco_0_1 [get_bd_intf_ports adc1_nco_0] [get_bd_intf_pins usp_rf_data_converter_0/adc1_nco]
  connect_bd_intf_net -intf_net dac0_nco_0_1 [get_bd_intf_ports dac0_nco_0] [get_bd_intf_pins usp_rf_data_converter_0/dac0_nco]
  connect_bd_intf_net -intf_net dac1_clk_0_1 [get_bd_intf_ports dac1_clk_0] [get_bd_intf_pins usp_rf_data_converter_0/dac1_clk]
  connect_bd_intf_net -intf_net dac1_nco_0_1 [get_bd_intf_ports dac1_nco_0] [get_bd_intf_pins usp_rf_data_converter_0/dac1_nco]
  connect_bd_intf_net -intf_net dac2_nco_0_1 [get_bd_intf_ports dac2_nco_0] [get_bd_intf_pins usp_rf_data_converter_0/dac2_nco]
  connect_bd_intf_net -intf_net dac3_nco_0_1 [get_bd_intf_ports dac3_nco_0] [get_bd_intf_pins usp_rf_data_converter_0/dac3_nco]
  connect_bd_intf_net -intf_net li_axi_write_0_m_axi [get_bd_intf_pins li_axi_write_0/m_axi] [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_HP0_FPD]
  connect_bd_intf_net -intf_net li_axi_write_1_m_axi [get_bd_intf_pins li_axi_write_1/m_axi] [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_HP1_FPD]
  connect_bd_intf_net -intf_net s00_axis_0_1 [get_bd_intf_ports s00_axis_0] [get_bd_intf_pins usp_rf_data_converter_0/s00_axis]
  connect_bd_intf_net -intf_net s02_axis_0_1 [get_bd_intf_ports s02_axis_0] [get_bd_intf_pins usp_rf_data_converter_0/s02_axis]
  connect_bd_intf_net -intf_net s10_axis_0_1 [get_bd_intf_ports s10_axis_0] [get_bd_intf_pins usp_rf_data_converter_0/s10_axis]
  connect_bd_intf_net -intf_net s12_axis_0_1 [get_bd_intf_ports s12_axis_0] [get_bd_intf_pins usp_rf_data_converter_0/s12_axis]
  connect_bd_intf_net -intf_net s20_axis_0_1 [get_bd_intf_ports s20_axis_0] [get_bd_intf_pins usp_rf_data_converter_0/s20_axis]
  connect_bd_intf_net -intf_net s22_axis_0_1 [get_bd_intf_ports s22_axis_0] [get_bd_intf_pins usp_rf_data_converter_0/s22_axis]
  connect_bd_intf_net -intf_net s30_axis_0_1 [get_bd_intf_ports s30_axis_0] [get_bd_intf_pins usp_rf_data_converter_0/s30_axis]
  connect_bd_intf_net -intf_net s31_axis_0_1 [get_bd_intf_ports s31_axis_0] [get_bd_intf_pins usp_rf_data_converter_0/s31_axis]
  connect_bd_intf_net -intf_net s32_axis_0_1 [get_bd_intf_ports s32_axis_0] [get_bd_intf_pins usp_rf_data_converter_0/s32_axis]
  connect_bd_intf_net -intf_net s33_axis_0_1 [get_bd_intf_ports s33_axis_0] [get_bd_intf_pins usp_rf_data_converter_0/s33_axis]
  connect_bd_intf_net -intf_net smartconnect_0_M00_AXI [get_bd_intf_pins smartconnect_0/M00_AXI] [get_bd_intf_pins dc_regs_0/s_axi]
  connect_bd_intf_net -intf_net smartconnect_0_M01_AXI [get_bd_intf_pins smartconnect_0/M01_AXI] [get_bd_intf_pins dc_regs_1/s_axi]
  connect_bd_intf_net -intf_net smartconnect_0_M02_AXI [get_bd_intf_pins dc_regs_2/s_axi] [get_bd_intf_pins smartconnect_0/M02_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M03_AXI [get_bd_intf_pins dc_regs_3/s_axi] [get_bd_intf_pins smartconnect_0/M03_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M04_AXI [get_bd_intf_pins dc_regs_4/s_axi] [get_bd_intf_pins smartconnect_0/M04_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M05_AXI [get_bd_intf_pins dc_regs_5/s_axi] [get_bd_intf_pins smartconnect_0/M05_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M06_AXI [get_bd_intf_pins dc_regs_6/s_axi] [get_bd_intf_pins smartconnect_0/M06_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M07_AXI [get_bd_intf_pins dc_regs_7/s_axi] [get_bd_intf_pins smartconnect_0/M07_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M08_AXI [get_bd_intf_pins dc_regs_8/s_axi] [get_bd_intf_pins smartconnect_0/M08_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M09_AXI [get_bd_intf_pins dc_regs_9/s_axi] [get_bd_intf_pins smartconnect_0/M09_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M10_AXI [get_bd_intf_pins dc_regs_10/s_axi] [get_bd_intf_pins smartconnect_0/M10_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M11_AXI [get_bd_intf_pins dc_regs_11/s_axi] [get_bd_intf_pins smartconnect_0/M11_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M12_AXI [get_bd_intf_pins smartconnect_0/M12_AXI] [get_bd_intf_pins dc_regs_12/s_axi]
  connect_bd_intf_net -intf_net smartconnect_0_M13_AXI [get_bd_intf_pins dc_regs_13/s_axi] [get_bd_intf_pins smartconnect_0/M13_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M14_AXI [get_bd_intf_pins dc_regs_14/s_axi] [get_bd_intf_pins smartconnect_0/M14_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M15_AXI [get_bd_intf_pins dc_regs_15/s_axi] [get_bd_intf_pins smartconnect_0/M15_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M16_AXI [get_bd_intf_pins dc_regs_16/s_axi] [get_bd_intf_pins smartconnect_0/M16_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M17_AXI [get_bd_intf_pins dc_regs_17/s_axi] [get_bd_intf_pins smartconnect_0/M17_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M18_AXI [get_bd_intf_pins dc_regs_18/s_axi] [get_bd_intf_pins smartconnect_0/M18_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M19_AXI [get_bd_intf_pins dc_regs_19/s_axi] [get_bd_intf_pins smartconnect_0/M19_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M20_AXI [get_bd_intf_pins smartconnect_0/M20_AXI] [get_bd_intf_pins dc_regs_20/s_axi]
  connect_bd_intf_net -intf_net smartconnect_0_M21_AXI [get_bd_intf_pins dc_regs_21/s_axi] [get_bd_intf_pins smartconnect_0/M21_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M22_AXI [get_bd_intf_pins dc_regs_22/s_axi] [get_bd_intf_pins smartconnect_0/M22_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M23_AXI [get_bd_intf_pins dc_regs_23/s_axi] [get_bd_intf_pins smartconnect_0/M23_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M24_AXI [get_bd_intf_pins rf_regs_0/s_axi] [get_bd_intf_pins smartconnect_0/M24_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M25_AXI [get_bd_intf_pins rf_regs_1/s_axi] [get_bd_intf_pins smartconnect_0/M25_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M26_AXI [get_bd_intf_pins rf_regs_2/s_axi] [get_bd_intf_pins smartconnect_0/M26_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M27_AXI [get_bd_intf_pins rf_regs_3/s_axi] [get_bd_intf_pins smartconnect_0/M27_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M28_AXI [get_bd_intf_pins rf_regs_4/s_axi] [get_bd_intf_pins smartconnect_0/M28_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M29_AXI [get_bd_intf_pins smartconnect_0/M29_AXI] [get_bd_intf_pins rf_regs_5/s_axi]
  connect_bd_intf_net -intf_net smartconnect_0_M30_AXI [get_bd_intf_pins li_regs_0/s_axi] [get_bd_intf_pins smartconnect_0/M30_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M31_AXI [get_bd_intf_pins smartconnect_0/M31_AXI] [get_bd_intf_pins li_regs_1/s_axi]
  connect_bd_intf_net -intf_net smartconnect_0_M32_AXI [get_bd_intf_pins launch_regs_0/s_axi] [get_bd_intf_pins smartconnect_0/M32_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M33_AXI [get_bd_intf_pins smartconnect_0/M33_AXI] [get_bd_intf_pins usp_rf_data_converter_0/s_axi]
  connect_bd_intf_net -intf_net sysref_in_0_1 [get_bd_intf_ports sysref_in_0] [get_bd_intf_pins usp_rf_data_converter_0/sysref_in]
  connect_bd_intf_net -intf_net usp_rf_data_converter_0_m10_axis [get_bd_intf_ports m10_axis_0] [get_bd_intf_pins usp_rf_data_converter_0/m10_axis]
  connect_bd_intf_net -intf_net usp_rf_data_converter_0_m11_axis [get_bd_intf_ports m11_axis_0] [get_bd_intf_pins usp_rf_data_converter_0/m11_axis]
  connect_bd_intf_net -intf_net usp_rf_data_converter_0_vout00 [get_bd_intf_ports vout00_0] [get_bd_intf_pins usp_rf_data_converter_0/vout00]
  connect_bd_intf_net -intf_net usp_rf_data_converter_0_vout01 [get_bd_intf_ports vout01_0] [get_bd_intf_pins usp_rf_data_converter_0/vout01]
  connect_bd_intf_net -intf_net usp_rf_data_converter_0_vout02 [get_bd_intf_ports vout02_0] [get_bd_intf_pins usp_rf_data_converter_0/vout02]
  connect_bd_intf_net -intf_net usp_rf_data_converter_0_vout03 [get_bd_intf_ports vout03_0] [get_bd_intf_pins usp_rf_data_converter_0/vout03]
  connect_bd_intf_net -intf_net usp_rf_data_converter_0_vout10 [get_bd_intf_ports vout10_0] [get_bd_intf_pins usp_rf_data_converter_0/vout10]
  connect_bd_intf_net -intf_net usp_rf_data_converter_0_vout11 [get_bd_intf_ports vout11_0] [get_bd_intf_pins usp_rf_data_converter_0/vout11]
  connect_bd_intf_net -intf_net usp_rf_data_converter_0_vout12 [get_bd_intf_ports vout12_0] [get_bd_intf_pins usp_rf_data_converter_0/vout12]
  connect_bd_intf_net -intf_net usp_rf_data_converter_0_vout13 [get_bd_intf_ports vout13_0] [get_bd_intf_pins usp_rf_data_converter_0/vout13]
  connect_bd_intf_net -intf_net usp_rf_data_converter_0_vout20 [get_bd_intf_ports vout20_0] [get_bd_intf_pins usp_rf_data_converter_0/vout20]
  connect_bd_intf_net -intf_net usp_rf_data_converter_0_vout21 [get_bd_intf_ports vout21_0] [get_bd_intf_pins usp_rf_data_converter_0/vout21]
  connect_bd_intf_net -intf_net usp_rf_data_converter_0_vout22 [get_bd_intf_ports vout22_0] [get_bd_intf_pins usp_rf_data_converter_0/vout22]
  connect_bd_intf_net -intf_net usp_rf_data_converter_0_vout23 [get_bd_intf_ports vout23_0] [get_bd_intf_pins usp_rf_data_converter_0/vout23]
  connect_bd_intf_net -intf_net usp_rf_data_converter_0_vout30 [get_bd_intf_ports vout30_0] [get_bd_intf_pins usp_rf_data_converter_0/vout30]
  connect_bd_intf_net -intf_net usp_rf_data_converter_0_vout31 [get_bd_intf_ports vout31_0] [get_bd_intf_pins usp_rf_data_converter_0/vout31]
  connect_bd_intf_net -intf_net usp_rf_data_converter_0_vout32 [get_bd_intf_ports vout32_0] [get_bd_intf_pins usp_rf_data_converter_0/vout32]
  connect_bd_intf_net -intf_net usp_rf_data_converter_0_vout33 [get_bd_intf_ports vout33_0] [get_bd_intf_pins usp_rf_data_converter_0/vout33]
  connect_bd_intf_net -intf_net vin10_0_1 [get_bd_intf_ports vin10_0] [get_bd_intf_pins usp_rf_data_converter_0/vin10]
  connect_bd_intf_net -intf_net vin11_0_1 [get_bd_intf_ports vin11_0] [get_bd_intf_pins usp_rf_data_converter_0/vin11]
  connect_bd_intf_net -intf_net zynq_ultra_ps_e_0_M_AXI_HPM0_FPD [get_bd_intf_pins zynq_ultra_ps_e_0/M_AXI_HPM0_FPD] [get_bd_intf_pins smartconnect_0/S00_AXI]

  # Create port connections
  connect_bd_net -net dc_regs_0_o_ctrl_regs  [get_bd_pins dc_regs_0/o_ctrl_regs] \
  [get_bd_ports o_dc_ctrl_regs0]
  connect_bd_net -net dc_regs_0_o_seq_regs  [get_bd_pins dc_regs_0/o_seq_regs] \
  [get_bd_ports o_dc_seq_regs0]
  connect_bd_net -net dc_regs_10_o_ctrl_regs  [get_bd_pins dc_regs_10/o_ctrl_regs] \
  [get_bd_ports o_dc_ctrl_regs10]
  connect_bd_net -net dc_regs_10_o_seq_regs  [get_bd_pins dc_regs_10/o_seq_regs] \
  [get_bd_ports o_dc_seq_regs10]
  connect_bd_net -net dc_regs_11_o_ctrl_regs  [get_bd_pins dc_regs_11/o_ctrl_regs] \
  [get_bd_ports o_dc_ctrl_regs11]
  connect_bd_net -net dc_regs_11_o_seq_regs  [get_bd_pins dc_regs_11/o_seq_regs] \
  [get_bd_ports o_dc_seq_regs11]
  connect_bd_net -net dc_regs_12_o_ctrl_regs  [get_bd_pins dc_regs_12/o_ctrl_regs] \
  [get_bd_ports o_dc_ctrl_regs12]
  connect_bd_net -net dc_regs_12_o_seq_regs  [get_bd_pins dc_regs_12/o_seq_regs] \
  [get_bd_ports o_dc_seq_regs12]
  connect_bd_net -net dc_regs_13_o_ctrl_regs  [get_bd_pins dc_regs_13/o_ctrl_regs] \
  [get_bd_ports o_dc_ctrl_regs13]
  connect_bd_net -net dc_regs_13_o_seq_regs  [get_bd_pins dc_regs_13/o_seq_regs] \
  [get_bd_ports o_dc_seq_regs13]
  connect_bd_net -net dc_regs_14_o_ctrl_regs  [get_bd_pins dc_regs_14/o_ctrl_regs] \
  [get_bd_ports o_dc_ctrl_regs14]
  connect_bd_net -net dc_regs_14_o_seq_regs  [get_bd_pins dc_regs_14/o_seq_regs] \
  [get_bd_ports o_dc_seq_regs14]
  connect_bd_net -net dc_regs_15_o_ctrl_regs  [get_bd_pins dc_regs_15/o_ctrl_regs] \
  [get_bd_ports o_dc_ctrl_regs15]
  connect_bd_net -net dc_regs_15_o_seq_regs  [get_bd_pins dc_regs_15/o_seq_regs] \
  [get_bd_ports o_dc_seq_regs15]
  connect_bd_net -net dc_regs_16_o_ctrl_regs  [get_bd_pins dc_regs_16/o_ctrl_regs] \
  [get_bd_ports o_dc_ctrl_regs16]
  connect_bd_net -net dc_regs_16_o_seq_regs  [get_bd_pins dc_regs_16/o_seq_regs] \
  [get_bd_ports o_dc_seq_regs16]
  connect_bd_net -net dc_regs_17_o_ctrl_regs  [get_bd_pins dc_regs_17/o_ctrl_regs] \
  [get_bd_ports o_dc_ctrl_regs17]
  connect_bd_net -net dc_regs_17_o_seq_regs  [get_bd_pins dc_regs_17/o_seq_regs] \
  [get_bd_ports o_dc_seq_regs17]
  connect_bd_net -net dc_regs_18_o_ctrl_regs  [get_bd_pins dc_regs_18/o_ctrl_regs] \
  [get_bd_ports o_dc_ctrl_regs18]
  connect_bd_net -net dc_regs_18_o_seq_regs  [get_bd_pins dc_regs_18/o_seq_regs] \
  [get_bd_ports o_dc_seq_regs18]
  connect_bd_net -net dc_regs_19_o_ctrl_regs  [get_bd_pins dc_regs_19/o_ctrl_regs] \
  [get_bd_ports o_dc_ctrl_regs19]
  connect_bd_net -net dc_regs_19_o_seq_regs  [get_bd_pins dc_regs_19/o_seq_regs] \
  [get_bd_ports o_dc_seq_regs19]
  connect_bd_net -net dc_regs_1_o_ctrl_regs  [get_bd_pins dc_regs_1/o_ctrl_regs] \
  [get_bd_ports o_dc_ctrl_regs1]
  connect_bd_net -net dc_regs_1_o_seq_regs  [get_bd_pins dc_regs_1/o_seq_regs] \
  [get_bd_ports o_dc_seq_regs1]
  connect_bd_net -net dc_regs_20_o_ctrl_regs  [get_bd_pins dc_regs_20/o_ctrl_regs] \
  [get_bd_ports o_dc_ctrl_regs20]
  connect_bd_net -net dc_regs_20_o_seq_regs  [get_bd_pins dc_regs_20/o_seq_regs] \
  [get_bd_ports o_dc_seq_regs20]
  connect_bd_net -net dc_regs_21_o_ctrl_regs  [get_bd_pins dc_regs_21/o_ctrl_regs] \
  [get_bd_ports o_dc_ctrl_regs21]
  connect_bd_net -net dc_regs_21_o_seq_regs  [get_bd_pins dc_regs_21/o_seq_regs] \
  [get_bd_ports o_dc_seq_regs21]
  connect_bd_net -net dc_regs_22_o_ctrl_regs  [get_bd_pins dc_regs_22/o_ctrl_regs] \
  [get_bd_ports o_dc_ctrl_regs22]
  connect_bd_net -net dc_regs_22_o_seq_regs  [get_bd_pins dc_regs_22/o_seq_regs] \
  [get_bd_ports o_dc_seq_regs22]
  connect_bd_net -net dc_regs_23_o_ctrl_regs  [get_bd_pins dc_regs_23/o_ctrl_regs] \
  [get_bd_ports o_dc_ctrl_regs23]
  connect_bd_net -net dc_regs_23_o_seq_regs  [get_bd_pins dc_regs_23/o_seq_regs] \
  [get_bd_ports o_dc_seq_regs23]
  connect_bd_net -net dc_regs_2_o_ctrl_regs  [get_bd_pins dc_regs_2/o_ctrl_regs] \
  [get_bd_ports o_dc_ctrl_regs2]
  connect_bd_net -net dc_regs_2_o_seq_regs  [get_bd_pins dc_regs_2/o_seq_regs] \
  [get_bd_ports o_dc_seq_regs2]
  connect_bd_net -net dc_regs_3_o_ctrl_regs  [get_bd_pins dc_regs_3/o_ctrl_regs] \
  [get_bd_ports o_dc_ctrl_regs3]
  connect_bd_net -net dc_regs_3_o_seq_regs  [get_bd_pins dc_regs_3/o_seq_regs] \
  [get_bd_ports o_dc_seq_regs3]
  connect_bd_net -net dc_regs_4_o_ctrl_regs  [get_bd_pins dc_regs_4/o_ctrl_regs] \
  [get_bd_ports o_dc_ctrl_regs4]
  connect_bd_net -net dc_regs_4_o_seq_regs  [get_bd_pins dc_regs_4/o_seq_regs] \
  [get_bd_ports o_dc_seq_regs4]
  connect_bd_net -net dc_regs_5_o_ctrl_regs  [get_bd_pins dc_regs_5/o_ctrl_regs] \
  [get_bd_ports o_dc_ctrl_regs5]
  connect_bd_net -net dc_regs_5_o_seq_regs  [get_bd_pins dc_regs_5/o_seq_regs] \
  [get_bd_ports o_dc_seq_regs5]
  connect_bd_net -net dc_regs_6_o_ctrl_regs  [get_bd_pins dc_regs_6/o_ctrl_regs] \
  [get_bd_ports o_dc_ctrl_regs6]
  connect_bd_net -net dc_regs_6_o_seq_regs  [get_bd_pins dc_regs_6/o_seq_regs] \
  [get_bd_ports o_dc_seq_regs6]
  connect_bd_net -net dc_regs_7_o_ctrl_regs  [get_bd_pins dc_regs_7/o_ctrl_regs] \
  [get_bd_ports o_dc_ctrl_regs7]
  connect_bd_net -net dc_regs_7_o_seq_regs  [get_bd_pins dc_regs_7/o_seq_regs] \
  [get_bd_ports o_dc_seq_regs7]
  connect_bd_net -net dc_regs_8_o_ctrl_regs  [get_bd_pins dc_regs_8/o_ctrl_regs] \
  [get_bd_ports o_dc_ctrl_regs8]
  connect_bd_net -net dc_regs_8_o_seq_regs  [get_bd_pins dc_regs_8/o_seq_regs] \
  [get_bd_ports o_dc_seq_regs8]
  connect_bd_net -net dc_regs_9_o_ctrl_regs  [get_bd_pins dc_regs_9/o_ctrl_regs] \
  [get_bd_ports o_dc_ctrl_regs9]
  connect_bd_net -net dc_regs_9_o_seq_regs  [get_bd_pins dc_regs_9/o_seq_regs] \
  [get_bd_ports o_dc_seq_regs9]
  connect_bd_net -net i_QIx4_0_1  [get_bd_ports i_li_QIx4_0] \
  [get_bd_pins li_axi_write_0/i_QIx4]
  connect_bd_net -net i_QIx4_0_2  [get_bd_ports i_li_QIx4_1] \
  [get_bd_pins li_axi_write_1/i_QIx4]
  connect_bd_net -net i_ctrl_0_1  [get_bd_ports i_li_ctrl_0] \
  [get_bd_pins li_axi_write_0/i_ctrl]
  connect_bd_net -net i_ctrl_0_2  [get_bd_ports i_li_ctrl_1] \
  [get_bd_pins li_axi_write_1/i_ctrl]
  connect_bd_net -net i_last_0_1  [get_bd_ports i_li_last_0] \
  [get_bd_pins li_axi_write_0/i_last]
  connect_bd_net -net i_last_0_2  [get_bd_ports i_li_last_1] \
  [get_bd_pins li_axi_write_1/i_last]
  connect_bd_net -net i_li_validx4_1  [get_bd_ports i_li_validx4_0] \
  [get_bd_pins li_axi_write_0/i_validx4]
  connect_bd_net -net i_li_validx4_1_1  [get_bd_ports i_li_validx4_1] \
  [get_bd_pins li_axi_write_1/i_validx4]
  connect_bd_net -net launch_regs_0_o_regs  [get_bd_pins launch_regs_0/o_regs] \
  [get_bd_ports o_lch_regs]
  connect_bd_net -net li_regs_0_o_ctrl_regs  [get_bd_pins li_regs_0/o_ctrl_regs] \
  [get_bd_ports o_li_ctrl_regs0]
  connect_bd_net -net li_regs_0_o_seq_regs  [get_bd_pins li_regs_0/o_seq_regs] \
  [get_bd_ports o_li_seq_regs0]
  connect_bd_net -net li_regs_1_o_ctrl_regs  [get_bd_pins li_regs_1/o_ctrl_regs] \
  [get_bd_ports o_li_ctrl_regs1]
  connect_bd_net -net li_regs_1_o_seq_regs  [get_bd_pins li_regs_1/o_seq_regs] \
  [get_bd_ports o_li_seq_regs1]
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn  [get_bd_pins proc_sys_reset_0/peripheral_aresetn] \
  [get_bd_pins smartconnect_0/aresetn] \
  [get_bd_pins usp_rf_data_converter_0/s_axi_aresetn]
  connect_bd_net -net proc_sys_reset_1_peripheral_aresetn  [get_bd_pins proc_sys_reset_1/peripheral_aresetn] \
  [get_bd_pins usp_rf_data_converter_0/m1_axis_aresetn] \
  [get_bd_pins usp_rf_data_converter_0/s0_axis_aresetn] \
  [get_bd_pins usp_rf_data_converter_0/s1_axis_aresetn] \
  [get_bd_pins usp_rf_data_converter_0/s2_axis_aresetn] \
  [get_bd_pins dc_regs_0/s_axi_aresetn] \
  [get_bd_pins dc_regs_1/s_axi_aresetn] \
  [get_bd_pins dc_regs_2/s_axi_aresetn] \
  [get_bd_pins dc_regs_10/s_axi_aresetn] \
  [get_bd_pins dc_regs_11/s_axi_aresetn] \
  [get_bd_pins dc_regs_12/s_axi_aresetn] \
  [get_bd_pins dc_regs_13/s_axi_aresetn] \
  [get_bd_pins dc_regs_14/s_axi_aresetn] \
  [get_bd_pins dc_regs_15/s_axi_aresetn] \
  [get_bd_pins dc_regs_16/s_axi_aresetn] \
  [get_bd_pins dc_regs_17/s_axi_aresetn] \
  [get_bd_pins dc_regs_18/s_axi_aresetn] \
  [get_bd_pins dc_regs_19/s_axi_aresetn] \
  [get_bd_pins dc_regs_20/s_axi_aresetn] \
  [get_bd_pins dc_regs_21/s_axi_aresetn] \
  [get_bd_pins dc_regs_22/s_axi_aresetn] \
  [get_bd_pins dc_regs_23/s_axi_aresetn] \
  [get_bd_pins dc_regs_3/s_axi_aresetn] \
  [get_bd_pins dc_regs_4/s_axi_aresetn] \
  [get_bd_pins dc_regs_5/s_axi_aresetn] \
  [get_bd_pins dc_regs_6/s_axi_aresetn] \
  [get_bd_pins dc_regs_7/s_axi_aresetn] \
  [get_bd_pins dc_regs_8/s_axi_aresetn] \
  [get_bd_pins dc_regs_9/s_axi_aresetn] \
  [get_bd_pins launch_regs_0/s_axi_aresetn] \
  [get_bd_pins rf_regs_0/s_axi_aresetn] \
  [get_bd_pins rf_regs_1/s_axi_aresetn] \
  [get_bd_pins rf_regs_2/s_axi_aresetn] \
  [get_bd_pins rf_regs_3/s_axi_aresetn] \
  [get_bd_pins rf_regs_4/s_axi_aresetn] \
  [get_bd_pins rf_regs_5/s_axi_aresetn] \
  [get_bd_ports dcrfli_rst_n] \
  [get_bd_pins li_regs_1/s_axi_aresetn] \
  [get_bd_pins li_regs_0/s_axi_aresetn] \
  [get_bd_pins li_axi_write_0/s_axi_aresetn] \
  [get_bd_pins li_axi_write_1/s_axi_aresetn] \
  [get_bd_pins usp_rf_data_converter_0/s3_axis_aresetn]
  connect_bd_net -net rf_regs_0_o_ctrl_regs  [get_bd_pins rf_regs_0/o_ctrl_regs] \
  [get_bd_ports o_rf_ctrl_regs0]
  connect_bd_net -net rf_regs_0_o_seq_regs  [get_bd_pins rf_regs_0/o_seq_regs] \
  [get_bd_ports o_rf_seq_regs0]
  connect_bd_net -net rf_regs_1_o_ctrl_regs  [get_bd_pins rf_regs_1/o_ctrl_regs] \
  [get_bd_ports o_rf_ctrl_regs1]
  connect_bd_net -net rf_regs_1_o_seq_regs  [get_bd_pins rf_regs_1/o_seq_regs] \
  [get_bd_ports o_rf_seq_regs1]
  connect_bd_net -net rf_regs_2_o_ctrl_regs  [get_bd_pins rf_regs_2/o_ctrl_regs] \
  [get_bd_ports o_rf_ctrl_regs2]
  connect_bd_net -net rf_regs_2_o_seq_regs  [get_bd_pins rf_regs_2/o_seq_regs] \
  [get_bd_ports o_rf_seq_regs2]
  connect_bd_net -net rf_regs_3_o_ctrl_regs  [get_bd_pins rf_regs_3/o_ctrl_regs] \
  [get_bd_ports o_rf_ctrl_regs3]
  connect_bd_net -net rf_regs_3_o_seq_regs  [get_bd_pins rf_regs_3/o_seq_regs] \
  [get_bd_ports o_rf_seq_regs3]
  connect_bd_net -net rf_regs_4_o_ctrl_regs  [get_bd_pins rf_regs_4/o_ctrl_regs] \
  [get_bd_ports o_rf_ctrl_regs4]
  connect_bd_net -net rf_regs_4_o_seq_regs  [get_bd_pins rf_regs_4/o_seq_regs] \
  [get_bd_ports o_rf_seq_regs4]
  connect_bd_net -net rf_regs_5_o_ctrl_regs  [get_bd_pins rf_regs_5/o_ctrl_regs] \
  [get_bd_ports o_rf_ctrl_regs5]
  connect_bd_net -net rf_regs_5_o_seq_regs  [get_bd_pins rf_regs_5/o_seq_regs] \
  [get_bd_ports o_rf_seq_regs5]
  connect_bd_net -net usp_rf_data_converter_0_clk_dac1  [get_bd_pins usp_rf_data_converter_0/clk_dac1] \
  [get_bd_ports clk_dac1_0]
  connect_bd_net -net util_ds_buf_0_BUFG_O  [get_bd_ports dcrfli_clk] \
  [get_bd_pins proc_sys_reset_1/slowest_sync_clk] \
  [get_bd_pins smartconnect_0/aclk] \
  [get_bd_pins usp_rf_data_converter_0/m1_axis_aclk] \
  [get_bd_pins usp_rf_data_converter_0/s0_axis_aclk] \
  [get_bd_pins usp_rf_data_converter_0/s1_axis_aclk] \
  [get_bd_pins usp_rf_data_converter_0/s2_axis_aclk] \
  [get_bd_pins zynq_ultra_ps_e_0/saxihp1_fpd_aclk] \
  [get_bd_pins zynq_ultra_ps_e_0/saxihp0_fpd_aclk] \
  [get_bd_pins dc_regs_0/s_axi_aclk] \
  [get_bd_pins dc_regs_1/s_axi_aclk] \
  [get_bd_pins dc_regs_2/s_axi_aclk] \
  [get_bd_pins dc_regs_10/s_axi_aclk] \
  [get_bd_pins dc_regs_11/s_axi_aclk] \
  [get_bd_pins dc_regs_12/s_axi_aclk] \
  [get_bd_pins dc_regs_13/s_axi_aclk] \
  [get_bd_pins dc_regs_14/s_axi_aclk] \
  [get_bd_pins dc_regs_15/s_axi_aclk] \
  [get_bd_pins dc_regs_16/s_axi_aclk] \
  [get_bd_pins dc_regs_17/s_axi_aclk] \
  [get_bd_pins dc_regs_18/s_axi_aclk] \
  [get_bd_pins dc_regs_19/s_axi_aclk] \
  [get_bd_pins dc_regs_20/s_axi_aclk] \
  [get_bd_pins dc_regs_21/s_axi_aclk] \
  [get_bd_pins dc_regs_22/s_axi_aclk] \
  [get_bd_pins dc_regs_23/s_axi_aclk] \
  [get_bd_pins dc_regs_3/s_axi_aclk] \
  [get_bd_pins dc_regs_4/s_axi_aclk] \
  [get_bd_pins dc_regs_5/s_axi_aclk] \
  [get_bd_pins dc_regs_6/s_axi_aclk] \
  [get_bd_pins dc_regs_7/s_axi_aclk] \
  [get_bd_pins dc_regs_8/s_axi_aclk] \
  [get_bd_pins dc_regs_9/s_axi_aclk] \
  [get_bd_pins launch_regs_0/s_axi_aclk] \
  [get_bd_pins rf_regs_0/s_axi_aclk] \
  [get_bd_pins rf_regs_1/s_axi_aclk] \
  [get_bd_pins rf_regs_2/s_axi_aclk] \
  [get_bd_pins rf_regs_3/s_axi_aclk] \
  [get_bd_pins rf_regs_4/s_axi_aclk] \
  [get_bd_pins rf_regs_5/s_axi_aclk] \
  [get_bd_pins li_regs_0/s_axi_aclk] \
  [get_bd_pins li_regs_1/s_axi_aclk] \
  [get_bd_pins li_axi_write_0/s_axi_aclk] \
  [get_bd_pins li_axi_write_1/s_axi_aclk] \
  [get_bd_pins usp_rf_data_converter_0/s3_axis_aclk]
  connect_bd_net -net zynq_ultra_ps_e_0_pl_clk0  [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] \
  [get_bd_pins smartconnect_0/aclk1] \
  [get_bd_pins proc_sys_reset_0/slowest_sync_clk] \
  [get_bd_pins zynq_ultra_ps_e_0/maxihpm0_fpd_aclk] \
  [get_bd_pins usp_rf_data_converter_0/s_axi_aclk]
  connect_bd_net -net zynq_ultra_ps_e_0_pl_resetn0  [get_bd_pins zynq_ultra_ps_e_0/pl_resetn0] \
  [get_bd_pins proc_sys_reset_0/ext_reset_in] \
  [get_bd_pins proc_sys_reset_1/ext_reset_in]

  # Create address segments
  assign_bd_address -offset 0xA0000000 -range 0x00001000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs dc_regs_0/s_axi/reg0] -force
  assign_bd_address -offset 0xA000A000 -range 0x00001000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs dc_regs_10/s_axi/reg0] -force
  assign_bd_address -offset 0xA000B000 -range 0x00001000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs dc_regs_11/s_axi/reg0] -force
  assign_bd_address -offset 0xA000C000 -range 0x00001000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs dc_regs_12/s_axi/reg0] -force
  assign_bd_address -offset 0xA000D000 -range 0x00001000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs dc_regs_13/s_axi/reg0] -force
  assign_bd_address -offset 0xA000E000 -range 0x00001000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs dc_regs_14/s_axi/reg0] -force
  assign_bd_address -offset 0xA000F000 -range 0x00001000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs dc_regs_15/s_axi/reg0] -force
  assign_bd_address -offset 0xA0010000 -range 0x00001000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs dc_regs_16/s_axi/reg0] -force
  assign_bd_address -offset 0xA0011000 -range 0x00001000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs dc_regs_17/s_axi/reg0] -force
  assign_bd_address -offset 0xA0012000 -range 0x00001000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs dc_regs_18/s_axi/reg0] -force
  assign_bd_address -offset 0xA0013000 -range 0x00001000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs dc_regs_19/s_axi/reg0] -force
  assign_bd_address -offset 0xA0001000 -range 0x00001000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs dc_regs_1/s_axi/reg0] -force
  assign_bd_address -offset 0xA0014000 -range 0x00001000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs dc_regs_20/s_axi/reg0] -force
  assign_bd_address -offset 0xA0015000 -range 0x00001000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs dc_regs_21/s_axi/reg0] -force
  assign_bd_address -offset 0xA0016000 -range 0x00001000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs dc_regs_22/s_axi/reg0] -force
  assign_bd_address -offset 0xA0017000 -range 0x00001000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs dc_regs_23/s_axi/reg0] -force
  assign_bd_address -offset 0xA0002000 -range 0x00001000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs dc_regs_2/s_axi/reg0] -force
  assign_bd_address -offset 0xA0003000 -range 0x00001000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs dc_regs_3/s_axi/reg0] -force
  assign_bd_address -offset 0xA0004000 -range 0x00001000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs dc_regs_4/s_axi/reg0] -force
  assign_bd_address -offset 0xA0005000 -range 0x00001000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs dc_regs_5/s_axi/reg0] -force
  assign_bd_address -offset 0xA0006000 -range 0x00001000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs dc_regs_6/s_axi/reg0] -force
  assign_bd_address -offset 0xA0007000 -range 0x00001000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs dc_regs_7/s_axi/reg0] -force
  assign_bd_address -offset 0xA0008000 -range 0x00001000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs dc_regs_8/s_axi/reg0] -force
  assign_bd_address -offset 0xA0009000 -range 0x00001000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs dc_regs_9/s_axi/reg0] -force
  assign_bd_address -offset 0xA0020000 -range 0x00001000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs launch_regs_0/s_axi/reg0] -force
  assign_bd_address -offset 0xA001E000 -range 0x00001000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs li_regs_0/s_axi/reg0] -force
  assign_bd_address -offset 0xA001F000 -range 0x00001000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs li_regs_1/s_axi/reg0] -force
  assign_bd_address -offset 0xA0018000 -range 0x00001000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs rf_regs_0/s_axi/reg0] -force
  assign_bd_address -offset 0xA0019000 -range 0x00001000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs rf_regs_1/s_axi/reg0] -force
  assign_bd_address -offset 0xA001A000 -range 0x00001000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs rf_regs_2/s_axi/reg0] -force
  assign_bd_address -offset 0xA001B000 -range 0x00001000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs rf_regs_3/s_axi/reg0] -force
  assign_bd_address -offset 0xA001C000 -range 0x00001000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs rf_regs_4/s_axi/reg0] -force
  assign_bd_address -offset 0xA001D000 -range 0x00001000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs rf_regs_5/s_axi/reg0] -force
  assign_bd_address -offset 0xA0040000 -range 0x00040000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs usp_rf_data_converter_0/s_axi/Reg] -force
  assign_bd_address -offset 0x000800000000 -range 0x000800000000 -target_address_space [get_bd_addr_spaces li_axi_write_0/m_axi] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_DDR_HIGH] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces li_axi_write_0/m_axi] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_DDR_LOW] -force
  assign_bd_address -offset 0xFF000000 -range 0x01000000 -target_address_space [get_bd_addr_spaces li_axi_write_0/m_axi] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_LPS_OCM] -force
  assign_bd_address -offset 0xC0000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces li_axi_write_0/m_axi] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_QSPI] -force
  assign_bd_address -offset 0x000800000000 -range 0x000800000000 -target_address_space [get_bd_addr_spaces li_axi_write_1/m_axi] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP3/HP1_DDR_HIGH] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces li_axi_write_1/m_axi] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP3/HP1_DDR_LOW] -force
  assign_bd_address -offset 0xFF000000 -range 0x01000000 -target_address_space [get_bd_addr_spaces li_axi_write_1/m_axi] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP3/HP1_LPS_OCM] -force
  assign_bd_address -offset 0xC0000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces li_axi_write_1/m_axi] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP3/HP1_QSPI] -force


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


