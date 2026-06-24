# src/li

Lock-in measurement channel: gates the RFDC ADC stream, applies a stride-based decimation scheme, tags samples with their PC address, and DMA-writes them to PS DDR via AXI4. Instantiated 2 times in `processor.sv`.

## Pipeline

```
bram_sequencer → li_decode → li_core ─┬─ li_sample → tagged QIx4
                                       └─ li_ctrl
                                                 ↓
                                           li_save → AXI4 → DDR
```

## Modules

### `li` (top)

Top-level wrapper connecting `bram_sequencer`, `li_decode`, `li_core`, and exposing AXI-Lite register buses, ADC stream input (`i_QIx4`), tagged sample outputs, `o_armed`/`o_marker`, and `o_eop`.

### `li_decode`

Combinational decode of `li_insn_t` into `li_decode_stg_t`. Propagates `pc_addr` (BRAM physical address) and `pc` (logical instruction index) through the pipeline for sample tagging. Computes `o_insn_modified`: increments `w_samples` by `w_dsamples` each repeat (sample-count sweep).

### `li_core`

Execution stage. On each active instruction:

1. Waits for `i_start` if the instruction has the arm flag.
2. Calls `li_sample` to compute per-cycle valid masks and sample indices given the remaining count and stride.
3. Gates the ADC `i_QIx4` stream through `o_sample_mask` to the RFDC.
4. Forwards tagged, valid-masked samples to `li_save`.
5. Asserts `o_next` when all samples in the instruction are collected.

### `li_sample`

Combinational sample-counting engine. Given remaining sample count and stride, computes which of the 4 ADC sub-samples this cycle are valid (`o_validx4`), their logical indices (`o_indexx4`), and the updated counts for the next cycle. Supports stride-based decimation: `i_stride` ADC samples are skipped between each accepted sample.

### `li_save`

AXI4 write master. Buffers tagged ADC words in a `bram_fifo_2to1` (256-bit wide entries, 128-bit AXI beats) and issues burst writes to DDR at the base address from `li_ctrl`.

- Tracks `o_samples_lost` when the FIFO overflows and `o_samples_inbuf` for PS-side flow control.
- Outputs the full AXI4 AW/W/B channel interface (no AR/R — write-only).

### `li_ctrl`

Decodes the control register bank into `li_ctrl_t` (DDR base address, burst length). Latches on write-strobe edge.

### `li_axi_write.v`

Verilog wrapper for the AXI write channels, used during Vivado block design integration to expose the AXI4 master port from `li_save` as a standalone IP interface.

### `li_regs.v`

AXI-Lite register bank wrapper for this channel.
