# lib/bram_fifo

Deep synchronous FIFO backed by a single `bram` instance from `../bram`. For the asymmetric 2:1 variant see `../bram_fifo_2to1`.

## Modules

### `bram_fifo`

Port A used for writes, port B for reads.

- **Parameters**: `DATA_WIDTH`, `ADDR_WIDTH` — depth is `2**ADDR_WIDTH`.
- Outputs: `o_full`, `o_empty`, `o_num_data` (fill level).
- 1-cycle read latency inherited from the BRAM primitive.
