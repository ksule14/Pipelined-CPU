import codes_pkg::DATA_WIDTH;

module write_back (
input logic clk,
input logic rst_n,
input logic reg_write_in,
input logic mem_to_reg,
input logic [4:0] rd_addr,
input logic [DATA_WIDTH-1:0] alu_data,
input logic [DATA_WIDTH-1:0] mem_data,
output logic [DATA_WIDTH-1:0] wb_data,
output logic [4:0] rd_addr_out,
output logic reg_write_out
);  

    always_ff  @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wb_data <= '0;
            reg_write_out <= 1'b0;
            rd_addr_out <= 5'd0;
        end else begin
            wb_data <= mem_to_reg ? mem_data : alu_data;
            reg_write_out <= reg_write_in;
            rd_addr_out <= rd_addr;
        end
    end

endmodule