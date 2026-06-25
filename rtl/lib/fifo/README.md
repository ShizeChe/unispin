# lib/fifo

Shallow synchronous FIFO backed by registers. For deep BRAM-backed FIFOs see `../bram_fifo` and `../bram_fifo_2to1`; for the CDC async FIFO see `../async_fifo`.

Formal properties for this module live in `fpv/`; run them with `./runme`.

## Modules

### `fifo`

Register-based synchronous FIFO. Small and low-latency; intended for shallow depths (≤ a few dozen entries).

- **Parameters**: `WIDTH`, `DEPTH`, `AF_DEPTH` (almost-full threshold), `AE_DEPTH` (almost-empty threshold).
- Outputs: `o_full`, `o_empty`, `o_almost_full`, `o_almost_empty`.
- Supports simultaneous enqueue and dequeue (pass-through when non-empty).
