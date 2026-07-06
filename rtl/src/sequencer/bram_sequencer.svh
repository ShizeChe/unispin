`ifndef BRAM_SEQUENCER_DEFINES
`define BRAM_SEQUENCER_DEFINES

// bram_sequencer's i_regs map. Offsets from IST_REG_HI onward shift with
// REG_PER_INSN (== (INSN_WIDTH+31)/32 of the instantiating core), so those
// are macros taking REG_PER_INSN as an argument rather than plain constants.

/*************
* pcmem store
*************/
`define PCST_ADDR_REG 0                    // PCMEM address to write (or, with PCLD_STRB_REG, to read)
`define PCST_REG      (`PCST_ADDR_REG + 1) // PC value to write into PCMEM at PCST_ADDR_REG
`define PCST_STRB_REG (`PCST_REG + 1)      // pulse to commit PCST_REG into PCMEM[PCST_ADDR_REG]

/************
* imem store
************/
`define IST_ADDR_REG               (`PCST_STRB_REG + 1) // IMEM address to write (or, with ILD_STRB_REG, to read)
`define IST_REG_LO                 (`IST_ADDR_REG + 1)  // first of the REG_PER_INSN words holding the instruction
`define IST_REG_HI(REG_PER_INSN)   (`IST_REG_LO + (REG_PER_INSN) - 1) // last of those instruction words
`define IST_STRB_REG(REG_PER_INSN) (`IST_REG_HI(REG_PER_INSN) + 1)    // pulse to commit IST_REG_LO..HI into IMEM[IST_ADDR_REG]

/**********
* pc stage
**********/
`define ITERS_REG(REG_PER_INSN)      (`IST_STRB_REG(REG_PER_INSN) + 1) // iteration count latched when START_STRB_REG pulses
`define DEPTH_REG(REG_PER_INSN)      (`ITERS_REG(REG_PER_INSN) + 1)    // inclusive last PC address of the program, latched with ITERS_REG
`define START_STRB_REG(REG_PER_INSN) (`DEPTH_REG(REG_PER_INSN) + 1)    // pulse to arm the sequencer and start stepping from PC 0
`define HALT_STRB_REG(REG_PER_INSN)  (`START_STRB_REG(REG_PER_INSN) + 1) // pulse to stop stepping and clear iters/active
`define PCLD_STRB_REG(REG_PER_INSN)  (`HALT_STRB_REG(REG_PER_INSN) + 1)  // pulse to read PCMEM[PCST_ADDR_REG] out to o_pc_rd
`define ILD_STRB_REG(REG_PER_INSN)   (`PCLD_STRB_REG(REG_PER_INSN) + 1)  // pulse to read IMEM[IST_ADDR_REG] out to o_insn_rd

`endif
