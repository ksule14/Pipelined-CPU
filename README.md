# Pipelined RISC-V CPU
This is my first personal project, a CPU based on the RISC-V architecture capable of arithmetic, load/store, and branch instructions. Specifically, this CPU is capable of ADD, SUB, AND, OR, SLT, SLTU, LD, SD, and BEQ instructions.
## Architecture
This CPU is currently a single cycle CPU. Once the single cycle version is finished, I plan on pipelining it to improve throughput. The pipelining will break the CPU into fetch, decode, excute, and memory access stages. The write back stage is broken up across the memory access and decode stages.
