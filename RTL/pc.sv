import codes_pkg::WORD_WIDTH;
import codes_pkg::DATA_WIDTH;

module pc (
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  pc_en,
    input  logic                  pc_redirect,
    input  logic [DATA_WIDTH-1:0] pc_branch,
    output logic [DATA_WIDTH-1:0] pc_current
);
    logic [DATA_WIDTH-1:0] pc_next;
    assign pc_next = pc_redirect ? pc_branch : (pc_current + DATA_WIDTH'd4);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)       pc_current <= DATA_WIDTH'd0;
        else if (pc_en)   pc_current <= pc_next;
    end
endmodule
