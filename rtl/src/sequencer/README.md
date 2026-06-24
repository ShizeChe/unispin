# src/sequencer

Instruction-fetch engines shared by all channel types. A sequencer reads a program from memory, manages the program counter and iteration counter, and feeds one instruction per cycle to the channel core. The `i_insn_modified` feedback path allows the core to write back a modified version of the current instruction (the `(t+Xns)` sweep mechanism).

## Modules

### `bram_sequencer`

The production sequencer used by all channels. Stores the program in an on-chip BRAM so programs can be arbitrarily large (up to `2**PC_ADDR_WIDTH` instructions) without consuming registers.

- **Register interface** (via `i_regs`): split into three groups — `pcmem` store (writes PC → instruction-address mappings), `imem` store (writes raw instruction words), and iteration/depth control. A write-strobe edge on the last register triggers a load.
- **PC memory**: maps logical PC (0, 1, 2, …) to a physical BRAM address; supports noncontiguous programs and sparse instruction layouts.
- **Iteration**: `o_iters` counts how many times the program has repeated. The sequencer re-runs the program until the iteration count is exhausted, then asserts `o_empty`.
- `o_insn_rd` and `o_pc_rd` expose the current read pointer for PS-side status readback.

### `serial_sequencer`

Alternative sequencer that stores the program in a small BRAM addressed serially (no PC-memory indirection layer). Simpler register interface and smaller footprint; suited for channels that do not need non-contiguous addressing. Parameters match `bram_sequencer` (`PC_WIDTH`, `INSN_WIDTH`, `ITER_WIDTH`).

### `sequencer`

Legacy register-file-based sequencer (instructions stored in flip-flops). Limited to shallow programs (`DEPTH` instructions). Retained for reference; replaced by `bram_sequencer` in all current channel instantiations.
