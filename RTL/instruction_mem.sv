import codes_pkg::WORD_WIDTH;
import codes_pkg::DEPTH;

// Instruction memory (IM) module. It stores the instructions of the program and provides the instruction to be executed
// based on the address provided by the PC.
// Initialized with the contents of instr_mem.hex, which is a hex file containing the instructions of the program
module instruction_mem #(
    parameter integer PROGRAM_LENGTH = DEPTH
) (
    // address input from the PC
    input  logic [WORD_WIDTH-1:0] addr,
    // instruction output to the rest of the CPU
    output logic [WORD_WIDTH-1:0] instruction,
    // high when the current fetch is the last program instruction
    output logic                  done,
    // error signal is high when there is an unaligned fetch meaning the address is not a multiple of 4
    output logic                  error
);
    // IM is an array of words with a depth defined in codes package. Each word is 32 bits wide
    // The depth is the number of words that can be stored
    logic [WORD_WIDTH-1:0] instr_mem [0:DEPTH-1];
    logic [WORD_WIDTH-1:0] instr_index;

    initial begin
        // loads the IM with the instructions from the hex file
        $readmemh("instr_mem.hex", instr_mem);
    end

    // Address from PC counts in bytes, (+4 every time) but the IM counts in words(instructions)
    // One word = 4 bytes so value of the address is divided by 4 to get the correct index in the IM array
    assign instr_index = addr[WORD_WIDTH-1:2];
    assign instruction = (instr_index < DEPTH) ? instr_mem[instr_index] : 32'h00000013; // NOP beyond valid memory
    assign done        = (instr_index == PROGRAM_LENGTH - 1);
    // When address is not a multiple of 4, the last 2 bits are not 00, so error signal is high to indicate unaligned fetch.
    assign error       = (addr[1:0] != 2'b00) || (instr_index >= DEPTH);
endmodule
