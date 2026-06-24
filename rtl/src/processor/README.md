# src/processor

Top-level PL module that instantiates and wires together every channel and the cross-channel infrastructure.

## Modules

### `processor`

Instantiates:
- 24 × `dc` (DC bias channels, each driving one AD5791 SPI DAC)
- 6 × `rf` (RF IQ channels, each feeding one RFDC DAC NCO)
- 2 × `li` (lock-in measurement channels, each reading one RFDC ADC)
- 2 × `ex` (fast DC / exchange channels, each feeding one RFDC real DAC)
- 1 × `launch` (cross-channel arm synchronizer)
- 1 × `nco_update_tiles` (RFDC NCO frequency/phase programmer)

**Register interface**: the PS accesses every channel and the launch/NCO controllers through a flat array of 32-bit AXI-Lite register banks (`i_dc_seq_regs`, `i_dc_ctrl_regs`, `i_rf_seq_regs`, etc.) that are connected to `axil_slave_regs` instances in `synth/pl.sv`.

**Physical outputs**: SPI buses for all 24 DC channels, IQ streams for all 6 RF channels, real-DAC streams for all 2 EX channels, sample masks and AXI4 write buses for all 2 LI channels.

**Status buses**: armed signals and marker bits from every channel are routed out for LED indicators and simulation probing. `o_*_empty_bus` and `o_*_eop_bus` expose pipeline state for testbench coverage.

**Button debounce**: a `button_detector` with `NUM_DEBOUNCE_CYCLES` is available at the processor boundary for board-level reset or trigger input.
