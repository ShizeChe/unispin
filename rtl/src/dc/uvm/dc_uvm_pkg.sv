`timescale 1ns/1ps

// NOTE: intentionally *not* wrapped in `package ... endpackage`. A
// SystemVerilog package cannot reference declarations made in $unit
// (compilation-unit) scope, and dc.svh's typedefs/parameters (dc_insn_t,
// dc_ctrl_t, DC_*) are declared at $unit scope so the plain-Verilog RTL can
// use them too. Collecting these classes at $unit scope instead of forcing
// them into a package keeps them able to see those types directly.
//
// Include from dc_tb.sv *after* dc.svh and components/dc_if.sv, since
// dc_driver / dc_monitor below reference dc_input_if / dc_output_if.
import uvm_pkg::*;
`include "uvm_macros.svh"

// Minimum SPI hold-cycle budget a dc_program instruction must leave.
// Currently unused inside dc_program's body; reserved as the value its
// insn_min_hold_cycles_cons constraint should eventually reference.
parameter int MIN_HOLD_CYCLES = 64;

// Analysis imp declarations used by dc_scoreboard
`uvm_analysis_imp_decl(_exp)
`uvm_analysis_imp_decl(_act)

`include "transactions/dc_program.sv"
`include "transactions/dc_trace.sv"
`include "components/dc_sequencer.sv"
`include "components/dc_driver.sv"
`include "components/dc_monitor.sv"
`include "components/dc_model.sv"
`include "components/dc_scoreboard.sv"
`include "components/dc_agent.sv"
`include "components/dc_env.sv"
`include "dc_test.sv"
