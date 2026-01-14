import codes_pkg::*;

module alu (
    input logic [DATA_WIDTH-1:0] reg_1, // first register value
    input logic [DATA_WIDTH-1:0] reg_2, // second register value
    input logic [DATA_WIDTH-1:0] sign_extended_imm, // immediate value
    input logic alu_src, // alu source mux from main control
    input alu_control control, // alu control lines from alu control
    output logic [DATA_WIDTH-1:0] result, // result of operation
    output logic zero_flag // flag set if sub operation = 0 for branch
);
    logic [DATA_WIDTH-1:0] operand2; // internal signal for mux
    assign operand2 = alu_src ? sign_extended_imm : reg_2; // SEI if 1, reg_2 if 0

// logic for operations
    always_comb begin
        unique case (control)
            ADD: begin 
                result = reg_1 + operand2;
                if (result == 0) zero_flag = 1;
                else zero_flag = 0;        
                end
            SUB: begin
                result = reg_1 - operand2;
                if (result == 0) zero_flag = 1;
                else zero_flag = 0;
            end
            AND: begin
                result = reg_1 & operand2;
                if (result == 0) zero_flag = 1;
                else zero_flag = 0;      
            end
            OR: begin
                result = reg_1 | operand2;
                if (result == 0) zero_flag = 1;
                else zero_flag = 0;      
            end
            SLT: begin
                result = ($signed(reg_1) < $signed(operand2)) ? 64'b1 : 64'b0;
                if (result == 0) zero_flag = 1;
                else zero_flag = 0;      
            end
            SLTU: begin
                result = (reg_1 < operand2) ? 64'b1 : 64'b0;
                if (result == 0) zero_flag = 1;
                else zero_flag = 0;      
            end
            default: begin
                result = 64'bx; // default to unknown for unsupported operations
                zero_flag = 0;
            end
        endcase
    end
endmodule
