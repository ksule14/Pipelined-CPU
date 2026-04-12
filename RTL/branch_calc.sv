import codes_pkg::DATA_WIDTH;
import codes_pkg::WORD_WIDTH;

module branch_calc (
    input  logic [WORD_WIDTH-1:0] pc,
    input  logic [DATA_WIDTH-1:0] imm,
    output logic [WORD_WIDTH-1:0] branch_addr
);
    assign branch_addr = pc + imm;
endmodule
