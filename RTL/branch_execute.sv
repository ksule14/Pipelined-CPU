import codes_pkg::DATA_WIDTH;

module branch_execute (
    input logic clk,
    input logic rst_n,
    input logic zero_flag,
    input logic [DATA_WIDTH-1:0] branch_addr,
    output logic pc_src    
);

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pc_src <= 0;
    end else begin
        pc_src <= zero_flag & branch_addr;
    end
end
endmodule
