// flush controller determines when flushing occurs and sends control signals to other modules
module flush_controller (
    // from EX stage
    input logic branch_resolved, // High when branch instruction is in EX/MEM stage, so we know the outcome
    input logic branch_taken, // actual branch outcome

    // From branch predictor / BTB, carried alongside this branch through the pipeline
    input logic spec_taken, // high if fetch already speculatively redirected to this branch's (tag-validated) predicted target

    // flush signals for earlier pipeline stages and redirect of pc to proper address
    output logic flush_IF_ID,
    output logic flush_ID_EX,
    output logic pc_redirect
);
    // spec_taken means fetch already jumped to this branch's BTB-predicted target the moment it was
    // fetched (see pc.sv's spec_redirect path and branch_predictor.sv's tag-validated btb_hit), instead of
    // the old always-fetch-PC+4 behavior. Since a static branch's target (pc+imm) never changes, a
    // tag-validated spec_taken redirect is guaranteed correct whenever the branch really is taken -- so a
    // flush is now only needed when the speculative decision disagrees with the real outcome:
    //   spec_taken=1, branch_taken=1 -> already on the correct path, no flush needed (this is the new case)
    //   spec_taken=1, branch_taken=0 -> wrongly sped down the taken path, flush and fall through to pc+4
    //   spec_taken=0, branch_taken=1 -> never redirected, flush and jump to branch_addr (same as before)
    //   spec_taken=0, branch_taken=0 -> already on pc+4 correctly, no flush needed (same as before)
    // All four cases collapse to: flush exactly when spec_taken and branch_taken disagree.
    assign flush_IF_ID = branch_resolved && (spec_taken != branch_taken);
    assign flush_ID_EX = branch_resolved && (spec_taken != branch_taken);
    assign pc_redirect  = branch_resolved && (spec_taken != branch_taken);

endmodule