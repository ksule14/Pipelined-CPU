module main_control (
    input [6:0] opcode,
    input logic zero_flag,
    output logic [1:0] alu_op,
    output logic branch,
    output logic mem_read,
    output logic mem_write,
    output logic mem_to_reg,
    output logic alu_src,
    output logic reg_write,
    output logic pc_src
);
    always_comb begin
        unique case (opcode)
            7'b0110011: begin // R-type
                alu_op = 2'b10;
                branch = 0;
                mem_read = 0;
                mem_write = 0;
                mem_to_reg = 0;
                alu_src = 0;
                reg_write = 1;
                pc_src = 0;
            end   
            7'b0010011: begin // Addi
                alu_op = 2'b00;
                branch = 0;
                mem_read = 0;
                mem_write = 0;
                mem_to_reg = 0;
                alu_src = 1;
                reg_write = 1;
                pc_src = 0;
            end
            7'b0000011: begin // Load
                alu_op = 2'b00;
                branch = 0;
                mem_read = 1;
                mem_write = 0;
                mem_to_reg = 1;
                alu_src = 1;
                reg_write = 1;
                pc_src = 0;
            end
            7'b0100011: begin // Store
                alu_op = 2'b00;
                branch = 0;
                mem_read = 0;
                mem_write = 1;
                mem_to_reg = 0;
                alu_src = 1;
                reg_write = 0;
                pc_src = 0;
            end

            7'b1100011: begin // BEQ
                alu_op = 2'b01;
                branch = 1;
                mem_read = 0;
                mem_write = 0;
                mem_to_reg = 0;
                alu_src = 0;
                reg_write = 0;
                if (branch & zero_flag) pc_src = 1;
                else pc_src = 0;
            end
            default: begin
                alu_op = 2'b00; // Default to ADD for unsupported opcodes
                branch = 0;
                mem_read = 0;
                mem_write = 0;
                mem_to_reg = 0;
                alu_src = 0;
                reg_write = 0;
                pc_src = 0;
            end
        endcase
    end
endmodule