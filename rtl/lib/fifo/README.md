# lib/fifo

FIFO collection: a shallow synchronous FIFO backed by registers, a deep BRAM-backed FIFO, an asymmetric 2:1 BRAM FIFO, and a CDC async FIFO. Gray-code converters used internally by `async_fifo` are also here.

## Modules

### `fifo`

Register-based synchronous FIFO. Small and low-latency; intended for shallow depths (≤ a few dozen entries).

- **Parameters**: `WIDTH`, `DEPTH`, `AF_DEPTH` (almost-full threshold), `AE_DEPTH` (almost-empty threshold).
- Outputs: `o_full`, `o_empty`, `o_almost_full`, `o_almost_empty`.
- Supports simultaneous enqueue and dequeue (pass-through when non-empty).

### `async_fifo`

Gray-code CDC FIFO for crossing between two independent clock domains.

- **Parameters**: `DATA_WIDTH`, `ADDR_WIDTH` — depth is `2**ADDR_WIDTH`.
- Write side: `i_wr_clk`/`i_wr_rst`, `i_data`, `i_wr_en`, `o_full`.
- Read side: `i_rd_clk`/`i_rd_rst`, `o_data`, `i_rd_en`, `o_empty`.
- Pointers are converted to Gray code and double-flopped across the clock domain boundary before comparison.

### `bram_fifo`

Deep synchronous FIFO backed by a single `bram` instance. Port A used for writes, port B for reads.

- **Parameters**: `DATA_WIDTH`, `ADDR_WIDTH` — depth is `2**ADDR_WIDTH`.
- Outputs: `o_full`, `o_empty`, `o_num_data` (fill level).
- 1-cycle read latency inherited from the BRAM primitive.

### `bram_fifo_2to1`

Asymmetric synchronous FIFO: enqueue writes `DATA_WIDTH_A`-wide words (2× wide), dequeue reads `DATA_WIDTH_B`-wide words (half width). Backed by a `bram_2to1` instance.

- **Parameters**: `DATA_WIDTH_A`, `DATA_WIDTH_B = DATA_WIDTH_A/2`, `ADDR_WIDTH_A`.
- Capacity = `2**(ADDR_WIDTH_A+1)` narrow entries. `o_num_data` counts narrow entries.
- Used by the lock-in channel (`li_save`) to buffer 256-bit ADC words and drain them as 128-bit AXI beats.

### `bin2gray`

Combinational binary-to-Gray-code converter. `WIDTH`-parameterized. Used by `async_fifo` to encode pointers before CDC synchronization.

### `gray2bin`

Combinational Gray-to-binary converter. `WIDTH`-parameterized. Used by `async_fifo` to decode synchronized pointers back to binary for comparison.
