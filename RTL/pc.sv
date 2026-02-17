import codes_pkg::WORD_WIDTH;
import codes_pkg::DATA_WIDTH;

module pc (
    input logic clk,
    input logic rst_n,
    input logic pc_src,
    input logic [DATA_WIDTH-1:0] pc_branch,
    output logic [DATA_WIDTH-1:0] pc_current
);
    logic [DATA_WIDTH-1:0] pc_next;
    assign pc_next = pc_src ? pc_branch : (pc_current + DATA_WIDTH'd4);
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_current <= DATA_WIDTH'd0; // Reset PC to 0
        end else begin
            pc_current <= pc_next; // Update PC
        end
    end
    
endmodule
