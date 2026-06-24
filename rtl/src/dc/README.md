# src/dc

DC bias channel: programs a 20-bit SPI DAC (AD5791) via a fully-pipelined `sequencer → dc_decode → dc_core → dc_spi_master` chain. Instantiated 24 times in `processor.sv`.

## Pipeline

```
bram_sequencer → dc_decode → dc_core → dc_spi_master → AD5791
```

## Modules

### `dc` (top)

Top-level wrapper that instantiates `bram_sequencer`, `dc_decode`, `dc_core`, and connects them. Exposes AXI-Lite register buses (`i_seq_regs`, `i_ctrl_regs`), SPI signals, `o_armed`/`o_marker` status, and `o_eop` for verification.

### `dc_decode`

Combinational decode stage. Unpacks the raw `dc_insn_t` into a `dc_decode_stg_t` pipeline struct and computes the `o_insn_modified` writeback.

- **Modify sweep**: if `w_modify` is set, increments `w_spi_din` by `w_dspi_din` (voltage sweep) or `w_hold_cycles` by `w_dspi_din` (time sweep), implementing the `(t+Xns)` / `(v+Xmv)` assembler syntax.
- **Arm**: merges `w_arm` and `w_sticky_arm` into the pipeline's `w_arm` flag. Clears the one-shot arm bit in the modified instruction so sticky-arm persists across iterations while plain arm fires once.

### `dc_core`

Main control FSM and SPI sequencer. Implements the per-instruction state machine:

1. Wait for `i_start` (from launch) if the instruction has `w_arm`.
2. Optionally wait `w_delay_cycles` before driving CS low.
3. Call `dc_spi_master` to shift out the DAC word.
4. Assert `o_ldac_n` for `w_ldac_cycles` to update the DAC output.
5. Wait `w_hold_cycles` to fill the instruction's timing slot.
6. Assert `o_next` to advance the sequencer.

### `dc_ctrl`

Decodes the control register bank into `dc_ctrl_t` (SPI divisor, delay cycles, CS-up cycles, LDAC pulse width). Latches new values on a rising edge of the write-strobe register bit.

### `dc_spi_master`

DC-specific SPI master derived from `lib/spi/spi_master`. Drives SCLK, MOSI, and CS_N for the AD5791's 24-bit SPI frame (R/W bit + 3-bit address + 20-bit data).

### `dc_regs.v`

Verilog wrapper that instantiates `axil_slave_regs` and splits the flat register array into sequencer, control, and status register groups for this channel's AXI-Lite slave.
