import codes_pkg::*;

module alu_ctrl (
    input logic [1:0] alu_op,
    input logic       bit_30,
    input logic [2:0] funct3,
    output alu_control control,
    output logic       error
);

    always_comb begin
        control = ADD;
        error   = 1'b0;

        case (alu_op)
            2'b00: control = ADD; // Load/Store/Add immediate
            2'b01: control = SUB; // BEQ
            2'b10: begin // R-type
                case ({bit_30, funct3})
                    4'b0_000: control = ADD;
                    4'b1_000: control = SUB;
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

