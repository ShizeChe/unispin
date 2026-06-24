# lib/bram

Parameterized true dual-port BRAM primitives. Written in the Vivado-inferred BRAM style (registered read output, write-first mode) so the synthesizer maps them to block RAM resources.

## Modules

### `bram`

Symmetric true dual-port BRAM. Both ports share the same data width and address width.

- **Parameters**: `DATA_WIDTH`, `ADDR_WIDTH` — depth is `2**ADDR_WIDTH`.
- Each port has independent clock, write-enable, address, and data. Read data is registered (1-cycle latency). Write-first: on a write the output reflects the new data in the same cycle.
- Used directly by `bram_fifo` and as the building block for `bram_2to1`.

### `bram_2to1`

Asymmetric true dual-port BRAM where port A is twice as wide as port B. Implemented as two symmetric `bram` instances (LO and HI halves) so Vivado can still infer BRAMs.

- **Port A** (wide): `DATA_WIDTH_A` bits, `ADDR_WIDTH_A`-bit address.
- **Port B** (narrow): `DATA_WIDTH_B = DATA_WIDTH_A/2` bits, `(ADDR_WIDTH_A+1)`-bit address. `addr_b[0]` selects the low (0) or high (1) half; `addr_b[ADDR_WIDTH_A:1]` indexes the row.
- Used by `bram_fifo_2to1` to implement the asymmetric lock-in save FIFO.
