# src/launch

Cross-channel synchronization controller. Waits for all selected channels to reach their arm point, then simultaneously asserts `o_*_start` to every active channel. Supports both software-triggered and hardware-triggered (external TTL) launch.

## Modules

### `launch`

- **Active masks** (`r_dc_active_mask`, `r_rf_active_mask`, `r_li_active_mask`, `r_ex_active_mask`): written from the control register bank to select which channels participate in the next synchronized launch.
- **Ready gate**: asserts `w_all_ready` when every active channel has asserted its `o_armed` signal.
- **Trigger modes**: if `r_use_trigger` is set, the launch waits for a rising edge on `i_trigger` (external hardware input) after all channels are ready; otherwise it fires immediately when all channels arm.
- **Iteration count**: repeats the arm→start cycle `r_iters` times before going idle, supporting multi-shot experiments without PS intervention.
- A separate `CLR` register bit resets the active masks and iteration state between experiments.

### `launch_regs.v`

AXI-Lite register bank wrapper providing the control and status register interface for `launch`.
