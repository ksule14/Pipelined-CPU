// DONE TESTING
`timescale 1ns/1ps

module flush_tb;
    // from EX stage
    logic branch_resolved;
    logic branch_taken;

    // from branch predictor/BTB: high if fetch already speculatively redirected
    // to this branch's tag-validated predicted target
    logic spec_taken;

    // outputs to flush pipeline registers and redirect PC
    logic flush_IF_ID;
    logic flush_ID_EX;
    logic pc_redirect;

    flush_controller dut (
        .branch_resolved(branch_resolved),
        .branch_taken(branch_taken),
        .spec_taken(spec_taken),
        .flush_IF_ID(flush_IF_ID),
        .flush_ID_EX(flush_ID_EX),
        .pc_redirect(pc_redirect)
    );

    initial begin
        branch_resolved = 0;
        branch_taken = 0;
        spec_taken = 0;

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

        spec_taken = 1; // resolved still 0, should not cause flush or redirect
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

        branch_resolved = 1; // resolved, correctly predicted not-taken (never sped off), should not flush
        spec_taken = 0;
        branch_taken = 0;
        #1;
        assert(flush_IF_ID == 0) else $fatal("Flush IF/ID should be 0 when spec_taken and branch_taken agree (not-taken)");
        assert(flush_ID_EX == 0) else $fatal("Flush ID/EX should be 0 when spec_taken and branch_taken agree (not-taken)");
        assert(pc_redirect == 0) else $fatal("PC redirect should be 0 when spec_taken and branch_taken agree (not-taken)");
        #10;

        branch_resolved = 1; // resolved, correctly sped off to the BTB target and it was taken -- already on
        branch_taken = 1;    // the right path, should not flush (this is the whole point of the BTB)
        spec_taken = 1;
        #1;
        assert(flush_IF_ID == 0) else $fatal("Flush IF/ID should be 0 when spec_taken and branch_taken agree (taken)");
        assert(flush_ID_EX == 0) else $fatal("Flush ID/EX should be 0 when spec_taken and branch_taken agree (taken)");
        assert(pc_redirect == 0) else $fatal("PC redirect should be 0 when spec_taken and branch_taken agree (taken)");
        #10;
    endtask

    task automatic flush(); // resolved and spec_taken/branch_taken mismatch, should cause flush and redirect
        branch_resolved = 1;
        branch_taken = 1;
        spec_taken = 0; // never sped off, but branch actually taken -> must flush and jump to branch_addr
        #1;
        assert(flush_IF_ID == 1) else $fatal("Flush IF/ID should be 1 when branch resolved and spec_taken/branch_taken mismatch");
        assert(flush_ID_EX == 1) else $fatal("Flush ID/EX should be 1 when branch resolved and spec_taken/branch_taken mismatch");
        assert(pc_redirect == 1) else $fatal("PC redirect should be 1 when branch resolved and spec_taken/branch_taken mismatch");
        #10;

        branch_taken = 0; // sped off down the taken path, but branch actually not taken -> must flush back to pc+4
        spec_taken = 1;
        #1;
        assert(flush_IF_ID == 1) else $fatal("Flush IF/ID should be 1 when branch resolved and spec_taken/branch_taken mismatch");
        assert(flush_ID_EX == 1) else $fatal("Flush ID/EX should be 1 when branch resolved and spec_taken/branch_taken mismatch");
        assert(pc_redirect == 1) else $fatal("PC redirect should be 1 when branch resolved and spec_taken/branch_taken mismatch");
        #10;
    endtask
endmodule