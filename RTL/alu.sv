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
    output logic pc_src_out,
    output logic addr_out
);
    logic [DATA_WIDTH-1:0] operand2; // internal signal for mux
    logic [DATA_WIDTH-1:0] result_next;
    logic zero_next;
    assign operand2 = alu_src ? sign_extended_imm : reg_2; // SEI if 1, reg_2 if 0

    always_comb begin
        result_next = '0;
        zero_next = 1'b0;

        // combinational ALU operations
        unique case (control)
            ADD: result_next = reg_1 + operand2;
            SUB: result_next = reg_1 - operand2;
            AND: result_next = reg_1 & operand2;
            OR: result_next = reg_1 | operand2;
            SLT: result_next = ($signed(reg_1) < $signed(operand2))
                ? {{(DATA_WIDTH-1){1'b0}}, 1'b1} : '0;
            SLTU: result_next = (reg_1 < operand2)
                ? {{(DATA_WIDTH-1){1'b0}}, 1'b1} : '0;
            default: result_next = 'x; // unknown for unsupported operations
        endcase

        if (result_next == '0)
            zero_next = 1'b1;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= '0;
            zero_flag <= 1'b0;
        end else begin
            result <= result_next;
            zero_flag <= zero_next;
        end
    end
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            branch_out <= 0;
            mem_read_out <= 0;
            mem_write_out <= 0;
            mem_to_reg_out <= 0;
            reg_write_out <= 0;
            pc_src_out <= 0;
            addr_out <= 0;
        end else begin
            branch_out <= branch;
            mem_read_out <= mem_read;
            mem_write_out <= mem_write;
            mem_to_reg_out <= mem_to_reg;
            reg_write_out <= reg_write;
            pc_src_out <= pc_src;
            addr_out <= addr;
        end
    end

endmodule
