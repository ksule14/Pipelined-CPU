// DONE TESTING
`timescale 1ns/1ps

module flush_tb;
    // from EX stage
    logic branch_resolved;
    logic branch_taken;

    // from branch predictor
    logic predicted_taken;

    // outputs to flush pipeline registers and redirect PC
    logic flush_IF_ID;
    logic flush_ID_EX;
    logic pc_redirect;

    flush_controller dut (
        .branch_resolved(branch_resolved),
        .branch_taken(branch_taken),
        .predicted_taken(predicted_taken),
        .flush_IF_ID(flush_IF_ID),
        .flush_ID_EX(flush_ID_EX),
        .pc_redirect(pc_redirect)
    );

    initial begin
        branch_resolved = 0;
        branch_taken = 0;
        predicted_taken = 0;

        no_flush();
        flush();

        $display("All tests passed!");
        $finish;
    end
    
    task automatic no_flush();
        branch_resolved = 0; // every output 0, should not cause flush or redirect
        #1;
        assert(flush_IF_ID == 0) else $fatal("Flush IF/ID should be 0 when branch not resolved");
        assert(flush_ID_EX == 0) else $fatal("Flush ID/EX should be 0 when branch not resolved");
        assert(pc_redirect == 0) else $fatal("PC redirect should be 0 when branch not resolved");
        #10;

        branch_taken = 1; // resolved still 0, should not cause flush or redirect
        #1;
        assert(flush_IF_ID == 0) else $fatal("Flush IF/ID should be 0 when branch not resolved");
        assert(flush_ID_EX == 0) else $fatal("Flush ID/EX should be 0 when branch not resolved");
        assert(pc_redirect == 0) else $fatal("PC redirect should be 0 when branch not resolved");
        #10;

        predicted_taken = 1; // resolved still 0, should not cause flush or redirect
        #1;
        assert(flush_IF_ID == 0) else $fatal("Flush IF/ID should be 0 when branch not resolved");
        assert(flush_ID_EX == 0) else $fatal("Flush ID/EX should be 0 when branch not resolved");
        assert(pc_redirect == 0) else $fatal("PC redirect should be 0 when branch not resolved");
        #10;

        branch_taken = 0; // resolved still 0, should not cause flush or redirect
        #1;
        assert(flush_IF_ID == 0) else $fatal("Flush IF/ID should be 0 when branch not resolved");
        assert(flush_ID_EX == 0) else $fatal("Flush ID/EX should be 0 when branch not resolved");
        assert(pc_redirect == 0) else $fatal("PC redirect should be 0 when branch not resolved");
        #10;

        branch_resolved = 1; // resolved but predicted and taken match, should not cause flush or redirect
        predicted_taken = 0;
        branch_taken = 0;
        #1;
        assert(flush_IF_ID == 0) else $fatal("Flush IF/ID should be 0 when predicted and taken match");
        assert(flush_ID_EX == 0) else $fatal("Flush ID/EX should be 0 when predicted and taken match");
        assert(pc_redirect == 0) else $fatal("PC redirect should be 0 when predicted and taken match");
        #10;

        branch_resolved = 1; // resolved but predicted and taken match, should not cause flush or redirect
        branch_taken = 1;
        predicted_taken = 1;
        assert(flush_IF_ID == 0) else $fatal("Flush IF/ID should be 0 when predicted and taken match");
        assert(flush_ID_EX == 0) else $fatal("Flush ID/EX should be 0 when predicted and taken match");
        assert(pc_redirect == 0) else $fatal("PC redirect should be 0 when predicted and taken match");
    endtask

    task automatic flush(); // resolved and predicted/taken mismatch, should cause flush and redirect
        branch_resolved = 1;
        branch_taken = 1;
        predicted_taken = 0;
        #1;
        assert(flush_IF_ID == 1) else $fatal("Flush IF/ID should be 1 when branch resolved and b_taken and b_predicted mismatch");
        assert(flush_ID_EX == 1) else $fatal("Flush ID/EX should be 1 when branch resolved and b_taken and b_predicted mismatch");
        assert(pc_redirect == 1) else $fatal("PC redirect should be 1 when branch resolved and b_taken and b_predicted mismatch");
        #10;

        branch_taken = 0; // resolved and predicted/taken mismatch, should cause flush and redirect
        predicted_taken = 1;
        #1;
        assert(flush_IF_ID == 1) else $fatal("Flush IF/ID should be 1 when branch resolved and b_taken and b_predicted mismatch");
        assert(flush_ID_EX == 1) else $fatal("Flush ID/EX should be 1 when branch resolved and b_taken and b_predicted mismatch");
        assert(pc_redirect == 1) else $fatal("PC redirect should be 1 when branch resolved and b_taken and b_predicted mismatch");
        #10;
    endtask
endmodule