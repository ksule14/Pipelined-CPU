// DONE TESTING
`timescale 1ns/1ps
import codes_pkg::DATA_WIDTH;
import branch_fsm_pkg::*;

module b_predict_tb;
    parameter INDEX_BITS = 4;
    localparam ENTRIES = 2 ** INDEX_BITS;

    logic clk = 0;
    logic rst_n;
    logic [DATA_WIDTH-1:0] pc_fetch;
    logic predict_taken;
    logic update_en;
    logic [DATA_WIDTH-1:0] update_pc;
    logic actual_taken;

    int pass_count, fail_count;

    branch_state exp_PHT [0:ENTRIES-1]; // shadow model of the predictor

    branch_predictor #(.INDEX_BITS(INDEX_BITS)) dut (
        .clk(clk), .rst_n(rst_n),
        .pc_fetch(pc_fetch), .predict_taken(predict_taken),
        .update_en(update_en), .update_pc(update_pc), .actual_taken(actual_taken)
    );

    always #5 clk = ~clk;

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------
    function automatic logic [INDEX_BITS-1:0] pc_to_idx(input logic [DATA_WIDTH-1:0] pc);
        return pc[INDEX_BITS+1:2];
    endfunction

    // Produce a canonical PC that maps to the requested PHT index
    function automatic logic [DATA_WIDTH-1:0] idx_to_pc(input logic [INDEX_BITS-1:0] idx);
        return {{(DATA_WIDTH-INDEX_BITS-2){1'b0}}, idx, 2'b00};
    endfunction

    function automatic logic state_to_pred(input branch_state s);
        return (s == WEAK_TAKEN || s == STRONG_TAKEN);
    endfunction

    // 2-bit saturating counter next-state logic, mirroring the DUT
    function automatic branch_state nxt(input branch_state s, input logic taken);
        case (s)
            STRONG_NOT_TAKEN: return taken ? WEAK_NOT_TAKEN : STRONG_NOT_TAKEN;
            WEAK_NOT_TAKEN:   return taken ? WEAK_TAKEN     : STRONG_NOT_TAKEN;
            WEAK_TAKEN:       return taken ? STRONG_TAKEN   : WEAK_NOT_TAKEN;
            STRONG_TAKEN:     return taken ? STRONG_TAKEN   : WEAK_TAKEN;
            default:          return WEAK_NOT_TAKEN;
        endcase
    endfunction

    // -------------------------------------------------------------------------
    // Concurrent assertions
    // -------------------------------------------------------------------------
    // All entries reset to WEAK_NOT_TAKEN, so prediction must be 0 during reset
    ap_reset_predict_zero: assert property (@(posedge clk)
        !rst_n |-> !predict_taken)
        else $error("ap_reset_predict_zero: predict_taken must be 0 while reset asserted");

    // Without an update and with a stable fetch PC, the prediction must not change
    ap_no_update_stable: assert property (@(posedge clk) disable iff (!rst_n)
        (!update_en && $stable(pc_fetch)) |=> $stable(predict_taken))
        else $error("ap_no_update_stable: prediction changed without an update");

    // predict_taken must never be X or Z in simulation
    ap_predict_no_x: assert property (@(posedge clk)
        !$isunknown(predict_taken))
        else $error("ap_predict_no_x: predict_taken is X or Z");

    // -------------------------------------------------------------------------
    // Core tasks
    // -------------------------------------------------------------------------
    // Check the combinational prediction for a given fetch PC against the shadow model
    task automatic check_pred(
        input logic [DATA_WIDTH-1:0] pc,
        input string label
    );
        logic [INDEX_BITS-1:0] idx;
        logic exp_pred;
        idx      = pc_to_idx(pc);
        exp_pred = state_to_pred(exp_PHT[idx]);
        pc_fetch = pc;
        update_en = 0;
        #1;
        assert (predict_taken == exp_pred)
            pass_count++;
        else begin
            fail_count++;
            $error("[%s] predict_taken: got %b, exp %b  (idx=%0d state=%s)",
                label, predict_taken, exp_pred, idx, exp_PHT[idx].name());
        end
    endtask

    // Apply one update, advance one clock, then update the shadow model
    task automatic apply_update(
        input logic [DATA_WIDTH-1:0] pc,
        input logic taken
    );
        logic [INDEX_BITS-1:0] idx;
        idx          = pc_to_idx(pc);
        update_en    = 1;
        update_pc    = pc;
        actual_taken = taken;
        @(posedge clk); #1;
        exp_PHT[idx] = nxt(exp_PHT[idx], taken);
        update_en    = 0;
    endtask

    // Advance one clock with update disabled; optional junk signals to verify they are ignored
    task automatic tick_no_update(
        input logic [DATA_WIDTH-1:0] junk_pc,
        input logic junk_taken
    );
        update_en    = 0;
        update_pc    = junk_pc;
        actual_taken = junk_taken;
        @(posedge clk); #1;
    endtask

    // Reset DUT and re-initialise shadow model
    task automatic do_reset();
        rst_n        = 0;
        update_en    = 0;
        pc_fetch     = '0;
        update_pc    = '0;
        actual_taken = 0;
        @(posedge clk); @(posedge clk);
        rst_n = 1;
        for (int i = 0; i < ENTRIES; i++) exp_PHT[i] = WEAK_NOT_TAKEN;
        @(posedge clk);
    endtask

    // -------------------------------------------------------------------------
    // Test scenarios
    // -------------------------------------------------------------------------
    task automatic test_reset_all_not_taken();
        $display("--- reset: all entries predict not-taken ---");
        do_reset();
        for (int i = 0; i < ENTRIES; i++) begin
            string lbl;
            $sformat(lbl, "reset_entry_%0d", i);
            check_pred(idx_to_pc(i[INDEX_BITS-1:0]), lbl);
        end
    endtask

    // Walk a single entry up: WNT → WT → ST using taken updates
    task automatic test_walk_taken();
        $display("--- walk taken: WNT -> WT -> ST ---");
        do_reset();
        check_pred(idx_to_pc(4'd2), "walk_t_init");          // starts at WNT → 0
        apply_update(idx_to_pc(4'd2), 1'b1);                  // WNT→WT
        check_pred(idx_to_pc(4'd2), "walk_t_after_wnt_wt");   // predict 1
        apply_update(idx_to_pc(4'd2), 1'b1);                  // WT→ST
        check_pred(idx_to_pc(4'd2), "walk_t_after_wt_st");    // predict 1 (ST)
    endtask

    // Walk a single entry down: WNT → SNT using a not-taken update
    task automatic test_walk_not_taken();
        $display("--- walk not-taken: WNT -> SNT ---");
        do_reset();
        check_pred(idx_to_pc(4'd5), "walk_nt_init");           // WNT → 0
        apply_update(idx_to_pc(4'd5), 1'b0);                   // WNT→SNT
        check_pred(idx_to_pc(4'd5), "walk_nt_after_snt");      // predict 0 (SNT)
    endtask

    // Full walk through every state transition in both directions
    task automatic test_full_state_walk();
        $display("--- full state walk ---");
        do_reset();
        // entry 7 starts at WNT
        apply_update(idx_to_pc(4'd7), 1'b0); // WNT→SNT
        check_pred(idx_to_pc(4'd7), "fsw_SNT");
        apply_update(idx_to_pc(4'd7), 1'b1); // SNT→WNT
        check_pred(idx_to_pc(4'd7), "fsw_WNT");
        apply_update(idx_to_pc(4'd7), 1'b1); // WNT→WT
        check_pred(idx_to_pc(4'd7), "fsw_WT");
        apply_update(idx_to_pc(4'd7), 1'b1); // WT→ST
        check_pred(idx_to_pc(4'd7), "fsw_ST_up");
        apply_update(idx_to_pc(4'd7), 1'b0); // ST→WT
        check_pred(idx_to_pc(4'd7), "fsw_ST_nt");
        apply_update(idx_to_pc(4'd7), 1'b0); // WT→WNT
        check_pred(idx_to_pc(4'd7), "fsw_WT_nt");
    endtask

    // Saturation: STRONG_TAKEN and STRONG_NOT_TAKEN do not leave their state
    task automatic test_saturation();
        $display("--- saturation ---");
        do_reset();
        // Saturate entry 1 to STRONG_TAKEN via two taken updates
        apply_update(idx_to_pc(4'd1), 1'b1); // WNT→WT
        apply_update(idx_to_pc(4'd1), 1'b1); // WT→ST
        check_pred(idx_to_pc(4'd1), "sat_st_init");
        repeat (4) apply_update(idx_to_pc(4'd1), 1'b1); // must stay at ST
        check_pred(idx_to_pc(4'd1), "sat_st_hold");

        // Saturate entry 3 to STRONG_NOT_TAKEN
        apply_update(idx_to_pc(4'd3), 1'b0); // WNT→SNT
        check_pred(idx_to_pc(4'd3), "sat_snt_init");
        repeat (4) apply_update(idx_to_pc(4'd3), 1'b0); // must stay at SNT
        check_pred(idx_to_pc(4'd3), "sat_snt_hold");
    endtask

    // Prediction flip: one taken update at WNT flips predict to 1; not-taken flips it back
    task automatic test_prediction_flip();
        $display("--- prediction flip ---");
        do_reset();
        check_pred(idx_to_pc(4'd6), "flip_before");   // WNT → 0
        apply_update(idx_to_pc(4'd6), 1'b1);           // WNT→WT: flips to 1
        check_pred(idx_to_pc(4'd6), "flip_after");     // WT → 1
        apply_update(idx_to_pc(4'd6), 1'b0);           // WT→WNT: flips back to 0
        check_pred(idx_to_pc(4'd6), "flip_back");      // WNT → 0
    endtask

    // Updates to one PHT entry must not affect other entries
    task automatic test_entry_independence();
        $display("--- entry independence ---");
        do_reset();
        apply_update(idx_to_pc(4'd0), 1'b1); // WNT→WT  (entry 0)
        apply_update(idx_to_pc(4'd0), 1'b1); // WT→ST   (entry 0)
        check_pred(idx_to_pc(4'd15), "indep_e15_after_e0_update"); // entry 15 still WNT → 0
        apply_update(idx_to_pc(4'd15), 1'b0); // WNT→SNT (entry 15)
        check_pred(idx_to_pc(4'd0), "indep_e0_after_e15_update"); // entry 0 still ST → 1
    endtask

    // Two different PCs that map to the same index must share PHT state (aliasing)
    task automatic test_alias();
        logic [DATA_WIDTH-1:0] pc_a, pc_b;
        $display("--- PC aliasing ---");
        do_reset();
        pc_a = idx_to_pc(4'd4);             // e.g. 32'h10, index 4
        pc_b = pc_a | 32'h0000_0040;        // bit[6] set; pc_b[5:2] still = 4
        apply_update(pc_a, 1'b1);            // WNT→WT via pc_a
        check_pred(pc_b, "alias_pred_via_b"); // same PHT entry → predict 1
        apply_update(pc_b, 1'b0);            // WT→WNT via pc_b
        check_pred(pc_a, "alias_pred_via_a"); // same entry → predict 0 again
    endtask

    // update_en=0: DUT must ignore update signals even if they look valid
    task automatic test_update_disabled();
        $display("--- update disabled ---");
        do_reset();
        // Drive plausible update signals but assert update_en=0
        tick_no_update(idx_to_pc(4'd8), 1'b1); // entry 8 should stay WNT
        check_pred(idx_to_pc(4'd8), "upd_disabled_check");
        // Repeat with a different junk signal combination
        tick_no_update(idx_to_pc(4'd8), 1'b0); // still no state change
        check_pred(idx_to_pc(4'd8), "upd_disabled_check2");
    endtask

    // Mid-sequence reset must snap all entries back to WEAK_NOT_TAKEN
    task automatic test_mid_sequence_reset();
        $display("--- mid-sequence reset ---");
        do_reset();
        apply_update(idx_to_pc(4'd2), 1'b1);
        apply_update(idx_to_pc(4'd2), 1'b1); // entry 2 → ST
        apply_update(idx_to_pc(4'd9), 1'b0); // entry 9 → SNT
        apply_update(idx_to_pc(4'd0), 1'b1); // entry 0 → WT
        do_reset(); // full reset: all entries must return to WNT
        for (int i = 0; i < ENTRIES; i++) begin
            string lbl;
            $sformat(lbl, "msr_entry_%0d", i);
            check_pred(idx_to_pc(i[INDEX_BITS-1:0]), lbl);
        end
    endtask

    // Randomised: mix of updates and prediction checks; shadow model is ground truth
    task automatic test_random(input int iterations);
        logic [INDEX_BITS-1:0] r_idx;
        logic r_taken, r_update_en;
        logic [DATA_WIDTH-1:0] r_pc;
        string lbl;

        $display("--- randomized (%0d iterations) ---", iterations);
        do_reset();
        for (int i = 0; i < iterations; i++) begin
            r_idx       = $urandom_range(0, ENTRIES-1);
            r_taken     = $urandom_range(0, 1);
            r_update_en = $urandom_range(0, 1);
            r_pc        = idx_to_pc(r_idx);
            $sformat(lbl, "rand_%0d", i);

            if (r_update_en)
                apply_update(r_pc, r_taken);
            else
                tick_no_update(r_pc, r_taken); // verify disabled update is ignored
            check_pred(r_pc, lbl);
        end
    endtask

    // -------------------------------------------------------------------------
    // Main
    // -------------------------------------------------------------------------
    initial begin
        pass_count = 0; fail_count = 0;

        test_reset_all_not_taken();
        test_walk_taken();
        test_walk_not_taken();
        test_full_state_walk();
        test_saturation();
        test_prediction_flip();
        test_entry_independence();
        test_alias();
        test_update_disabled();
        test_mid_sequence_reset();
        test_random(500);

        $display("\n=== Results: %0d passed, %0d failed ===", pass_count, fail_count);
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("FAILURES DETECTED");
        $finish;
    end

endmodule
