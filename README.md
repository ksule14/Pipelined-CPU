# 5-Stage Pipelined RISC-V CPU with Cache and UART
This is a simple 5-stage pipelined RiSC-V CPU with one-level memory hierarchy and UART interfacing to a display terminal.

Languages/Tools: SystemVerilog, Vivado 2025.2, EDAPlayground Aldec Riviera Pro, AMD Urbana board with Spartan-7 FPGA.

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
The processor implements a classic 5-stage pipeline. Each stage communicates through SystemVerilog struct-typed pipeline registers, which group related signals into named types
  (if_id_t, id_ex_t, ex_mem_t, mem_wb_t) for clarity.

  IF — Instruction Fetch

  Fetches the instruction at the current PC from instruction memory. The PC increments by 4 each cycle unless the stall unit freezes it or the branch predictor redirects it. The stage passes the instruction, PC, and branch prediction result (predict_taken) downstream.

  ID — Instruction Decode

  Decodes the fetched instruction and reads the register file. The control unit generates all downstream control signals (alu_op, alu_src, branch, mem_read, mem_write, mem_to_reg, reg_write) from the opcode. The immediate is sign-extended here and passed forward alongside both source register values and their addresses (rs1, rs2, rd).

  EX — Execute

  The ALU executes the operation using operands selected by the forwarding unit (see Hazard Handling). Supported operations: ADD, SUB, AND, OR, SLT, SLTU. A zero_flag is produced for branch resolution. The branch target address is computed here and passed to MEM alongside the ALU result.

  MEM — Memory Access

  Load and store instructions access the data cache here. On a cache miss, the stall unit freezes the entire pipeline until the miss is resolved. Writes to address 0x400 are routed to the UART transmitter instead of data memory. Non-memory instructions pass the ALU result through unchanged.

  WB — Write Back

  Selects between the ALU result and the value read from memory (mem_to_reg) and writes it back to the register file. This is the only stage that writes to architectural state.
## Hazard Handling
Data Hazards — Forwarding

  Most data hazards are resolved without stalling by the forwarding unit. It compares the source registers of the instruction in EX (rs1, rs2) against the destination registers of instructions in MEM and WB. When a match is found and the downstream instruction writes to a register (reg_write asserted), the forwarding unit muxes the result directly into
  the ALU inputs:

  ┌─────────────┬───────────────────────────────────────────┐
  │ forward_a/b │                  Source                   │
  ├─────────────┼───────────────────────────────────────────┤
  │ 2'b10       │ EX/MEM pipeline register (one cycle old)  │
  ├─────────────┼───────────────────────────────────────────┤
  │ 2'b01       │ MEM/WB pipeline register (two cycles old) │
  ├─────────────┼───────────────────────────────────────────┤
  │ 2'b00       │ Register file                             │
  └─────────────┴───────────────────────────────────────────┘

  MEM-stage forwarding takes priority over WB-stage forwarding when both match.

  Data Hazards — Load-Use Stall

  Forwarding cannot resolve a load-use hazard. The loaded value is not available until the end of MEM, one cycle too late for the immediately following instruction. When the EX-stage instruction is a load and its destination register matches a source register of the ID-stage instruction, the stall unit:
  - Freezes the PC and IF/ID register (pc_en, if_id_en deasserted)
  - Flushes the ID/EX register to insert a pipeline bubble

  This introduces exactly one stall cycle, after which forwarding from MEM/WB resolves the dependency.

  Control Hazards — Branch Predictor

  Branches are resolved at the end of EX, three cycles after fetch. To reduce the penalty, the processor uses a 2-bit dynamic branch predictor with a 16-entry Pattern History Table (PHT) indexed by PC bits [5:2]. Each entry is a 2-bit saturating counter with four states:

  STRONG_NOT_TAKEN → WEAK_NOT_TAKEN → WEAK_TAKEN → STRONG_TAKEN

  The prediction (predict_taken) is made at fetch time and carried through the pipeline. When the branch resolves in EX, the flush controller compares the outcome against the
  prediction. If the branch was taken or the prediction was wrong, IF/ID and ID/EX are flushed and the PC is redirected to the correct target — incurring a 2-cycle penalty.
  Correct not-taken predictions incur no penalty.

  Pipeline Stalls — Cache and UART

  Beyond load-use stalls, the stall unit also freezes the entire pipeline (pc_en, if_id_en, id_ex_en, ex_mem_en, mem_wb_en all deasserted) on two additional conditions:
  - Cache miss (mem_stall asserted): holds until the cache fetches the missing line from RAM
  - UART FIFO full (uart_stall asserted): holds until the transmitter drains enough to accept the next byte
## Cache
The processor uses an L1 cache and RAM as its memory hierarchy. The cache has 16 entries and the RAM has 256. Writing to memory utilizes write-through logic, meaning the cache and RAM are both written at the same time. Write-through is simpler to implement but is slower than write-back logic. Memory reads look at the cache first. If cache values are valid and the index and tag bits match between the desired location and the actual data in the cache, it is a cache hit and the data is supplied without going to RAM. If there is a cache miss, the pipeline is stalled so that RAM can be accessed in multiple cycles. The error signal is high when the desired memory address is not word aligned.
## UART Interface
The UART interface transmits serial data to a terminal to display text. The interface is made up of a UART controller, synchronous FIFO, and TX module. When a store instruction has destination 1024 in memory, the processor redirects that data to the UART controller instead of RAM/cache. The UART controller writes to the FIFO with data from the processor when the FIFO is not full and sends data to the TX module by reading from the FIFO when the FIFO is not empty. The FIFO is synchronous because it operates on the same clock as the processor. Full flag is high when write pointer = depth of FIFO. Empty flag is high when read pointer = write pointer. The TX module is an FSM that sends the starting bit (0), then the 8-bit serial data, and then the stop bit (1). There is an additional state in the FSM that delays it for one cycle for stability. The clock runs at 100MHz and the baud rate is 115200 which equates to about 868 cycles per bit. The tx_busy signal is high while a counter counts to 868 for each bit being sent.  
## Verification
The modules in this project have been verified using SystemVerilog testbenches that incorporate a golden model and scoreboard to compare dut results with calculated outcomes for specific test cases.
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
Project written entirely in SystemVerilog and verified using EDAPlayground Aldec Riviera Pro simulator.
To use, open a Vivado project and add RTL and COMM files as design sources and set cpu_top.sv as top module. Also include data_mem.hex and uart_instr.hex as memory initialization files to load instruction memory with program and RAM with zeros. Program to run can be changed at any time by changing the file the instruction memory accesses in instruction_mem.sv. Use Urbana.xdc as constraint file. Synthesize, run implementation, generate bistream, and program device to run program. If running a program that utilizes UART interface, ensure a serial terminal is open and configured to 115200 baud.

