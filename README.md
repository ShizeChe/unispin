SwashiSpin is a unified quantum control architecture designed for quantum dot spin qubits. The goal is to integrate traditionally siloed control units (bias DC, RF pulse, Lock-in amplifier) onto a single FPGA for optimal performance, concise programming interface, and cost-reduction. It is implemented on the ZCU216 RFSoC Evaluation Board.

The project has three parts:
* RTL design for FPGA firmware (PL in Xilinx's term), along with testbenches and formal properties used for verification (under rtl)
* PCB design for low-noise DC, along with assembly instrctions (under pcb)
* Assembler for compiling and executing Squish programs (under asm)

The project is currently work in progress.
