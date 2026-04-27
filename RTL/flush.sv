// flush controller determines when flushing occurs and sends control signals to other modules
module flush_controller (
    // from EX stage
    input logic branch_resolved, // High when branch instruction is in EX/MEM stage, so we know the outcome
    input logic branch_taken, // actual branch outcome
    
    // From branch predictor
    input logic predicted_taken, // what was predicted by the branch predictor

    // flush signals for earlier pipeline stages and redirect of pc to proper address
    output logic flush_IF_ID,
    output logic flush_ID_EX,
    output logic pc_redirect
);
    logic mispredicted;

    // incorrect branch prediction is when branch is resolved and prediction does not match real result
    assign mispredicted = branch_resolved && (branch_taken != predicted_taken);
    // flushing and pc redirect occurs on mispredict, as everything that has been processed after the misprediction
    // is garbage and needs to be cleared
    assign flush_IF_ID = mispredicted;
    assign flush_ID_EX = mispredicted;
    assign pc_redirect = mispredicted;

endmodule