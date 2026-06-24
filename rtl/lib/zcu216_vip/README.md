# lib/zcu216_vip

Behavioral simulation models of the ZCU216 RFDC (RF Data Converter) interfaces. These wrap the board's ADC and DAC streams with simplified behavioral models so channel cores can be verified without a full Xilinx IP simulation. Testbench-only; they do not synthesize.

## Modules

### `zcu216_adc`

Models the RFDC ADC output for the lock-in (LI) channel.

- Accepts a real-valued `i_vli` voltage and converts it to a packed `[127:0] o_QIx4` stream (4 complex IQ samples per system clock, each 16-bit I and 16-bit Q).
- Tracks the ADC sub-cycle (`adc_cycle` 0–3) against `i_adc_clk` and generates `o_sample_spike` synchronized to `i_sample_mask` — used by `li_core` to know which ADC sub-sample to latch.
- Outputs a simple incrementing I/Q ramp by default to allow deterministic sample verification.

### `zcu216_dac`

Models the RFDC DUC (digital up-converter) and DAC for the RF (IQ) channel.

- Accepts a packed `[255:0] i_QIx8` stream (8 complex samples per system clock, 32 bits per sample: 14-bit I + 2 padding + 14-bit Q + 2 padding).
- Tracks the DAC sub-cycle (`dac_cycle` 0–7) against `i_dac_clk`, demultiplexes IQ pairs, and computes a real `o_vrf` output by mixing with a behavioral NCO.
- Accepts NCO update requests (`i_nco_req`, `i_nco_freq`, `i_nco_phase`, `i_nco_en`) and asserts `o_nco_busy` while a programmable delay elapses.

### `zcu216_real_dac`

Models the RFDC DAC for the EX (fast DC / real-valued) channel.

- Accepts a packed `[255:0] i_realx16` stream (16 real samples per system clock, 16 bits per sample: 14-bit value + 2 padding).
- Tracks the DAC sub-cycle (`dac_cycle` 0–15) against `i_dac_clk` and exposes the current 14-bit output as `o_vex`.
