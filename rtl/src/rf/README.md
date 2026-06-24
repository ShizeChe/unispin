# src/rf

RF IQ channel: generates a 16-bit IQ sample stream at 8 samples per system clock for the ZCU216 RFDC DAC, using a CORDIC-based NCO with programmable phase trajectories. Instantiated 6 times in `processor.sv`.

## Pipeline

```
bram_sequencer → rf_decode → rf_core ─┬─ rf_phasor → [8× rf_cordic] → rf_format → QIx8
                                       └─ rf_ctrl
```

## Modules

### `rf` (top)

Top-level wrapper connecting `bram_sequencer`, `rf_decode`, `rf_core`, and exposing the AXI-Lite register buses, `o_QIx8` IQ stream, `o_armed`/`o_marker`, and `o_eop`.

### `rf_decode`

Combinational decode of `rf_insn_t` into `rf_decode_stg_t`. Handles three instruction modes:

- **RF_KB**: sets phasor acceleration `k` and initial velocity `b`; computes continuous quadratic phase.
- **RF_BC**: sets initial velocity `b` and phase offset `c`; linear phase ramp.
- **RF_IDLE**: idles the DAC output (no phasor update, bubbles propagated through CORDIC).

Also computes `o_insn_modified` for the sweep writeback (increment `w_samples` by `w_dsamples` each repeat).

### `rf_core`

Execution stage that drives `rf_phasor` with decoded k/b/c coefficients, collects 8 CORDIC results per system clock, and calls `rf_format` to assemble the output word. Manages the armed/start handshake with `launch` and asserts `o_next` when the instruction's sample count is exhausted.

### `rf_phasor`

Computes 8 simultaneous phase values per system clock using a polynomial difference engine (second-order recurrence). The 8 outputs cover sub-samples 0–7 of the current DAC clock cycle.

- On `i_set`, pre-computes initial values for all 8 lanes using the closed-form polynomial `p[n] = k·n² + (b−k)·n + c`.
- Each cycle advances all 8 accumulators by one full system-clock step (`k×8` per velocity accumulator).

### `rf_cordic`

One CORDIC pipeline stage (parameterized by `INDEX` 0–7). Converts a phase angle `p.w_phasex8[INDEX]` into a 14-bit I/Q pair using iterative vectoring rotations.

- Coarse rotation first maps the phase into ±45°, then 18 fine CORDIC iterations converge on the exact angle.
- `PAD_ZEROS` appended to the amplitude input increases sub-LSB precision through the pipeline.
- `i_stall` freezes the pipeline while downstream backpressure is applied.

### `rf_format`

Collects the 8 `rf_result_stg_t` structs from the 8 CORDIC pipelines and assembles the packed `[RF_DAC_WIDTH*16-1:0] o_QIx8` output word (8 IQ pairs × 32 bits each, with 2 zero padding bits per component per RFDC requirement). Fills bubble slots with the default I/Q values from `rf_ctrl`.

### `rf_ctrl`

Decodes the control register bank into `rf_ctrl_t` (default I/Q idle values). Latches on write-strobe edge.

### `rf_regs.v`

AXI-Lite register bank wrapper for this channel.
