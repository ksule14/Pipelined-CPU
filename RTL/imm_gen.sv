import codes_pkg::DATA_WIDTH;
import codes_pkg::WORD_WIDTH;

module imm_gen (
    input logic [WORD_WIDTH-1:0] instruction,
    output logic [DATA_WIDTH-1:0] sign_extended_imm
);

    logic [DATA_WIDTH-1:0] imm;
    logic [6:0] opcode;

    assign opcode = instruction[6:0];

    always_comb begin
        unique case (opcode)
            7'b0000011, // Load
            7'b0010011: // Addi
                imm = {{(DATA_WIDTH-12){instruction[31]}}, instruction[31:20]}; // I-type
            7'b0100011: // Store
                imm = {{(DATA_WIDTH-12){instruction[31]}}, instruction[31:25], instruction[11:7]}; // S-type
            7'b1100011: // BEQ
                imm = {{(DATA_WIDTH-13){instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0}; // B-type
            default:
                imm = 64'bx; // Default to unknown for unsupported opcodes
        endcase
    end

    assign sign_extended_imm = imm;
endmodule
