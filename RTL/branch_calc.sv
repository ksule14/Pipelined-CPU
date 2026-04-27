import codes_pkg::DATA_WIDTH;
import codes_pkg::WORD_WIDTH;

// branch calculator calculates the address of the address to branch to
module branch_calc (
    input  logic [WORD_WIDTH-1:0] pc, // current address in the pc
    input  logic [DATA_WIDTH-1:0] imm, // the immediate from the immediate generator
    output logic [WORD_WIDTH-1:0] branch_addr // the resulting branch address
);
    assign branch_addr = pc + imm; // the branch address is the pc added to the immediate and it supports forward and backward branching
endmodule
