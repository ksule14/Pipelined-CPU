import codes_pkg::*;

// ALU control module generates control signals for the ALU based on the instruction type and function codes.
module alu_ctrl (
    // alu_op is is from main control and indicates the type of instruction (R, I, load/store/addi, branch)
    input logic [1:0] alu_op,
    // bit_30 is used only for R-type instructions to differentiate between ADD and SUB
    input logic       bit_30,
    // funct3 used only for R-type instructions to determine the specific ALU operation
    input logic [2:0] funct3,
    // control signals for the ALU that determine the specific operation to perform
    output alu_control control,
    // error signal is high when an unsupported alu_op or unsupported funct3/bit_30 combination is encountered
    output logic       error
);
    // alu control is combinational
    always_comb begin
        control = ADD; // default to ADD
        error   = 1'b0; // default to no error

        case (alu_op)
            2'b00: control = ADD; // Load/Store/Add immediate
            2'b01: control = SUB; // BEQ
            2'b10: begin // R-type
                case ({bit_30, funct3})
                    4'b0_000: control = ADD;
                    4'b1_000: control = SUB; // bit_30 differentiates between ADD and SUB
                    4'b0_111: control = AND;
                    4'b0_110: control = OR;
                    4'b0_010: control = SLT;
                    4'b0_011: control = SLTU;
                    default:  error = 1'b1; // unsupported funct3/bit_30
                endcase
            end
            default: error = 1'b1; // unsupported alu_op
        endcase
    end
endmodule

