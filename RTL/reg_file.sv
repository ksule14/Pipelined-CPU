import codes_pkg::DATA_WIDTH;

module reg_file (
    input logic clk,
    input logic reg_write,
    input logic mem_to_reg,
    input logic [4:0] rs1_addr,
    input logic [4:0] rs2_addr,
    input logic [4:0] rd_addr,
    input logic [DATA_WIDTH-1:0] rd_data,
    input logic [DATA_WIDTH-1:0] mem_data,
    output logic [DATA_WIDTH-1:0] rs1_data,
    output logic [DATA_WIDTH-1:0] rs2_data
);
    logic [DATA_WIDTH-1:0] regs [0:31]; // 32 registers of DATA_WIDTH

    logic [DATA_WIDTH-1:0] reg_data;
    assign reg_data = mem_to_reg ? mem_data : rd_data;

    assign rs1_data = (rs1_addr == 5'd0) ? 64'd0 : regs[rs1_addr]; // x0 is always 0
    assign rs2_data = (rs2_addr == 5'd0) ? 64'd0 : regs[rs2_addr]; // x0 is always 0

    always_ff @(posedge clk) begin
        if (reg_write && (rd_addr != 5'd0)) begin
            regs[rd_addr] <= reg_data; // Write to register if reg_write is high and not x0
        end
    end
endmodule

