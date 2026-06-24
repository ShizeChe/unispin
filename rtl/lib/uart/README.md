# lib/uart

UART transceiver stack: baud-rate generator, byte-level receiver and transmitter, and a top-level wrapper with TX/RX FIFOs.

## Modules

### `baudx16_generator`

Generates a `o_sample_tick` pulse at 16× the baud rate by counting to `i_dvsr`. The receiver uses this oversampled tick to locate and sample each data bit in the center of its window.

### `receiver`

State-machine UART RX (IDLE → START → DATA → STOP). Samples the incoming `i_rx` line at the tick from `baudx16_generator`, shifting 8 bits into an output register. Pulses `o_enq_rxq` when a complete byte is ready.

### `transmitter`

State-machine UART TX (IDLE → START → DATA → STOP). Dequeues one byte from the TX FIFO (`o_deq_txq`) and shifts it out LSB-first on `o_tx` at the baud rate.

### `uart`

Top-level UART integrating `baudx16_generator`, `receiver`, `transmitter`, and two `fifo` instances (RX queue and TX queue).

- **Parameters**: `DATA_WIDTH`, per-FIFO depth, almost-full, and almost-empty thresholds.
- `i_dvsr` sets the baud rate at runtime.
- Exposes enqueue/dequeue interfaces for both queues along with `full`/`empty`/`almost_full`/`almost_empty` status flags.
