# Pipelined RISC-V CPU
This is my first personal project, a CPU based on the RISC-V architecture capable of arithmetic, load/store, and branch instructions. Specifically, this CPU is capable of ADD, SUB, AND, OR, SLT, SLTU, ADDI, LD, SD, and BEQ instructions.
## Architecture
This CPU is currently a single cycle CPU. Once the single cycle version is finished, I plan on pipelining it to improve throughput. The pipelining will break the CPU into fetch, decode, excute, and memory access stages. The write back stage is broken up across the memory access and decode stages.

### Main Control
The main control unit receives the instruction opcode (bits 6-0) and controls the muxes throughout the CPU. Based on the opcode, the main control determines the instruction type and sets the select lines accordingly. To handle the BEQ instruction, the main control outputs a branch signal and takes in a zero flag as input from the ALU. When the branch signal and zero flag are high, the pc_src signal is high which feeds the address calculated by the ALU to the PC. The main control unit also provides input to the alu control unit, telling it what instruction type is being executed.

### Program Counter
The program counter increments by 4 bytes on every rising clock edge. The only excpetion is on branch instructions, where it jumps to the calculated branch address.

### Instruction Memory
The instruction memory (IM) is an array 32 bits wide and 8 bits deep, meaning it can hold up to 256 32-bit instructions. The program instructions are baked into the IM with a hex file, sequentially filling the IM. The IM receives the address from the PC and right shifts by 2. The IM then outputs the corresponding instruction.

### Register File
The register file is an array 64 bits wide and 5 bits deep, meaning it holds 32 64-bit registers. The register file receives instruction bits corresponding to rs1, rs2, and rd and outputs the data in rs1 and rs2. The register file is written using the reg_write control signal and the data is written to rd. Register 0 is hardcoded to the value zero to allow easy register loading using ADDI.

### Immediate Generator
The immediate generator takes the entire 32-bit instruction as an input, and depend on the instruction type, pieces together the 12 bit immediate from various fields of the instruction and sign extends it to 64 bits.

### ALU Control
The ALU control receives input from the main control and determines what instruction type is being performed. The ALU control first generalizes the instruction as either arithmetic, load/store, or branch and based on this, directs the ALU to perform the approriate operation. If the instruction is arithmetic, the ALU control further specifies what exact operation is to be performed.
### ALU
The ALU takes rs1 and either rs2 or the immediate as inputs. Based on the input from ALU control, the ALU performs a specific operation. This ALU is capable of ADD, SUB, bitwise AND, bitwise OR, SLT, and SLTU operations.
### Data Memory
The Data memory (DM) has a read and write signal. If the read signal is high, the DM provides the data at the address supplied by the ALU. If the write signal is high, the data contained in rs2 is written to the DM at the address supplied by the ALU.
## Codes Package
The codes package defines parameters and data types used across files. Parameters include Data width, word width and depth. 
