# lib/axi_slave_regs_vip

AXI4 (full) write-only slave VIP for simulation and verification only. For the synthesizable AXI-Lite slave see `../axil_slave_regs`.

## Modules

### `axi_slave_regs_vip`

AXI4 write-only slave for simulation and verification only. Accepts AW/W/B channels with randomized independent backpressure on all three channels to stress-test AXI masters.

- **Parameters**: `DATA_WIDTH` (must be 128 for `li_save`), `ADDR_WIDTH`, `ID_WIDTH`.
- **Behavior**: stores every accepted write beat in a SystemVerilog associative array readable by the testbench via hierarchical reference.
- Asserts `$fatal` on any AXI4 protocol violation (valid stability, signal stability, alignment, single-outstanding).
- AR/R channels not present; W-before-AW is legal per AXI4 but flagged with a warning.
