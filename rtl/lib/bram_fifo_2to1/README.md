# lib/bram_fifo_2to1

Asymmetric synchronous FIFO: enqueue writes wide words, dequeue reads half-width words. Backed by `bram_2to1` from `../bram`.

## Modules

### `bram_fifo_2to1`

- **Parameters**: `DATA_WIDTH_A`, `DATA_WIDTH_B = DATA_WIDTH_A/2`, `ADDR_WIDTH_A`.
- Capacity = `2**(ADDR_WIDTH_A+1)` narrow entries. `o_num_data` counts narrow entries.
- 1-cycle read latency inherited from the BRAM primitive.
- Used by the lock-in channel (`li_save`) to buffer 256-bit ADC words and drain them as 128-bit AXI beats.
