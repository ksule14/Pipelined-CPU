// Main control unit for the core, generates control signals based on the opcode of the instruction.
module main_control (
    input  logic [6:0] opcode, // 7 bit opcode from instruction. Determines the control signals
    output logic [1:0] alu_op, // 2 bit signal sent to alu_control to determine type of instruction
    output logic       branch, // branch signal is high for branch instructions
    output logic       mem_read, // mem_read is high for load instructions
    output logic       mem_write, // mem_write is high for store instructions
    output logic       mem_to_reg, // mem_to_reg is high for load instructions to select memory data to write back to reg file in wb stage
    output logic       alu_src, // high for means second operand comes from immediate, low means it comes from reg file (rs2) 
    output logic       reg_write, // high means data is written back to reg file, low means no write back
    output logic       error // error signal is high when an unsupported opcode is encountered
);
    always_comb begin
        // controls signals default to 0 and no error
        alu_op     = 2'b00; // default to load/store/addi
        branch     = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        mem_to_reg = 1'b0;
        alu_src    = 1'b0;
        reg_write  = 1'b0;
        error      = 1'b0;

        case (opcode)
            7'b0110011: begin // R-type
                alu_op    = 2'b10; // R-type instructions require more decoding in the alu control
                reg_write = 1'b1; // data will be written back to the reg file
            end
            7'b0010011: begin // I-type
                alu_src   = 1'b1; // immediate is the second operand for I-type instructions
                reg_write = 1'b1; // data will be written back to the reg file
            end
            7'b0000011: begin // Load
                mem_read   = 1'b1; // memory will be read for load instructions
                mem_to_reg = 1'b1; // data loaded from memory will be written back to reg file
                alu_src    = 1'b1; // immediate is the second operand for load instructions (used to calculate memory address)
                reg_write  = 1'b1; // data will be written back to the reg file
            end
            7'b0100011: begin // Store
                mem_write = 1'b1; // memory will be written for store instructions
                alu_src   = 1'b1; // second operand comes from immediate for store instructions (used to calculate memory address)
            end
            7'b1100011: begin // BEQ
                alu_op = 2'b01; // alu_op for branch instructions
                branch = 1'b1; // branch signal is high for branch instructions
            end
                default: error = 1'b1; // unsupported opcode
        endcase
    end
endmodule
