import codes_pkg::WORD_WIDTH;

module pc (
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  pc_en,
    input  logic                  pc_redirect,
    input  logic [WORD_WIDTH-1:0] pc_branch,
    output logic [WORD_WIDTH-1:0] pc_current
);
    logic [WORD_WIDTH-1:0] pc_next;
    assign pc_next = pc_redirect ? pc_branch : (pc_current + 4);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)       pc_current <= '0;
        else if (pc_en)   pc_current <= pc_next;
    end
endmodule
