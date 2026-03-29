import codes_pkg::WORD_WIDTH;
import codes_pkg::DEPTH;

module instruction_mem (
    input logic clk,
    input logic [WORD_WIDTH-1:0] addr,
    output logic [WORD_WIDTH-1:0] instruction,
    output logic [WORD_WIDTH-1:0] pc_addr
);
    logic [WORD_WIDTH-1:0] instr_mem [0:DEPTH-1]; // 8 bits for 256 words

    initial begin
        $readmemh("instr_mem.hex", instr_mem); // Load instructions from hex file
    end
    always_ff @(posedge clk) begin
        instruction <= instr_mem[addr[WORD_WIDTH-1:2]]; // word aligned
        pc_addr <= addr;
    end
endmodule