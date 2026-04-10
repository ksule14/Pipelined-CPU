import codes_pkg::*;

module alu (
    input  logic [DATA_WIDTH-1:0] rs1_data,
    input  logic [DATA_WIDTH-1:0] rs2_data,
    input  logic [DATA_WIDTH-1:0] imm,
    input  logic                  alu_src,
    input  alu_control            control,
    output logic [DATA_WIDTH-1:0] alu_result,
    output logic                  zero_flag
);
    logic [DATA_WIDTH-1:0] operand2;
    assign operand2 = alu_src ? imm : rs2_data;

    always_comb begin
        alu_result = '0;
        zero_flag  = 1'b0;

        case (control)
            ADD:     alu_result = rs1_data + operand2;
            SUB:     alu_result = rs1_data - operand2;
            AND:     alu_result = rs1_data & operand2;
            OR:      alu_result = rs1_data | operand2;
            SLT:     alu_result = ($signed(rs1_data) < $signed(operand2))
                         ? {{(DATA_WIDTH-1){1'b0}}, 1'b1} : '0;
            SLTU:    alu_result = (rs1_data < operand2)
                         ? {{(DATA_WIDTH-1){1'b0}}, 1'b1} : '0;
            default: alu_result = 'x;
        endcase

        if (alu_result == '0)
            zero_flag = 1'b1;
    end
endmodule
