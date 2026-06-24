# Simulator Command Protocol

## Overview

The VCS simulator (`rtl/simulator`) listens on a Unix domain socket at `/tmp/tb_cmd.sock`.
Any C program can connect and send ASCII line commands to load instructions, trigger
execution, and read back results. The assembler (`asm/squish -s`) uses this same interface.

Start the simulator first, then connect. The simulator waits indefinitely for a connection
and automatically re-waits if the client disconnects.

## Connection (C example)

```c
#include <sys/socket.h>
#include <sys/un.h>

int sim_connect(void) {
    int fd = socket(AF_UNIX, SOCK_STREAM, 0);
    struct sockaddr_un addr = { .sun_family = AF_UNIX };
    strcpy(addr.sun_path, "/tmp/tb_cmd.sock");
    connect(fd, (struct sockaddr *)&addr, sizeof(addr));
    return fd;
}
```

## Command Reference

### AXI-Lite Write
```
0xAAAAAAAA 0xDDDDDDDD\n
```
Performs one AXI-Lite write to the PL register space. Address is 32-bit.
No response is sent; the next command can be sent immediately after this one.

### Register / Memory Read
```
read 0xAAAAAAAAAAAAA\n
```
Address is up to 49-bit hex (no fixed width required).

- **PL register space** (`addr < 0x800000000`): issues an AXI-Lite read transaction
  through the `axil_slave_regs` of the target channel and returns the register value.
- **DDR High** (`addr >= 0x800000000`): direct lookup into the simulator's in-memory
  DDR array; no AXI transaction is issued.

**Response:** `0xDDDDDDDD\n` — always 32 bits, one line.

**IMPORTANT:** The client must read this response line before sending the next command.
The simulator will not process any further commands until the response is sent.

### Launch (arm + trigger)
```
launch N\n
```
Waits for the launch module to reach LAUNCH state (fires automatically once all
armed channels assert ready — no external trigger needed). Then runs the simulation
for N additional nanoseconds (`N/4` processor clock cycles at 250 MHz / 4 ns period).

### Run (delay only)
```
run N\n
```
Runs the simulation for N nanoseconds without any hardware action.
Same clock-cycle calculation as `launch`.

---

## Address Map

### PL Register Space

```
ADDR = 0xA0000000 + channel_index * 0x1000 + register_offset_bytes
```

| Channel type | Index range | Base address    |
|--------------|-------------|-----------------|
| DC  0–23     | 0–23        | 0xA0000000      |
| RF  0–5      | 24–29       | 0xA0018000      |
| LI  0–1      | 30–31       | 0xA001E000      |
| EX  0–1      | 32–33       | 0xA0020000      |
| Launch       | 34          | 0xA0022000      |

Register layout within a channel (offset = reg_index × 4):

| Index range                            | Type        | Access     |
|----------------------------------------|-------------|------------|
| 0 … SEQ_REGS−1                         | Seq regs    | R/W        |
| SEQ_REGS … SEQ_REGS+CTRL_REGS−1       | Ctrl regs   | R/W        |
| SEQ_REGS+CTRL_REGS … (end)            | Status regs | Read-only  |

Register counts per channel type:

| Channel | SEQ_REGS | CTRL_REGS | STATUS_REGS |
|---------|----------|-----------|-------------|
| DC      | 33       | 2         | 3           |
| RF      | 64       | 3         | 5           |
| LI      | 43       | 6         | 8           |
| EX      | 32       | 0         | 2           |
| Launch  | —        | 3         | 1           |

### DDR High (LI lock-in data)

The `li_save` module bursts ADC samples to DDR High starting at base `0x800000000`.
The simulator maintains an in-memory array of **8192 × 32-bit words** (2048 × 128-bit
AXI4 beats, 32 KB total).

**Sample packing** — each 128-bit AXI beat holds 4 IQ pairs:

```
beat word 0:  {Q0[15:0], I0[15:0]}   ← ddr_mem[beat_index*4 + 0]
beat word 1:  {Q1[15:0], I1[15:0]}   ← ddr_mem[beat_index*4 + 1]
beat word 2:  {Q2[15:0], I2[15:0]}   ← ddr_mem[beat_index*4 + 2]
beat word 3:  {Q3[15:0], I3[15:0]}   ← ddr_mem[beat_index*4 + 3]
```

To read IQ sample n (zero-indexed):

```
addr = 0x800000000 + n * 4
```

The I component is in bits [15:0] and Q in bits [31:16] of the returned 32-bit word.

**C helper:**

```c
static void send_line(int fd, const char *s) {
    write(fd, s, strlen(s));
}

static void recv_line(int fd, char *buf, int sz) {
    int i = 0;
    char c;
    while (i < sz - 1 && read(fd, &c, 1) == 1) {
        if (c == '\n') break;
        buf[i++] = c;
    }
    buf[i] = '\0';
}

uint32_t sim_read(int fd, uint64_t addr) {
    char cmd[64], resp[32];
    snprintf(cmd, sizeof(cmd), "read 0x%012llx\n", (unsigned long long)addr);
    send_line(fd, cmd);
    recv_line(fd, resp, sizeof(resp));
    return (uint32_t)strtoul(resp + 2, NULL, 16);
}

// Read IQ sample n; returns I in low 16 bits, Q in high 16 bits
uint32_t sim_read_iq(int fd, int n) {
    return sim_read(fd, 0x800000000ULL + (uint64_t)n * 4);
}

int16_t get_I(uint32_t word) { return (int16_t)(word & 0xFFFF); }
int16_t get_Q(uint32_t word) { return (int16_t)(word >> 16); }
```

---

## Simulator Behaviour

- The DDR memory is initialized to **0x00000000** for all words at simulation start.
- Reading an unwritten DDR location returns 0x00000000 (not an error).
- DDR overflow (a `li_save` burst would exceed word index 8191) causes `$fatal`.
- AXI-Lite write responses with `bresp != OKAY` cause `$fatal`.
- The two LI channels (`li0`, `li1`) share the same DDR memory array. Configure their
  `base_addr` ctrl register to non-overlapping regions.
- Channel 0 has priority if both LI channels assert AXI burst requests simultaneously.
