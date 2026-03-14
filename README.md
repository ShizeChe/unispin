<h1 align="center">Unispin</h1>
<p align="center">A unified quantum control platform for quantum dot spin qubits</p>

<p align="center">
 <img src="img/boards.jpg" alt="boards" width=100% height=auto>
</p>

Overview
========
Unispin is a unified quantum control platform designed specifically for quantum dot spin qubits. Its goal is to reduce control stack complexity and cost while improving performance by integrating all the requried control resources onto a single FPGA. With the two custom PCBs (FMC breakout board and low-noise DAC board), the current configuration has:

* 24x bias DC channels (AD5791BRUZ)
* 6x RF IQ pairs for further analog upconversion
* 2x singled-ended RF channels and 2x ADC channels for lockin-in measurement
* 2x singled-ended fast DC channels

Each signal and measurement channel has its own dedicated, fully-pipelined control core. Each core can be programmed to iteratively executes a sequence of custom assembly instructions with cycle-precise timing. The annotated pulse experiment assembly program and waveform below demonstrates this execution model.

```text
.program rf0                 # program for RF channel 0
.fnco 10MHz                  # NCO is 10MHz
.repeat 100                  # repeats 100 times
    idl t=19us (arm)         # idle for 19us
    ply phs=0 t=12ns (t+8ns) # play the NCO tone for 12ns (increment the pulse duration by 8ns every iteration)
    idl t=12us               # idle for 12us

.program dc0                 # program for DC channel 0
.repeat 100                  # this program repeats 100 times
    lvl v=0 t=2us (arm)      # output 0V for 2us
    lvl v=1 t=15us           # output 1V for 15us
    lvl v=2 t=2us            # output 2V for 2us
    idl t=12ns (t+8ns)       # idle for 12ns (increment the idle duration by 8ns every iteration)
    lvl v=1 t=10us           # output 1V for 10us
    lvl v=0 t=2us            # output 0V for 2us

.program li0                 # program for LI (lock-in) channel 0
.repeat 100                  # this program repeats 100 times
    idl t=19us (arm)         # idle for 19us
    idl t=12ns (t+8ns)       # idle for 12ns (increment the idle duration by 8ns every iteration)
    sam n=1000 t=10us        # sample 1000 samples spanning 10us
    idl t=2us                # idle for 2us

.launch rf0 dc0 li0          # launch RF channel 0, DC channel 0, LI channel 0 
```

<p align="center"> 
 <img src="img/rabi_example.png" alt="rabi example" width="100%" height=auto> 
</p>

## Project Status
The project currently has three parts:
* RTL design, along with testbenches and some formal properties used for verification (under rtl)
* PCB design for the 24 bias DC channels, along with assembly instrctions (under pcb)
* Assembler for compiling and executing the custom assembly programs (under asm)

This project is currently under active development. The RTL design, PCB design, and assembler may continue to evolve as functionality is validated experimentally and the system is further refined. More detailed documentation and user guides will be added after real-device experiments.

## Building the rtl design project and bistream in Vivado
```bash
# clone repo
git clone "repo-url"

# go to the synthesis folder
cd unispin/rtl/synth

# build in vivado
vivado -script proj.tcl &
```
Note that proj.tcl only builds the project. Click generate bitstream in vivado to build the bitstream.

## Building the simulator (requires VCS+Verdi)
This simulator is our go-to method to visualize the full-system waveforms. It incorporates all the channels and cores and have simulated DAC and ADC modules for directly visualizing analog waveforms. It simulates AXI memory operations by accepting address and data through a socket interface, the received address and data are then written to the sequencer through its AXI interface.

Build the simulator. 
```bash
# assume we are in the top level of the cloned repo

# go to the rtl folder
cd unispin/rtl

# build the simulator (requires VCS)
make
```
This will create a simulator executable under rtl.

Execute the simulator in Verdi.
```bash
./simulator -gui -do sim/wv.tcl &
```

This will open up Verdi and load the waveforms. It will listen for connections and read address and data once running. Verdi can stop it at anytime to examine waveforms.

## Building the assembler
```bash
# assume we are in the top level of the cloned repo

# go to the asm folder
cd asm

# build the assmebler
make
```
This will create an executable named "squish" under asm.

Example assembling a .asm file and send to the simulator to visualize exection (with simulator running).
```bash
./squish -s -f ../exp/hahn_echo.asm
```

## Petalinux
A Petalinux os can be built to interface with the cores in FPGA. os/petalinux-steps.md describe the exact steps we took to build a bootable image with an uio driver for each core.

