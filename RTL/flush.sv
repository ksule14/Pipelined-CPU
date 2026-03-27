import codes_pkg::WORD_WIDTH;
module flush_controller (
    input logic clk,
    input logic rst_n,

    // From EX stage
    input logic branch_resolved,
    input logic branch_taken,
    input logic [WORD_WIDTH-1:0] branch_target,
    input logic [WORD_WIDTH-1:0] branch_addr,
    
    // From branch predictor
    input logic predicted_taken,

    output logic flush_IF_ID,
    output logic flush_ID_EX,
    output logic pc_redirect,
    output logic [WORD_WIDTH-1:0] pc_corrected
);
    logic [WORD_WIDTH-1:0] branch_pc_plus4;
    logic mispredicted;

    assign branch_pc_plus4 = branch_addr + 4;

    assign mispredicted = branch_resolved &&(branch_taken != predicted_taken);
    assign flush_IF_ID = mispredicted;
    assign flush_ID_EX = mispredicted;
    assign pc_redirect = mispredicted;
    assign pc_corrected = branch_taken ? branch_target : branch_pc_plus4;

endmodule