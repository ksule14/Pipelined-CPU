# Pipelined RISC-V CPU
This is my first personal project, a CPU based on the RISC-V architecture capable of arithmetic, load/store, and branch instructions. Specifically, this CPU is capable of ADD, SUB, AND, OR, SLT, SLTU, LD, SD, and BEQ instructions.
## Architecture
This CPU is currently a single cycle CPU. Once the single cycle version is finished, I plan on pipelining it to improve throughput. The pipelining will break the CPU into fetch, decode, excute, and memory access stages. The write back stage is broken up across the memory access and decode stages.

### Program Counter
The Program counter (pc) takes four inputs: the clock, active-low reset, pc_source control signal, and pc branch address. The pc_source control signal is the select line for a 2x1 mux between the pc branch address and simply incrementing by 4. Pc_source is controlled by the main control unit. When pc_source = 0, the pc increments by 4 (bytes) on every rising clock edge. When pc_source = 1, the pc jumps to the branch address calculated by the ALU. When the reset signal is low, the pc resets to address 0, restarting the program.

### Instruction Memory
The instruction memory is a 
