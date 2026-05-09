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
    // This design always fetches PC+4 (no speculative redirect in the fetch stage).
    // Therefore a taken branch always requires a flush and redirect, regardless of
    // what the predictor said.  A not-taken branch only needs a flush when the
    // predictor incorrectly said "taken" (predicted_taken=1, branch_taken=0).
    // Combined: flush whenever branch_taken OR predicted_taken is true.
    assign flush_IF_ID = branch_resolved && (branch_taken || predicted_taken);
    assign flush_ID_EX = branch_resolved && (branch_taken || predicted_taken);
    assign pc_redirect  = branch_resolved && (branch_taken || predicted_taken);

endmodule