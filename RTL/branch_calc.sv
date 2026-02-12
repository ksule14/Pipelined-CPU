import codes_pkg::DATA_WIDTH;

module branch_calc (
    input logic clk,
    input logic rst_n,
    input logic [DATA_WIDTH-1:0] current_addr,
    input logic [DATA_WIDTH-1:0] branch_offset,
    output logic [DATA_WIDTH-1:0] branch_addr
);
    logic [DATA_WIDTH-1:0] temp_branch_addr;

    always_comb begin
        temp_branch_addr = current_addr + branch_offset;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) branch_addr <= '0;
        else branch_addr <= temp_branch_addr;
    end
endmodule
