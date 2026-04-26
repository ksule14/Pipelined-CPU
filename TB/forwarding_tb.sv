// DONE TESTING
`timescale 1ns/1ps

module forwarding_tb;
    parameter REG_WIDTH = 5;

    logic [REG_WIDTH-1:0] ex_rs1;
    logic [REG_WIDTH-1:0] ex_rs2;
    logic [REG_WIDTH-1:0] rd_mem;
    logic [REG_WIDTH-1:0] rd_wb;
    logic                 reg_write_mem;
    logic                 ex_mem_is_load;
    logic                 reg_write_wb;

    logic [1:0] forward_a;
    logic [1:0] forward_b;

    forwarding_u #(.REG_WIDTH(REG_WIDTH)) dut (
        .ex_rs1(ex_rs1),
        .ex_rs2(ex_rs2),
        .rd_mem(rd_mem),
        .rd_wb(rd_wb),
        .reg_write_mem(reg_write_mem),
        .ex_mem_is_load(ex_mem_is_load),
        .reg_write_wb(reg_write_wb),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    int pass_count = 0;
    int fail_count = 0;

    logic clk = 0;
    always #5 clk = ~clk;

    // x0 destination must never produce a forward
    ap_no_x0_mem_a: assert property (@(posedge clk)
        (rd_mem == '0) |-> (forward_a != 2'b10))
        else $error("ap_no_x0_mem_a: rd_mem=x0 must not forward to A");

    ap_no_x0_mem_b: assert property (@(posedge clk)
        (rd_mem == '0) |-> (forward_b != 2'b10))
        else $error("ap_no_x0_mem_b: rd_mem=x0 must not forward to B");

    ap_no_x0_wb_a: assert property (@(posedge clk)
        (rd_wb == '0) |-> (forward_a != 2'b01))
        else $error("ap_no_x0_wb_a: rd_wb=x0 must not forward to A");

    ap_no_x0_wb_b: assert property (@(posedge clk)
        (rd_wb == '0) |-> (forward_b != 2'b01))
        else $error("ap_no_x0_wb_b: rd_wb=x0 must not forward to B");

    // A load in MEM must never produce a 2'b10 (EX/MEM) forward
    ap_load_no_exmem_a: assert property (@(posedge clk)
        ex_mem_is_load |-> (forward_a != 2'b10))
        else $error("ap_load_no_exmem_a: load in MEM must not forward 2'b10 to A");

    ap_load_no_exmem_b: assert property (@(posedge clk)
        ex_mem_is_load |-> (forward_b != 2'b10))
        else $error("ap_load_no_exmem_b: load in MEM must not forward 2'b10 to B");

    // No write intent means no forward from that stage
    ap_no_write_mem_a: assert property (@(posedge clk)
        !reg_write_mem |-> (forward_a != 2'b10))
        else $error("ap_no_write_mem_a: reg_write_mem=0 must not forward 2'b10 to A");

    ap_no_write_mem_b: assert property (@(posedge clk)
        !reg_write_mem |-> (forward_b != 2'b10))
        else $error("ap_no_write_mem_b: reg_write_mem=0 must not forward 2'b10 to B");

    ap_no_write_wb_a: assert property (@(posedge clk)
        !reg_write_wb |-> (forward_a != 2'b01))
        else $error("ap_no_write_wb_a: reg_write_wb=0 must not forward 2'b01 to A");

    ap_no_write_wb_b: assert property (@(posedge clk)
        !reg_write_wb |-> (forward_b != 2'b01))
        else $error("ap_no_write_wb_b: reg_write_wb=0 must not forward 2'b01 to B");

    // -------------------------------------------------------------------------
    // Reference model + checker
    // -------------------------------------------------------------------------
    function automatic logic [1:0] expected_fwd(
        input logic [REG_WIDTH-1:0] rs,
        input logic [REG_WIDTH-1:0] rdm, rdw,
        input logic                  rwm, is_load, rww
    );
        if (rwm && !is_load && (rdm != '0) && (rdm == rs))
            return 2'b10;
        else if (rww && (rdw != '0) && (rdw == rs))
            return 2'b01;
        else
            return 2'b00;
    endfunction

    task automatic check(
        input logic [REG_WIDTH-1:0] rs1_in, rs2_in, rdm_in, rdw_in,
        input logic                  rwm_in, load_in, rww_in,
        input string                 label
    );
        logic [1:0] exp_a, exp_b;

        ex_rs1         = rs1_in;
        ex_rs2         = rs2_in;
        rd_mem         = rdm_in;
        rd_wb          = rdw_in;
        reg_write_mem  = rwm_in;
        ex_mem_is_load = load_in;
        reg_write_wb   = rww_in;
        #1;

        exp_a = expected_fwd(rs1_in, rdm_in, rdw_in, rwm_in, load_in, rww_in);
        exp_b = expected_fwd(rs2_in, rdm_in, rdw_in, rwm_in, load_in, rww_in);

        assert (forward_a == exp_a)
            pass_count++;
        else begin
            fail_count++;
            $error("[%s] forward_a: got %02b, exp %02b  (rs1=%0d rd_mem=%0d rd_wb=%0d rwm=%b load=%b rww=%b)",
                   label, forward_a, exp_a, rs1_in, rdm_in, rdw_in, rwm_in, load_in, rww_in);
        end

        assert (forward_b == exp_b)
            pass_count++;
        else begin
            fail_count++;
            $error("[%s] forward_b: got %02b, exp %02b  (rs2=%0d rd_mem=%0d rd_wb=%0d rwm=%b load=%b rww=%b)",
                   label, forward_b, exp_b, rs2_in, rdm_in, rdw_in, rwm_in, load_in, rww_in);
        end
    endtask

    // -------------------------------------------------------------------------
    // Scenario tasks
    // -------------------------------------------------------------------------
    task automatic test_no_forward();
        $display("--- no forwarding ---");
        check(5'd1,  5'd2,  5'd3,  5'd4,  0, 0, 0, "no_fwd_no_write");
        check(5'd1,  5'd2,  5'd3,  5'd4,  1, 0, 1, "no_fwd_no_match");
        check(5'd0,  5'd0,  5'd0,  5'd0,  1, 0, 1, "no_fwd_all_x0");
        check(5'd1,  5'd2,  5'd0,  5'd0,  1, 0, 1, "no_fwd_rd_x0");
    endtask

    task automatic test_exmem_forward_rs1();
        $display("--- EX/MEM forward rs1 ---");
        check(5'd5,  5'd2,  5'd5,  5'd9,  1, 0, 0, "exmem_a_basic");
        check(5'd31, 5'd2,  5'd31, 5'd9,  1, 0, 0, "exmem_a_high_reg");
        check(5'd5,  5'd2,  5'd5,  5'd9,  1, 0, 1, "exmem_a_over_wb");  // MEM wins over WB
    endtask

    task automatic test_exmem_forward_rs2();
        $display("--- EX/MEM forward rs2 ---");
        check(5'd2,  5'd7,  5'd7,  5'd9,  1, 0, 0, "exmem_b_basic");
        check(5'd2,  5'd31, 5'd31, 5'd9,  1, 0, 0, "exmem_b_high_reg");
        check(5'd2,  5'd7,  5'd7,  5'd9,  1, 0, 1, "exmem_b_over_wb");
    endtask

    task automatic test_exmem_forward_both();
        $display("--- EX/MEM forward both ---");
        check(5'd4,  5'd4,  5'd4,  5'd9,  1, 0, 0, "exmem_both_same_rd");
        check(5'd3,  5'd5,  5'd3,  5'd9,  1, 0, 0, "exmem_both_diff_regs_a");  // only rs1 matches
    endtask

    task automatic test_wb_forward_rs1();
        $display("--- WB forward rs1 ---");
        check(5'd6,  5'd2,  5'd9,  5'd6,  0, 0, 1, "wb_a_basic");
        check(5'd6,  5'd2,  5'd9,  5'd6,  1, 0, 1, "wb_a_mem_no_match");  // MEM doesn't match, WB wins
        check(5'd6,  5'd2,  5'd9,  5'd6,  1, 1, 1, "wb_a_mem_is_load");   // load in MEM, WB wins
    endtask

    task automatic test_wb_forward_rs2();
        $display("--- WB forward rs2 ---");
        check(5'd2,  5'd8,  5'd9,  5'd8,  0, 0, 1, "wb_b_basic");
        check(5'd2,  5'd8,  5'd9,  5'd8,  1, 0, 1, "wb_b_mem_no_match");
        check(5'd2,  5'd8,  5'd9,  5'd8,  1, 1, 1, "wb_b_mem_is_load");
    endtask

    task automatic test_wb_forward_both();
        $display("--- WB forward both ---");
        check(5'd7,  5'd7,  5'd9,  5'd7,  0, 0, 1, "wb_both_same_rd");
    endtask

    task automatic test_load_blocks_exmem();
        $display("--- load in MEM blocks 2b10 forward ---");
        // rs matches rd_mem but it's a load — must not forward 2'b10
        check(5'd4,  5'd3,  5'd4,  5'd9,  1, 1, 0, "load_blocks_a_no_wb");
        check(5'd3,  5'd4,  5'd4,  5'd9,  1, 1, 0, "load_blocks_b_no_wb");
        // load + WB fallback
        check(5'd4,  5'd3,  5'd4,  5'd4,  1, 1, 1, "load_blocks_a_wb_fallback");
        check(5'd3,  5'd4,  5'd4,  5'd4,  1, 1, 1, "load_blocks_b_wb_fallback");
    endtask

    task automatic test_exmem_priority_over_wb();
        $display("--- EX/MEM takes priority over WB when both match ---");
        check(5'd5,  5'd2,  5'd5,  5'd5,  1, 0, 1, "priority_a_exmem_wins");
        check(5'd2,  5'd5,  5'd5,  5'd5,  1, 0, 1, "priority_b_exmem_wins");
        check(5'd5,  5'd5,  5'd5,  5'd5,  1, 0, 1, "priority_both_exmem_wins");
    endtask

    task automatic test_mixed_forward();
        $display("--- mixed: rs1 from MEM, rs2 from WB ---");
        check(5'd3,  5'd7,  5'd3,  5'd7,  1, 0, 1, "mixed_a_mem_b_wb");
        $display("--- mixed: rs1 from WB, rs2 from MEM ---");
        check(5'd7,  5'd3,  5'd3,  5'd7,  1, 0, 1, "mixed_a_wb_b_mem");
    endtask

    task automatic test_random(input int iterations);
        logic [REG_WIDTH-1:0] r_rs1, r_rs2, r_rdm, r_rdw;
        logic r_rwm, r_load, r_rww;
        string lbl;

        $display("--- randomized (%0d iterations) ---", iterations);
        for (int i = 0; i < iterations; i++) begin
            r_rs1  = $urandom_range(0, 2**REG_WIDTH - 1);
            r_rs2  = $urandom_range(0, 2**REG_WIDTH - 1);
            r_rdm  = $urandom_range(0, 2**REG_WIDTH - 1);
            r_rdw  = $urandom_range(0, 2**REG_WIDTH - 1);
            r_rwm  = $urandom_range(0, 1);
            r_load = $urandom_range(0, 1);
            r_rww  = $urandom_range(0, 1);
            $sformat(lbl, "rand_%0d", i);
            check(r_rs1, r_rs2, r_rdm, r_rdw, r_rwm, r_load, r_rww, lbl);
        end
    endtask

    // -------------------------------------------------------------------------
    // Top-level stimulus
    // -------------------------------------------------------------------------
    initial begin
        pass_count = 0;
        fail_count = 0;

        ex_rs1 = '0; ex_rs2 = '0; rd_mem = '0; rd_wb = '0;
        reg_write_mem = 0; ex_mem_is_load = 0; reg_write_wb = 0;
        @(posedge clk);

        test_no_forward();
        test_exmem_forward_rs1();
        test_exmem_forward_rs2();
        test_exmem_forward_both();
        test_wb_forward_rs1();
        test_wb_forward_rs2();
        test_wb_forward_both();
        test_load_blocks_exmem();
        test_exmem_priority_over_wb();
        test_mixed_forward();
        test_random(2000);

        $display("\n=== Results: %0d passed, %0d failed ===", pass_count, fail_count);
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("FAILURES DETECTED");
        $finish;
    end

endmodule
