# 5-Stage Pipelined RISC-V CPU with Cache and UART
This is a simple 5-stage pipelined RiSC-V CPU with one-level memory hierarchy and UART interfacing to a display terminal.

Languages/Tools: SystemVerilog, Vivado 2025.2, AMD Urbana board with Spartan-7 FPGA.

## Overview
This project is a functional 32-bit RISC-V processor implemented in SystemVerilog and synthesized on the AMD Urbana board with Spartan-7 FPGA. The design implements a classic 5-stage pipeline (IF → ID → EX → MEM → WB) with hazard resolution. A forwarding unit eliminates most data hazards, a stall controller handles load-use delays, and a 2-bit dynamic branch predictor with a 16-entry Pattern History Table reduces control hazard penalties by predicting branch outcomes before they resolve. A direct-mapped write-through cache sits between the pipeline and data memory, stalling the pipeline on misses. A UART interface is mapped into the address space, allowing the processor to transmit output over serial. The design is verified through transaction-based SystemVerilog testbenches that compare against golden reference models using scoreboards and SV assertions. 
## Architecture Diagram

## Key Features
1. 4 main pipeline registers (IF/ID, ID/EX, EX/MEM, MEM/WB) that carry data across components
2. Forwarding Unit: Used to avoid data hazards by immediately sending data from the ALU to previous stages before WB occurs.
3. Stalling Unit: Stalls the pipeline when forwarding is not enough such as in load-use hazards or when the UART FIFO is full to prevent data loss.
4. Dynamic Branch Predictor: 4 state branch predictor (SNT, WNT, WT, ST) that is used to predict branch results in advance to avoid stalling.
5. Cache: L1 Cache one memory hierarchy above RAM that utilizes index and tag bits to identify data. Cache and RAM are in synch with write-through logic.
6. Flush Controller: Flushes and injects NOP into pipeline registers on branch misprediction to clear garbage instructions and redirect PC.
7. UART: Connects processor to serial terminal using synchronous FIFO and UART TX module at 115200 baud.

## Pipeline Stages

## Hazard Handling

## Cache

## UART Interface
The UART interface transmits serial data to a terminal to display text. The interface is made up of a UART controller, synchronous FIFO, and TX module. When a store instruction has destination 1024 in memory, the processor redirects that data to the UART controller instead of RAM/cache. The UART controller writes to the FIFO with data from the processor when the FIFO is not full and sends data to the TX module by reading from the FIFO when the FIFO is not empty. The FIFO is synchronous because it operates on the same clock as the processor. Full flag is high when write pointer = depth of FIFO. Empty flag is high when read pointer = write pointer. The TX module is an FSM that sends the starting bit (0), then the 8-bit serial data, and then the stop bit (1). There is an additional state in the FSM that delays it for one cycle for stability. The clock runs at 100MHz and the baud rate is 115200 which equates to about 868 cycles per bit. The tx_busy signal is high while a counter counts to 868 for each bit being sent.  
## Verification

## Supported Instructions
| Instruction | Type | Description |
| ----------- | ---- | ----------- |
| add rd, rs1, rs2 | R    | Stores sum of rs1, rs2 in rd |
| sub rd, rs1, rs2 | R    | Stores difference of rs1, rs2 in rd |
| and rd, rs1, rs2 | R    | Stores bitwise AND of rs1, rs2 in rd |
| or rd, rs1, rs2 | R     | Stores bitwise OR of rs1, rs2 in rd |
| slt rd, rs1, rs2 | R    | Stores signed comparision rs1 < rs2 in rd |
| sltu rd, rs1, rs2 | R   | Stores unsigned comparison rs1 < rs2 in rd |
| addi rd, r1, imm | I    | Stores sum of rs1, imm in rd |
| lw  rd, offset(rs1) | I | loads data from memory address (offset + rs1) into rd |
| sw rs2, offset(rs1) | S | stores data from rs2 into memory address (offset + rs1) |
| beq rs1, rs2 offset | B | compares rs1, rs2 and jumps to PC + offset if equal |

## Tools and Synthesis
Avoid errors by using Vivado 2025.2.
Project written entirely in SystemVerilog.
To use, open a Vivado project and add RTL and COMM files as design sources and set cpu_top.sv as top module. Also include data_mem.hex and uart_instr.hex as memory initialization files to load instruction memory with program and RAM with zeros. Program to run can be changed at any time by changing the file the instruction memory accesses in instruction_mem.sv. Use Urbana.xdc as constraint file. Synthesize, run implementation, generate bistream, and program device to run program. If running a program that utilizes UART interface, ensure a serial terminal is open and configured to 115200 baud.

