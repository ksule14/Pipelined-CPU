import codes_pkg::*;

module alu (
    input logic clk,
    input logic rst_n,
    input logic branch,
    input logic mem_read,
    input logic mem_write,
    input logic mem_to_reg,
    input logic reg_write,
    input logic pc_src,
    input logic addr, 
    input logic [DATA_WIDTH-1:0] reg_1, // first register value
    input logic [DATA_WIDTH-1:0] reg_2, // second register value
    input logic [DATA_WIDTH-1:0] sign_extended_imm, // immediate value
    input logic alu_src, // alu source mux from main control
    input alu_control control, // alu control lines from alu control
    output logic [DATA_WIDTH-1:0] result, // result of operation
    output logic zero_flag, // flag set if sub operation = 0 for branch
    output logic branch_out,
    output logic mem_read_out,
    output logic mem_write_out,
    output logic mem_to_reg_out,
    output logic reg_write_out,
    output logic pc_src,
    output logic addr_out
);
    logic [DATA_WIDTH-1:0] operand2; // internal signal for mux
    assign operand2 = alu_src ? sign_extended_imm : reg_2; // SEI if 1, reg_2 if 0

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= '0;
            zero_flag <= 0;
        end else begin
        // logic for operations
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
    end
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            branch_out <= 0;
            mem_read_out <= 0;
            mem_write_out <= 0;
            mem_to_reg_out <= 0;
            reg_write_out <= 0;
            pc_src <= 0;
            addr_out <= 0;
        end else begin
            branch_out <= branch;
            mem_read_out <= mem_read;
            mem_write_out <= mem_write;
            mem_to_reg_out <= mem_to_reg;
            reg_write_out <= reg_write;
            pc_src <= pc_src;
            addr_out <= addr;
        end
    end

endmodule
