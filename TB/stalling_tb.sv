`timescale 1ns/1ps

module stalling_tb;
    parameter REG_WIDTH = 5;

    logic [REG_WIDTH-1:0] if_id_rs1;
    logic [REG_WIDTH-1:0] if_id_rs2;
    logic [REG_WIDTH-1:0] id_ex_rd;
    logic                 id_ex_mem_load;
    logic                 pc_redirect;
    logic                 mem_stall;
    logic                 uart_stall;

    logic pc_en;
    logic if_id_en;
    logic id_ex_en;
    logic id_ex_flush;
    logic ex_mem_en;
    logic mem_wb_en;
    logic stall;

    int pass_count, fail_count;

    stalling_u #(.REG_WIDTH(REG_WIDTH)) dut (
        .if_id_rs1(if_id_rs1),
        .if_id_rs2(if_id_rs2),
        .id_ex_mem_load(id_ex_mem_load),
        .id_ex_rd(id_ex_rd),
        .pc_redirect(pc_redirect),
        .mem_stall(mem_stall),
        .uart_stall(uart_stall),
        .pc_en(pc_en),
        .if_id_en(if_id_en),
        .id_ex_en(id_ex_en),
        .id_ex_flush(id_ex_flush),
        .ex_mem_en(ex_mem_en),
        .mem_wb_en(mem_wb_en),
        .stall(stall)
    );

    logic clk = 0;
    always #5 clk = ~clk; // 100MHz clock

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
        (id_ex_rd == '0) |-> (!stall || mem_stall || uart_stall))
        else $error("ap_no_x0_hazard: rd=x0 must never cause a load-use stall");

    // UART FIFO full: same full-pipeline freeze as cache-miss
    ap_uart_stall_id_ex_en: assert property (@(posedge clk)
        uart_stall |-> !id_ex_en)
        else $error("ap_uart_stall_id_ex_en: id_ex_en must be 0 during uart_stall");

    ap_uart_stall_ex_mem_en: assert property (@(posedge clk)
        uart_stall |-> !ex_mem_en)
        else $error("ap_uart_stall_ex_mem_en: ex_mem_en must be 0 during uart_stall");

    ap_uart_stall_mem_wb_en: assert property (@(posedge clk)
        uart_stall |-> !mem_wb_en)
        else $error("ap_uart_stall_mem_wb_en: mem_wb_en must be 0 during uart_stall");

    // -------------------------------------------------------------------------
    // Core checker task: drive inputs, compute expected, assert each output
    // -------------------------------------------------------------------------
    task automatic check(
        input logic [REG_WIDTH-1:0] rs1, rs2, rd,
        input logic                 mem_load, redirect, mem_stall_in,
        input string                label,
        input logic                 uart_stall_in = 1'b0
    );
        logic load_use;
        logic pipe_freeze;
        logic exp_stall, exp_pc_en, exp_if_id_en, exp_id_ex_en;
        logic exp_id_ex_flush, exp_ex_mem_en, exp_mem_wb_en;

        load_use        = mem_load && (rd != '0) && ((rd == rs1) || (rd == rs2));
        pipe_freeze     = mem_stall_in || uart_stall_in;
        exp_stall       = load_use || pipe_freeze;
        exp_pc_en       = redirect || ~exp_stall;
        exp_if_id_en    = ~exp_stall;
        exp_id_ex_en    = ~pipe_freeze;
        exp_id_ex_flush = load_use && !pipe_freeze;
        exp_ex_mem_en   = ~pipe_freeze;
        exp_mem_wb_en   = ~pipe_freeze;

        if_id_rs1      = rs1;
        if_id_rs2      = rs2;
        id_ex_rd       = rd;
        id_ex_mem_load = mem_load;
        pc_redirect    = redirect;
        mem_stall      = mem_stall_in;
        uart_stall     = uart_stall_in;
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


    // Scenario tasks

    task automatic test_no_hazard();
        $display("--- no hazard ---");
        check(5'd1,  5'd2,  5'd3,  0, 0, 0, "no_hazard_basic");
        check(5'd0,  5'd0,  5'd0,  1, 0, 0, "no_hazard_all_zero_regs");
        check(5'd31, 5'd30, 5'd29, 0, 0, 0, "no_hazard_high_regs");
        check(5'd1,  5'd2,  5'd0,  1, 0, 0, "no_hazard_rd_x0");       // rd=x0 must never hazard
        check(5'd1,  5'd2,  5'd3,  1, 0, 0, "no_hazard_no_reg_match");
    endtask

    task automatic test_load_use_rs1();
        $display("--- load-use rs1 ---");
        check(5'd5,  5'd2, 5'd5,  1, 0, 0, "load_use_rs1");
        check(5'd31, 5'd1, 5'd31, 1, 0, 0, "load_use_rs1_high");
    endtask

    task automatic test_load_use_rs2();
        $display("--- load-use rs2 ---");
        check(5'd2, 5'd7,  5'd7,  1, 0, 0, "load_use_rs2");
        check(5'd1, 5'd31, 5'd31, 1, 0, 0, "load_use_rs2_high");
    endtask

    task automatic test_load_use_both();
        $display("--- load-use rs1 and rs2 ---");
        check(5'd4, 5'd4, 5'd4, 1, 0, 0, "load_use_rs1_rs2_match");
    endtask

    // Cache miss: freeze entire pipeline; id_ex_flush must NOT fire from load_use alone
    task automatic test_mem_stall();
        $display("--- mem_stall ---");
        check(5'd1, 5'd2, 5'd3, 0, 0, 1, "mem_stall_only");
        check(5'd5, 5'd2, 5'd5, 1, 0, 1, "mem_stall_suppresses_load_use_flush");
    endtask

    // pc_redirect ORs into pc_en — must override stall suppression
    task automatic test_redirect_during_stall();
        $display("--- pc_redirect during stall ---");
        check(5'd5, 5'd2, 5'd5, 1, 1, 0, "redirect_overrides_load_use");
        check(5'd1, 5'd2, 5'd3, 0, 1, 1, "redirect_overrides_mem_stall");
    endtask

    // UART FIFO full: freezes entire pipeline, no flush; identical behaviour to mem_stall
    task automatic test_uart_stall();
        $display("--- uart_stall ---");
        // Basic FIFO-full freeze with no other hazards
        check(5'd1, 5'd2, 5'd3, 0, 0, 0, "uart_stall_only",                     1);
        // load-use flush must be suppressed when pipe_freeze is high
        check(5'd5, 5'd2, 5'd5, 1, 0, 0, "uart_stall_suppresses_load_use_flush", 1);
        // mem_stall and uart_stall both asserted simultaneously
        check(5'd1, 5'd2, 5'd3, 0, 0, 1, "mem_and_uart_stall",                   1);
        // pc_redirect must still override pc_en even during uart_stall
        check(5'd1, 5'd2, 5'd3, 0, 1, 0, "redirect_overrides_uart_stall",         1);
    endtask

    // Uniform random: full input space
    task automatic test_random(input int iterations);
        logic [REG_WIDTH-1:0] r_rs1, r_rs2, r_rd;
        logic r_mem_load, r_redirect, r_mem_stall, r_uart_stall;
        string lbl;

        $display("--- randomized (%0d iterations) ---", iterations);
        for (int i = 0; i < iterations; i++) begin
            r_rs1        = $urandom_range(0, 2**REG_WIDTH - 1);
            r_rs2        = $urandom_range(0, 2**REG_WIDTH - 1);
            r_rd         = $urandom_range(0, 2**REG_WIDTH - 1);
            r_mem_load   = $urandom_range(0, 1);
            r_redirect   = $urandom_range(0, 1);
            r_mem_stall  = $urandom_range(0, 1);
            r_uart_stall = $urandom_range(0, 1);
            $sformat(lbl, "rand_%0d", i);
            check(r_rs1, r_rs2, r_rd, r_mem_load, r_redirect, r_mem_stall, lbl, r_uart_stall);
        end
    endtask


    initial begin
        pass_count = 0;
        fail_count = 0;

        // Initialise to quiescent state before concurrent assertions start sampling
        if_id_rs1 = '0; if_id_rs2 = '0; id_ex_rd = '0;
        id_ex_mem_load = 0; pc_redirect = 0; mem_stall = 0; uart_stall = 0;
        @(posedge clk);

        test_no_hazard();
        test_load_use_rs1();
        test_load_use_rs2();
        test_load_use_both();
        test_mem_stall();
        test_redirect_during_stall();
        test_uart_stall();
        test_random(1000);

        $display("\n=== Results: %0d passed, %0d failed ===", pass_count, fail_count);
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("FAILURES DETECTED");
        $finish;
    end

endmodule
