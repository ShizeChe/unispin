# lib/spi

General-purpose SPI master primitive.

## Modules

### `spi_master`

Configurable SPI master that supports all four CPOL/CPHA mode combinations and a software-programmable clock divider.

- **Parameters**: `DATA_WIDTH`, `SCLK_POLARITY` (CPOL), `SCLK_PHASE` (CPHA).
- `i_dvsr` — 16-bit clock divisor; SCLK period = `2 × (i_dvsr + 1)` system clocks.
- `i_start` initiates a transfer; `o_done` pulses high when the last bit has been clocked.
- Full-duplex: `i_miso` is shifted into `o_dout` simultaneously with `i_din` shifting out on `o_mosi`.
- Used as the basis for `dc_spi_master` in the DC bias channel.
