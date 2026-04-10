import codes_pkg::DATA_WIDTH;
import codes_pkg::WORD_WIDTH;

module imm_gen (
    input  logic [WORD_WIDTH-1:0] instruction,
    output logic [DATA_WIDTH-1:0] imm,
    output logic                  error
);
    logic [6:0] opcode;
    assign opcode = instruction[6:0];

    always_comb begin
        imm   = '0;
        error = 1'b0;

        case (opcode)
            7'b0000011, // Load
            7'b0010011: // Addi
                imm = {{(DATA_WIDTH-12){instruction[31]}}, instruction[31:20]}; // I-type
            7'b0100011: // Store
                imm = {{(DATA_WIDTH-12){instruction[31]}}, instruction[31:25], instruction[11:7]}; // S-type
            7'b1100011: // BEQ
                imm = {{(DATA_WIDTH-13){instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0}; // B-type
            7'b0110011: ; // R-type: no immediate
            default:    error = 1'b1; // unsupported opcode
        endcase
    end
endmodule
