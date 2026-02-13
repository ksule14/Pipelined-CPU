import codes_pkg::DATA_WIDTH;

module reg_file (
    input logic clk,
    input logic reg_write,
    input logic [4:0] rs1_addr,
    input logic [4:0] rs2_addr,
    input logic [4:0] rd_addr,
    input logic [DATA_WIDTH-1:0] write_data,
    output logic [DATA_WIDTH-1:0] rs1_data,
    output logic [DATA_WIDTH-1:0] rs2_data
);
    logic [DATA_WIDTH-1:0] regs [0:31]; // 32 registers of DATA_WIDTH

    always_comb begin
        rs1_data = (rs1_addr == 5'd0) ? '0 : regs[rs1_addr];
        rs2_data = (rs2_addr == 5'd0) ? '0 : regs[rs2_addr];
    end

    always_ff @(posedge clk) begin
        regs[5'd0] <= '0;

        if (reg_write && (rd_addr != 5'd0)) begin
            regs[rd_addr] <= write_data;
        end
    end
endmodule

