import codes_pkg::*;

module alu_ctrl (
    input logic [1:0] alu_op,
    input logic       bit_30,
    input logic [2:0] funct3,
    output alu_control control
);

    always_comb begin
        unique case (alu_op)
            2'b00: control = ADD; // Load/Store/Add immediate
            2'b01: control = SUB; // BEQ
            2'b10: begin // R-type
                unique case ({bit_30, funct3})
                    4'b0_000: control = ADD; // ADD
                    4'b1_000: control = SUB; // SUB
                    4'b0_111: control = AND; // AND
                    4'b0_110: control = OR;  // OR
                    4'b0_010: control = SLT; // SLT
                    4'b0_011: control = SLTU; // SLTU
                    default : control = ADD; // Default to unknown for unsupported funct3/bit_30 combinations
                endcase
            end
            default: control = ADD; // Default to ADD for unsupported alu_op
        endcase
    end
endmodule

