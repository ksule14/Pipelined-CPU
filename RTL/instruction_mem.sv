import codes_pkg::WORD_WIDTH;
import codes_pkg::DEPTH;

module instruction_mem (
    input  logic [WORD_WIDTH-1:0] addr,
    output logic [WORD_WIDTH-1:0] instruction
);
    logic [WORD_WIDTH-1:0] instr_mem [0:DEPTH-1];

    initial begin
        $readmemh("instr_mem.hex", instr_mem);
    end

    assign instruction = instr_mem[addr[WORD_WIDTH-1:2]]; // word aligned
endmodule
