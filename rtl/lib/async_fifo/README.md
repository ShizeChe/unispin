# lib/async_fifo

Gray-code CDC FIFO for crossing between two independent clock domains, plus the combinational binary↔Gray converters it uses internally.

## Modules

### `async_fifo`

CDC FIFO with gray-coded pointer synchronization.

- **Parameters**: `DATA_WIDTH`, `ADDR_WIDTH` — depth is `2**ADDR_WIDTH`.
- Write side: `i_wr_clk`/`i_wr_rst`, `i_data`, `i_wr_en`, `o_full`.
- Read side: `i_rd_clk`/`i_rd_rst`, `o_data`, `i_rd_en`, `o_empty`.
- Pointers are converted to Gray code and double-flopped across the clock domain boundary before comparison.

### `bin2gray`

Combinational binary-to-Gray-code converter. `WIDTH`-parameterized. Encodes write/read pointers before CDC synchronization.

### `gray2bin`

Combinational Gray-to-binary converter. `WIDTH`-parameterized. Decodes synchronized pointers back to binary for comparison.
