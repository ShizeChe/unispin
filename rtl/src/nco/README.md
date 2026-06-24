# src/nco

NCO (numerically controlled oscillator) update controllers for the ZCU216 RFDC tiles. The RFDC's built-in DUC/DDC NCOs must be programmed via a handshake protocol; these modules translate AXI-Lite register writes into that protocol.

## Modules

### `nco_update`

Single-tile NCO update controller. Manages frequency, phase, phase-reset, and enable parameters for `NUM_NCO` NCOs within one RFDC tile.

- Latches new parameters from `i_ctrl_regs` on a rising edge of the write-strobe bit.
- Runs a 4-state FSM (IDLE → REQ → HOLD → BUSY) to assert `o_req` and wait for `i_busy` to deassert before considering the update complete.
- Exposes `o_freq[47:0]`, `o_phase[17:0]`, `o_phase_rst`, and `o_en[5:0]` per NCO.

### `nco_update_tiles`

Top-level aggregator instantiating one `nco_update` per RFDC tile. Covers 4 DAC tiles (228/229/230/231, 2 NCOs each) and 1 ADC tile (225, 2 NCOs).

- Connects the per-tile `i_ctrl_regs` / `o_status_regs` register busses from `processor.sv` to individual `nco_update` instances.
- Forwards per-tile update request/busy handshakes to the RFDC IP.

### `nco_update_regs.v`

AXI-Lite register bank wrapper for the NCO control and status registers.
