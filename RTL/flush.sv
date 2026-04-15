module flush_controller (
 
    // From EX stage
    input logic branch_resolved,
    input logic branch_taken,
    
    // From branch predictor
    input logic predicted_taken,

    output logic flush_IF_ID,
    output logic flush_ID_EX,
    output logic pc_redirect
);
    logic mispredicted;

    assign mispredicted = branch_resolved && (branch_taken != predicted_taken);
    assign flush_IF_ID = mispredicted;
    assign flush_ID_EX = mispredicted;
    assign pc_redirect = mispredicted;

endmodule