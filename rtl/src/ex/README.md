# src/ex

EX (exchange / fast DC) channel: generates a real-valued 14-bit sample stream at 16 samples per system clock for the ZCU216 RFDC real DAC output. Used for deterministic fast DC pulses (e.g., exchange-gate waveforms). Instantiated 2 times in `processor.sv`.

## Pipeline

```
bram_sequencer → ex_core (decode + count + output) → realx16 → RFDC DAC
```

## Modules

### `ex` (top)

Top-level wrapper connecting `bram_sequencer` and `ex_core`. Exposes AXI-Lite register bus (`i_seq_regs`), the packed 16-sample-per-clock real DAC stream (`o_realx16`), `o_armed`/`o_marker`, and `o_eop`.

Unlike DC and RF, EX has no separate control register bank — all per-instruction parameters are encoded directly in the instruction word.

### `ex_core`

Combined decode + execution stage (no separate `ex_decode` module). The decode is inlined as a combinational struct assignment from `ex_insn_t`.

- Each instruction carries a 14-bit `w_real` amplitude and a `w_samples` count. `w_dsamples` increments the count each repeat (sweep).
- The core counts down `w_samples` cycles while replicating `w_real` across all 16 output lanes, then asserts `o_next`.
- Arm/start handshake with `launch` is the same as other channels.

### `ex_regs.v`

AXI-Lite register bank wrapper for this channel (sequencer registers only; no separate control registers).
