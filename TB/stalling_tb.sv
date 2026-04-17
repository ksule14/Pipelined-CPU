`timescale 1ns/1ps

module stalling_tb;
    parameter REG_WIDTH = 5;

    logic [REG_WIDTH-1:0] if_id_rs1;
    logic [REG_WIDTH-1:0] if_id_rs2;
    logic [REG_WIDTH-1:0] id_ex_rd;
    logic                 id_ex_mem_load, ex_branch_taken, pc_redirect, mem_stall;

    logic pc_en;
    logic if_id_en;
    logic id_ex_en;
    logic id_ex_flush;
    logic if_id_flush;
    logic ex_mem_en;
    logic mem_wb_en;
    logic stall;

    int pass_count, fail_count;

    stalling_u #(.REG_WIDTH(REG_WIDTH)) dut (
        .if_id_rs1(if_id_rs1),
        .if_id_rs2(if_id_rs2),
        .id_ex_mem_load(id_ex_mem_load),
        .id_ex_rd(id_ex_rd),
        .ex_branch_taken(ex_branch_taken),
        .pc_redirect(pc_redirect),
        .mem_stall(mem_stall),
        .pc_en(pc_en),
        .if_id_en(if_id_en),
        .id_ex_en(id_ex_en),
        .id_ex_flush(id_ex_flush),
        .if_id_flush(if_id_flush),
        .ex_mem_en(ex_mem_en),
        .mem_wb_en(mem_wb_en),
        .stall(stall)
    );

    logic clk = 0;
    always #5 clk = ~clk; // 100MHz clock
     // if_id_flush is always exactly ex_branch_taken (no other logic touches it)
    ap_if_id_flush: assert property (@(posedge clk)
        if_id_flush === ex_branch_taken)
        else $error("ap_if_id_flush: if_id_flush=%b ex_branch_taken=%b",
                    if_id_flush, ex_branch_taken);

    // Cache-miss freeze: all downstream pipeline enables must deassert
    ap_mem_stall_id_ex_en: assert property (@(posedge clk)
        mem_stall |-> !id_ex_en)
        else $error("ap_mem_stall_id_ex_en: id_ex_en must be 0 during mem_stall");

    ap_mem_stall_ex_mem_en: assert property (@(posedge clk)
        mem_stall |-> !ex_mem_en)
        else $error("ap_mem_stall_ex_mem_en: ex_mem_en must be 0 during mem_stall");

    ap_mem_stall_mem_wb_en: assert property (@(posedge clk)
        mem_stall |-> !mem_wb_en)
        else $error("ap_mem_stall_mem_wb_en: mem_wb_en must be 0 during mem_stall");

    // pc_redirect unconditionally forces pc_en high (overrides stall suppression)
    ap_redirect_pc_en: assert property (@(posedge clk)
        pc_redirect |-> pc_en)
        else $error("ap_redirect_pc_en: pc_en must be high when pc_redirect asserted");

    // Stall without redirect must freeze fetch
    ap_stall_pc_en: assert property (@(posedge clk)
        (stall && !pc_redirect) |-> !pc_en)
        else $error("ap_stall_pc_en: pc_en must be low when stalling without redirect");

    ap_stall_if_id_en: assert property (@(posedge clk)
        stall |-> !if_id_en)
        else $error("ap_stall_if_id_en: if_id_en must be low during any stall");

    // x0 destination must never trigger a load-use stall on its own
    ap_no_x0_hazard: assert property (@(posedge clk)
        (id_ex_rd == '0) |-> (!stall || mem_stall))
        else $error("ap_no_x0_hazard: rd=x0 must never cause a load-use stall");

    // -------------------------------------------------------------------------
    // Core checker task: drive inputs, compute expected, assert each output
    // -------------------------------------------------------------------------
    task automatic check(
        input logic [REG_WIDTH-1:0] rs1, rs2, rd,
        input logic                 mem_load, branch_taken, redirect, mem_stall_in,
        input string                label
    );
        logic load_use;
        logic exp_stall, exp_pc_en, exp_if_id_en, exp_id_ex_en;
        logic exp_id_ex_flush, exp_if_id_flush, exp_ex_mem_en, exp_mem_wb_en;

        load_use        = mem_load && (rd != '0) && ((rd == rs1) || (rd == rs2));
        exp_stall       = load_use || mem_stall_in;
        exp_pc_en       = redirect || ~exp_stall;
        exp_if_id_en    = ~exp_stall;
        exp_id_ex_en    = ~mem_stall_in;
        exp_id_ex_flush = (load_use && !mem_stall_in) || branch_taken;
        exp_if_id_flush = branch_taken;
        exp_ex_mem_en   = ~mem_stall_in;
        exp_mem_wb_en   = ~mem_stall_in;

        if_id_rs1       = rs1;
        if_id_rs2       = rs2;
        id_ex_rd        = rd;
        id_ex_mem_load  = mem_load;
        ex_branch_taken = branch_taken;
        pc_redirect     = redirect;
        mem_stall       = mem_stall_in;
        #1;

        assert (stall == exp_stall)
            pass_count++;
        else begin
            fail_count++;
            $error("[%s] stall: got %b, exp %b", label, stall, exp_stall);
        end

        assert (pc_en == exp_pc_en)
            pass_count++;
        else begin
            fail_count++;
            $error("[%s] pc_en: got %b, exp %b", label, pc_en, exp_pc_en);
        end

        assert (if_id_en == exp_if_id_en)
            pass_count++;
        else begin
            fail_count++;
            $error("[%s] if_id_en: got %b, exp %b", label, if_id_en, exp_if_id_en);
        end

        assert (id_ex_en == exp_id_ex_en)
            pass_count++;
        else begin
            fail_count++;
            $error("[%s] id_ex_en: got %b, exp %b", label, id_ex_en, exp_id_ex_en);
        end

        assert (id_ex_flush == exp_id_ex_flush)
            pass_count++;
        else begin
            fail_count++;
            $error("[%s] id_ex_flush: got %b, exp %b", label, id_ex_flush, exp_id_ex_flush);
        end

        assert (if_id_flush == exp_if_id_flush)
            pass_count++;
        else begin
            fail_count++;
            $error("[%s] if_id_flush: got %b, exp %b", label, if_id_flush, exp_if_id_flush);
        end

        assert (ex_mem_en == exp_ex_mem_en)
            pass_count++;
        else begin
            fail_count++;
            $error("[%s] ex_mem_en: got %b, exp %b", label, ex_mem_en, exp_ex_mem_en);
        end

        assert (mem_wb_en == exp_mem_wb_en)
            pass_count++;
        else begin
            fail_count++;
            $error("[%s] mem_wb_en: got %b, exp %b", label, mem_wb_en, exp_mem_wb_en);
        end
    endtask

    // -------------------------------------------------------------------------
    // Scenario tasks
    // -------------------------------------------------------------------------

    task automatic test_no_hazard();
        $display("--- no hazard ---");
        check(5'd1,  5'd2,  5'd3,  0, 0, 0, 0, "no_hazard_basic");
        check(5'd0,  5'd0,  5'd0,  1, 0, 0, 0, "no_hazard_all_zero_regs");
        check(5'd31, 5'd30, 5'd29, 0, 0, 0, 0, "no_hazard_high_regs");
        check(5'd1,  5'd2,  5'd0,  1, 0, 0, 0, "no_hazard_rd_x0");       // rd=x0 must never hazard
        check(5'd1,  5'd2,  5'd3,  1, 0, 0, 0, "no_hazard_no_reg_match");
    endtask

    task automatic test_load_use_rs1();
        $display("--- load-use rs1 ---");
        check(5'd5,  5'd2, 5'd5,  1, 0, 0, 0, "load_use_rs1");
        check(5'd31, 5'd1, 5'd31, 1, 0, 0, 0, "load_use_rs1_high");
    endtask

    task automatic test_load_use_rs2();
        $display("--- load-use rs2 ---");
        check(5'd2, 5'd7,  5'd7,  1, 0, 0, 0, "load_use_rs2");
        check(5'd1, 5'd31, 5'd31, 1, 0, 0, 0, "load_use_rs2_high");
    endtask

    task automatic test_load_use_both();
        $display("--- load-use rs1 and rs2 ---");
        check(5'd4, 5'd4, 5'd4, 1, 0, 0, 0, "load_use_rs1_rs2_match");
    endtask

    // Cache miss: freeze entire pipeline; id_ex_flush must NOT fire from load_use alone
    task automatic test_mem_stall();
        $display("--- mem_stall ---");
        check(5'd1, 5'd2, 5'd3, 0, 0, 0, 1, "mem_stall_only");
        check(5'd5, 5'd2, 5'd5, 1, 0, 0, 1, "mem_stall_suppresses_load_use_flush");
    endtask

    task automatic test_branch_taken();
        $display("--- branch taken ---");
        check(5'd1, 5'd2, 5'd3, 0, 1, 0, 0, "branch_taken_basic");
        check(5'd1, 5'd2, 5'd3, 0, 1, 1, 0, "branch_taken_with_redirect");
    endtask

    task automatic test_load_use_and_branch();
        $display("--- load-use + branch taken ---");
        check(5'd5, 5'd2, 5'd5, 1, 1, 0, 0, "load_use_rs1_and_branch");
        check(5'd2, 5'd7, 5'd7, 1, 1, 0, 0, "load_use_rs2_and_branch");
    endtask

    task automatic test_branch_and_mem_stall();
        $display("--- branch taken + mem_stall ---");
        check(5'd1, 5'd2, 5'd3, 0, 1, 0, 1, "branch_and_mem_stall");
        // if_id_flush must still fire even when the rest of the pipeline is frozen
        check(5'd5, 5'd2, 5'd5, 1, 1, 0, 1, "branch_mem_stall_load_use_all");
    endtask

    // pc_redirect ORs into pc_en — must override stall suppression
    task automatic test_redirect_during_stall();
        $display("--- pc_redirect during stall ---");
        check(5'd5, 5'd2, 5'd5, 1, 0, 1, 0, "redirect_overrides_load_use");
        check(5'd1, 5'd2, 5'd3, 0, 0, 1, 1, "redirect_overrides_mem_stall");
    endtask

    // Uniform random: full input space
    task automatic test_random(input int iterations);
        logic [REG_WIDTH-1:0] r_rs1, r_rs2, r_rd;
        logic r_mem_load, r_branch, r_redirect, r_mem_stall;
        string lbl;

        $display("--- randomized (%0d iterations) ---", iterations);
        for (int i = 0; i < iterations; i++) begin
            r_rs1       = $urandom_range(0, 2**REG_WIDTH - 1);
            r_rs2       = $urandom_range(0, 2**REG_WIDTH - 1);
            r_rd        = $urandom_range(0, 2**REG_WIDTH - 1);
            r_mem_load  = $urandom_range(0, 1);
            r_branch    = $urandom_range(0, 1);
            r_redirect  = $urandom_range(0, 1);
            r_mem_stall = $urandom_range(0, 1);
            $sformat(lbl, "rand_%0d", i);
            check(r_rs1, r_rs2, r_rd, r_mem_load, r_branch, r_redirect, r_mem_stall, lbl);
        end
    endtask

    // Biased random: 75% chance rd matches rs1/rs2 to stress load-use path
    task automatic test_random_biased(input int iterations);
        logic [REG_WIDTH-1:0] r_rs1, r_rs2, r_rd;
        logic r_mem_load, r_branch, r_redirect, r_mem_stall;
        int   bias;
        string lbl;

        $display("--- biased random (%0d iterations) ---", iterations);
        for (int i = 0; i < iterations; i++) begin
            bias = $urandom_range(0, 3);
            case (bias)
                0: begin r_rd = $urandom_range(1,31); r_rs1 = r_rd;               r_rs2 = $urandom_range(0,31); end
                1: begin r_rd = $urandom_range(1,31); r_rs2 = r_rd;               r_rs1 = $urandom_range(0,31); end
                2: begin r_rd = $urandom_range(1,31); r_rs1 = r_rd;               r_rs2 = r_rd;                 end
                3: begin r_rd = $urandom_range(0,31); r_rs1 = $urandom_range(0,31); r_rs2 = $urandom_range(0,31); end
            endcase
            r_mem_load  = $urandom_range(0, 1);
            r_branch    = $urandom_range(0, 1);
            r_redirect  = $urandom_range(0, 1);
            r_mem_stall = $urandom_range(0, 1);
            $sformat(lbl, "biased_%0d", i);
            check(r_rs1, r_rs2, r_rd, r_mem_load, r_branch, r_redirect, r_mem_stall, lbl);
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;

        // Initialise to quiescent state before concurrent assertions start sampling
        if_id_rs1 = '0; if_id_rs2 = '0; id_ex_rd = '0;
        id_ex_mem_load = 0; ex_branch_taken = 0; pc_redirect = 0; mem_stall = 0;
        @(posedge clk);

        test_no_hazard();
        test_load_use_rs1();
        test_load_use_rs2();
        test_load_use_both();
        test_mem_stall();
        test_branch_taken();
        test_load_use_and_branch();
        test_branch_and_mem_stall();
        test_redirect_during_stall();
        test_random(1000);
        test_random_biased(500);

        $display("\n=== Results: %0d passed, %0d failed ===", pass_count, fail_count);
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("FAILURES DETECTED");
        $finish;
    end

endmodule


    