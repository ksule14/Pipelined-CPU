import codes_pkg::WORD_WIDTH;
import codes_pkg::DEPTH;

module instruction_mem (
    input logic [WORD_WIDTH-1:0] addr,
    output logic [WORD_WIDTH-1:0] instruction
);
    logic [WORD_WIDTH-1:0] instr_mem [0:DEPTH-1]; // 8 bits for 256 words
    logic [WORD_WIDTH-1:0] addr_data;
    initial begin
        $readmemh("instr_mem.hex", instr_mem); // Load instructions from hex file
    end
    assign addr_data = instr_mem[addr[WORD_WIDTH-1:2]]; // word aligned
    assign instruction = addr_data;
endmodule