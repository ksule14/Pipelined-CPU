import codes_pkg::*;

module main_control (
    input  logic [6:0] opcode,
    output logic [1:0] alu_op,
    output logic       branch,
    output logic       mem_read,
    output logic       mem_write,
    output logic       mem_to_reg,
    output logic       alu_src,
    output logic       reg_write
);
    always_comb begin
        alu_op     = 2'b00;
        branch     = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        mem_to_reg = 1'b0;
        alu_src    = 1'b0;
        reg_write  = 1'b0;

        unique case (opcode)
            7'b0110011: begin // R-type
                alu_op    = 2'b10;
                reg_write = 1'b1;
            end
            7'b0010011: begin // I-type
                alu_src   = 1'b1;
                reg_write = 1'b1;
            end
            7'b0000011: begin // Load
                mem_read   = 1'b1;
                mem_to_reg = 1'b1;
                alu_src    = 1'b1;
                reg_write  = 1'b1;
            end
            7'b0100011: begin // Store
                mem_write = 1'b1;
                alu_src   = 1'b1;
            end
            7'b1100011: begin // BEQ
                alu_op = 2'b01;
                branch = 1'b1;
            end
        endcase
    end
endmodule
