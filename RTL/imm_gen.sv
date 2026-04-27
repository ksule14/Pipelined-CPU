import codes_pkg::DATA_WIDTH;
import codes_pkg::WORD_WIDTH;

// immediate generator pieces together immediate from separate fields of instruction and supplies result to ALU
module imm_gen (
    input  logic [WORD_WIDTH-1:0] instruction, // full instruction
    output logic [DATA_WIDTH-1:0] imm, // output is the 32 bit immediate
    output logic                  error // error for unsupported opcodes
);
    logic [6:0] opcode;
    assign opcode = instruction[6:0]; // opcode is the last 7 bits of the instruction

    always_comb begin
        imm   = '0; // initialize immediate to 0
        error = 'b0; // initialize error to 0

        case (opcode)
            7'b0000011, // Load
            7'b0010011: // Addi
                imm = {{(DATA_WIDTH-12){instruction[31]}}, instruction[31:20]}; // I-type immedidate is sign-extended 31st bit and bits 31-20
            7'b0100011: // Store
                imm = {{(DATA_WIDTH-12){instruction[31]}}, instruction[31:25], instruction[11:7]}; // S-type immediate is sign-extended 31st bit and bits 31-25 and 11-7
            7'b1100011: // BEQ
                imm = {{(DATA_WIDTH-13){instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0}; // B-type immediate is sign-extended 31st bit, bit 7, 30-25, 11-8
                // immediate field for branch is only 11 bits, and one left shift is added
            7'b0110011: ; // R-type: no immediate
            default:    error = 1'b1; // unsupported opcode
        endcase
    end
endmodule
