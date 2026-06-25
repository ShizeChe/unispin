# lib/axil_slave_regs

AXI4-Lite slave register file used by every channel to bridge the PS (ARM) to PL logic.

## Modules

### `axil_slave_regs`

Implements the full AXI-Lite write and read channels over a flat array of 32-bit registers.

- **Parameters**: `NUM_WRITE_REGS` write-only registers + `NUM_READ_REGS` read-back registers; address width derived automatically.
- **Outputs**: `o_regs[0:NUM_WRITE_REGS-1]` — registered copies of whatever the PS writes; `i_regs[0:NUM_READ_REGS-1]` — values the PL wants to expose back to the PS.
- **Protocol**: single-outstanding, no burst. Both AW+W channels must be valid simultaneously before a handshake is accepted.
- Used by every channel's `*_regs.sv` wrapper to map sequencer, control, and status registers into the PS memory map.
