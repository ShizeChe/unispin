# lib/ad_vip

Behavioral simulation models (VIPs) of Analog Devices DAC ICs used in the DC bias channel. These are testbench-only models; they do not synthesize.

## Modules

### `ad5541a`

Behavioral model of the AD5541A 16-bit SPI DAC.

- Clocks 16 bits in on the rising edge of `i_sclk` while `i_cs_n` is asserted low.
- Latches the SPI shift register into the DAC register on the falling edge of `i_ldac_n`.
- Exposes the current DAC code as `o_vdc[15:0]`.

### `ad5791`

Behavioral model of the AD5791 20-bit SPI DAC (±10 V bipolar).

- **Parameters**: `VMIN`, `VMAX` (real-valued voltage range).
- Full register map: DAC input register, control register, clear-code register, software-control register — all writable via the 24-bit SPI frame (`RW[23] | ADDR[22:20] | DATA[19:0]`).
- Outputs `VDIGITAL[19:0]` (raw code) and `VOUT` (real-valued voltage computed from the DAC register and the supply rails).
- Supports RESET via `RESET_N`, clear via `CLR_N`, and the software RESET/CLR bits.
