import codes_pkg::*;

// ALU calculates values based on the operation and supplied operands. Calculates using 32 bits and returns 32 bits
module alu (
    input  logic [DATA_WIDTH-1:0] rs1_data, // first operand, from reg file
    input  logic [DATA_WIDTH-1:0] rs2_data, // data from second reg in reg file
    input  logic [DATA_WIDTH-1:0] imm, // immediate from immediate generator
    input  logic                  alu_src, // control signal from main control
    input  alu_control            control, // from alu control, determines the operation
    output logic [DATA_WIDTH-1:0] alu_result, // output value of ALU
    output logic                  zero_flag // high if calculated value is zero
);
    logic [DATA_WIDTH-1:0] operand2;
    assign operand2 = alu_src ? imm : rs2_data; // if alu_src == 1: operand2 == imm. if alu_src == 0: operand2 == rs2_data

    always_comb begin
        alu_result = '0; // initialize alu_result to 0
        zero_flag  = 1'b0; // initialize zero flag to 0

        case (control)
            ADD:     alu_result = rs1_data + operand2; // add operands
            SUB:     alu_result = rs1_data - operand2; // subtract operands
            AND:     alu_result = rs1_data & operand2; // bitwise AND operands
            OR:      alu_result = rs1_data | operand2; // bitwise OR operands
            SLT:     alu_result = ($signed(rs1_data) < $signed(operand2)) // sign operands first, then less than comparison
                         ? 'b1: '0; // result is 1 if true, 0 if false
            SLTU:    alu_result = (rs1_data < operand2) // unsigned comparison
                         ? 'b1 : '0;
            default: alu_result = 'x; // default to X
        endcase

        if (alu_result == '0)
            zero_flag = 1'b1; // zero flag used for branch instructions to determine if branch should be taken
    end
endmodule
