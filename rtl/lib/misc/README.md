# lib/misc

Miscellaneous utility modules: edge detection, debouncing, and signal generation primitives used across the design and testbenches.

## Modules

### `edge_detector`

Detects rising and falling edges on a single-bit signal using a two-flip-flop pipeline.

- Outputs `o_posedge` (high for one cycle on rising edge) and `o_negedge` (high for one cycle on falling edge).
- Used throughout the design to convert level-triggered write-strobe registers into single-cycle pulses (e.g., `dc_ctrl`, `nco_update`, `bram_sequencer`).

### `debouncer`

Filters glitches off a noisy input by requiring the signal to be stable for `NUM_CYCLES` consecutive clock cycles before updating `o_steady`.

- Restarts the counter whenever the input changes. Only updates the output when the counter expires.

### `button_detector`

Combines `debouncer` + a two-FF synchronizer + edge detector to produce a clean single-cycle `o_pressed` pulse per button press. Supports multiple buttons via the `NUM_BUTTONS` parameter.

### `parabolic_counter`

Computes a second-order polynomial sequence: `p[n] = k·n² + (b−k)·n + c` using a difference engine (two accumulators), outputting the upper `OW` bits of the accumulator each cycle.

- **Parameters**: `IW` (accumulator width), `OW` (output width).
- `i_set` loads initial conditions (`k`, `b`, `c`); subsequent cycles auto-advance.
- Used by the RF channel to generate smooth frequency sweeps without a full multiplier.

### `phase_observe`

Simulation-only helper that demultiplexes a packed `[7:0][17:0]` phase vector (8 sub-samples per system clock) into a single `o_phase` that tracks the current DAC sub-cycle. Used in testbenches to observe the instantaneous NCO phase driven into the DAC.
