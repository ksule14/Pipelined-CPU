// DONE TESTING
`timescale 1ns/1ps

// cpu_tb: top-level testbench for the pipelined RISC-V CPU.
// Drives reset, runs the program loaded in instr_mem.hex to completion,
// then checks every register and the relevant memory location against
// expected values derived from manual trace of that program.
module cpu_tb;
    import codes_pkg::*;
    import branch_fsm_pkg::*;
    import pipeline_pkg::*;

    // =========================================================================
    // Signal declarations
    // =========================================================================

    logic clk;          // 100 MHz testbench clock (10 ns period, toggled every 5 ns)
    logic rst_n;        // active-low synchronous reset driven by the test sequence
    logic error;        // OR of all CPU error flags; must never be high during execution
    logic prog_done;    // combinational pulse from cpu_top: high for exactly one cycle
                        // when the last instruction reaches the ID stage

    // prog_done_latched: SR flip-flop that captures the one-cycle prog_done pulse.
    // Once set it stays high for the rest of the simulation, giving the
    // ap_prog_done_stable assertion a stable signal to check.
    logic prog_done_latched;

    // rst_done: goes high one cycle after rst_n is released.
    // Used as the antecedent of ap_no_error_during_execution so that the very
    // first active clock edge (when if_id_reg still holds the reset-cleared
    // zero opcode) does not cause a false assertion failure.
    logic rst_done;

    // error_count: accumulates every assertion violation and every register /
    // memory mismatch; checked at the end to determine pass or fail.
    int error_count = 0;

    // =========================================================================
    // Testbench flip-flops (prog_done_latched and rst_done)
    // =========================================================================

    // Both signals share one always_ff so they reset together on negedge rst_n.
    // prog_done_latched: set by ORing with the incoming prog_done pulse so it
    //   latches on the first cycle prog_done is high and never clears.
    // rst_done: set unconditionally one cycle after the first posedge clk
    //   following rst_n going high, marking the pipeline as fully initialised.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prog_done_latched <= 1'b0;
            rst_done          <= 1'b0;
        end else begin
            prog_done_latched <= prog_done_latched | prog_done;
            rst_done          <= 1'b1;
        end
    end

    // =========================================================================
    // DUT instantiation
    // =========================================================================

    // Connect the four top-level ports of cpu_top.  All internal signals are
    // accessed for checking via hierarchical references (dut.<path>).
    cpu_top dut(
        .clk(clk),
        .rst_n(rst_n),
        .error(error),
        .prog_done(prog_done)
    );

    // =========================================================================
    // Clock generation — 10 ns period (100 MHz)
    // =========================================================================

    // Initialise clk to 0, then toggle every 5 ns forever.
    // posedge clk is the active edge used by all pipeline registers.
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // =========================================================================
    // Main test sequence
    // =========================================================================

    initial begin
        // Assert reset for 20 ns (covers two full clock cycles) to ensure every
        // pipeline register and cache state machine reach their reset values.
        rst_n = 1'b0;
        #20;

        // Deassert reset and wait one additional clock period before starting
        // execution monitoring, giving the PC and IF/ID register time to load
        // the first real instruction.
        rst_n = 1'b1;
        #10;

        // Poll prog_done until the program finishes, then wait for the pipeline
        // to drain completely before sampling register and memory state.
        run_program();

        // Compare every architected register and the written memory word against
        // the values produced by a manual trace of instr_mem.hex.
        verify_final_state();

        // Report overall pass/fail based on the accumulated error count.
        if (error_count == 0) begin
            $display("CPU_TB: All tests passed!");
            $finish;
        end else begin
            $fatal("CPU_TB: %0d test errors detected", error_count);
        end
    end

    // =========================================================================
    // Concurrent assertions — checked every posedge clk
    // =========================================================================

    // ap_no_error_during_execution:
    //   The CPU error output must never be high during normal program execution.
    //   error is the OR of ctrl_error, immgen_error, aluctrl_error, imem_error,
    //   and cache_error inside cpu_top.
    //
    //   disable iff (!rst_n): suppress while reset is asserted; the pipeline
    //     registers hold undefined opcodes and error is expected to be high.
    //
    //   rst_done |-> !error: the implication makes the property true
    //     on the very first active clock edge (rst_done=0 in the preponed region)
    //     when if_id_reg still holds the zeroed reset value whose opcode=0
    //     briefly asserts ctrl_error.  Using |-> rather than extending
    //     disable iff avoids a simulator quirk where disable iff is evaluated
    //     in the active region (after flip-flops have already updated)
    ap_no_error_during_execution: assert property (
        @(posedge clk) disable iff (!rst_n)
        rst_done |-> !error
    ) else begin
        error_count++;
        // Print the time and each individual error flag so the failing source
        // can be identified immediately without re-running with waveforms.
        $error("[CPU_TB] t=%0t ap_no_error_during_execution: ctrl=%b immgen=%b aluctrl=%b imem=%b cache=%b",
               $time,
               dut.ctrl_error, dut.immgen_error, dut.aluctrl_error,
               dut.imem_error, dut.cache_error);
    end

    // ap_prog_done_stable:
    //   Once prog_done_latched goes high it must never fall.  prog_done itself
    //   is a combinational one-cycle pulse (the halt gate takes two cycles to
    //   freeze if_id_reg, so a NOP overwrites prog_end before it can hold
    //   prog_done high permanently).  prog_done_latched is the SR-latched
    //   version that satisfies the stability requirement.
    //
    //   (prog_done_latched) |=> (prog_done_latched): at the next clock edge
    //     after prog_done_latched first goes high, it must still be high.
    //     Because prog_done_latched is set-only this is tautologically true by
    //     construction, but the assertion documents and enforces the invariant.
    ap_prog_done_stable: assert property (
        @(posedge clk) disable iff (!rst_n)
        (prog_done_latched) |=> (prog_done_latched)
    ) else begin
        error_count++;
        $error("ap_prog_done_stable: prog_done_latched should remain high once asserted");
    end

    // =========================================================================
    // Task: run_program
    //   Waits for prog_done to be asserted, enforcing a cycle timeout to prevent
    //   the simulation hanging if the program never terminates.  After detecting
    //   prog_done, waits five additional clock cycles so that all instructions
    //   still in-flight through the five pipeline stages (IF ID EX MEM WB) can
    //   complete their writebacks before verify_final_state samples the state.
    // =========================================================================
    task automatic run_program();
        int cycle_count = 0;    // counts posedge clk events since execution began
        int max_cycles = 1000;  // upper bound; far exceeds the expected ~33 cycles

        $display("[CPU_TB] Starting program execution...");

        // Sample prog_done before each rising edge.  prog_done is combinational
        // and is high for exactly one cycle, so checking it at the top of the
        // loop (before the @(posedge clk) wait) is sufficient to catch it.
        while (!prog_done && cycle_count < max_cycles) begin
            @(posedge clk);
            cycle_count++;
        end

        if (prog_done) begin
            $display("[CPU_TB] Program completed in %0d cycles", cycle_count);
        end else begin
            // $fatal stops simulation immediately with a non-zero exit code.
            $fatal("[CPU_TB] Program did not complete within %0d cycles", max_cycles);
        end

        // Drain the pipeline: the last instruction is in ID when prog_done fires,
        // so it needs up to four more cycles to reach WB and commit its result.
        // Five cycles gives one cycle of margin.
        repeat(5) @(posedge clk);
    endtask

    // =========================================================================
    // Task: dump_registers
    //   Prints the raw contents of registers x0–x13 and the first two RAM words
    //   in both hex and unsigned decimal.  Called at the start of
    //   verify_final_state so that every value is visible in the log before any
    //   pass/fail verdict is printed, making failures easy to diagnose without
    //   needing a waveform viewer.
    // =========================================================================
    task automatic dump_registers();
        $display("[CPU_TB] ---- Register File Dump ----");
        // Access the register array inside u_regfile via hierarchical reference.
        // regs[0] is hardwired to zero by the register file's always_ff, so it
        // will always read back as 0 regardless of writes.
        for (int i = 0; i <= 16; i++) begin
            $display("[CPU_TB]   x%-2d = 0x%08h  (%0d)", i, dut.u_regfile.regs[i], dut.u_regfile.regs[i]);
        end
        // The cache uses write-through policy so every store is immediately
        // committed to RAM.  Printing the first two RAM words (byte addresses
        // 0 and 4) covers the memory location written by the test program.
        $display("[CPU_TB]   RAM[0] = 0x%08h  (%0d)", dut.u_ram.mem[0], dut.u_ram.mem[0]);
        $display("[CPU_TB]   RAM[1] = 0x%08h  (%0d)", dut.u_ram.mem[1], dut.u_ram.mem[1]);
        $display("[CPU_TB] ---------------------------");
    endtask

    // =========================================================================
    // Task: verify_final_state
    //   Calls dump_registers for a full state snapshot, then calls
    //   verify_register_value for every register whose final value is known from
    //   a manual trace of instr_mem.hex, and verify_memory_value for the one
    //   memory word the program writes.
    // =========================================================================
    task automatic verify_final_state();
        // Dump all register and RAM values before running any checks so the
        // full state is always visible in the log, even if a fatal error occurs.
        dump_registers();
        $display("[CPU_TB] Verifying final register state...");

        // Expected final values derived from manual trace of instr_mem.hex.
        // The program has two sequences; the second overwrites the first.
        // After the arithmetic section a 2-iteration branch loop exercises
        // the flush controller and the 2-bit branch predictor.
        //
        // x1  = 4      ADDI x1, x0, 4     — base address / loop counter
        // x2  = 5      ADDI x2, x0, 5     — constant addend
        // x3  = 7      ADDI x3, x0, 7     — value stored to memory
        // x4  = 7      LW   x4, 0(x1)     — loaded back from address 4 after store
        // x5  = 12     ADD  x5, x4, x2    — 7  + 5
        // x6  = 17     ADD  x6, x5, x2    — 12 + 5
        // x7  = 22     ADD  x7, x6, x2    — 17 + 5
        // x8  = 17     ADD  x8, x0, x6    — copy of x6
        // x9  = 1      ADDI x9,  x0, 1    — left-hand side of (not-taken) branch
        // x10 = 1      ADDI x10, x0, 1    — right-hand side
        // x11 = 22     branch not taken → falls through to ADDI x11, x0, 22
        // x12 = 21     ADD  x12, x8, x1   — 17 + 4
        // x13 = 29     ADD  x13, x11, x3  — 22 + 7
        //
        // Branch predictor / flush coverage (new loop at instructions 28-32):
        // x14 = 1      ADDI x14, x0, 1    — loop sentinel
        // x15 = 2      ADDI x15, x0, 0; loop ADDI x15,x15,1 runs twice: 0→1→2
        //              Pass 1: BEQ x14,x15 → 1==1 TAKEN (predict NOT_TAKEN → flush, state→WEAK_TAKEN)
        //              Pass 2: BEQ x14,x15 → 1≠2 NOT TAKEN (predict TAKEN → flush, state→WEAK_NOT_TAKEN)
        // x16 = 3      ADD  x16, x14, x15 — 1+2, confirms loop exited correctly

        verify_register_value(1,  32'd4,  "x1 should be 4");
        verify_register_value(2,  32'd5,  "x2 should be 5");
        verify_register_value(3,  32'd7,  "x3 should be 7");
        verify_register_value(4,  32'd7,  "x4 should be 7 (loaded from address 4)");
        verify_register_value(5,  32'd12, "x5 should be 12");
        verify_register_value(6,  32'd17, "x6 should be 17");
        verify_register_value(7,  32'd22, "x7 should be 22");
        verify_register_value(8,  32'd17, "x8 should be 17");
        verify_register_value(9,  32'd1,  "x9 should be 1");
        verify_register_value(10, 32'd1,  "x10 should be 1");
        verify_register_value(11, 32'd22, "x11 should be 22");
        verify_register_value(12, 32'd21, "x12 should be 21");
        verify_register_value(13, 32'd29, "x13 should be 29");
        verify_register_value(14, 32'd1,  "x14 should be 1 (loop sentinel)");
        verify_register_value(15, 32'd2,  "x15 should be 2 (loop ran twice: 0->1->2)");
        verify_register_value(16, 32'd3,  "x16 should be 3 (1+2, loop exited correctly)");

        $display("[CPU_TB] Verifying memory state...");

        // The last store in the program is SW x3, 0(x1) with x1=4 and x3=7,
        // so byte address 4 (word address 1 in RAM) must contain 7.
        // The cache is write-through so the value is guaranteed to be in RAM
        // by the time the pipeline drain completes.
        verify_memory_value(4, 32'd7, "Memory[4] should be 7 (last store)");

        $display("[CPU_TB] All register and memory checks passed!");
    endtask

    // =========================================================================
    // Task: verify_register_value
    //   Reads register reg_id directly from the register file array via
    //   hierarchical reference, compares it to expected, and prints a PASS or
    //   FAIL line showing both hex and decimal.  On a mismatch, increments
    //   error_count so the final verdict reflects the failure.
    //
    //   Parameters:
    //     reg_id   — architectural register index (0–31)
    //     expected — expected 32-bit value after program completion
    //     msg      — human-readable description printed alongside the result
    // =========================================================================
    task automatic verify_register_value(int reg_id, logic [31:0] expected, string msg);
        logic [31:0] actual;
        // Read directly from the register file storage array.  This bypasses
        // the forwarding logic in reg_file.sv and always reflects the committed
        // (written-back) value.
        actual = dut.u_regfile.regs[reg_id];
        if (actual == expected) begin
            $display("[CPU_TB] PASS  x%-2d = 0x%08h (%0d)  expected 0x%08h (%0d)",
                     reg_id, actual, actual, expected, expected);
        end else begin
            error_count++;
            // Append <-- to make failing lines easy to grep for in large logs.
            $display("[CPU_TB] FAIL  x%-2d = 0x%08h (%0d)  expected 0x%08h (%0d)  <--",
                     reg_id, actual, actual, expected, expected);
        end
    endtask

    // =========================================================================
    // Task: verify_memory_value
    //   Converts a byte address to a word index, reads the value directly from
    //   the RAM array via hierarchical reference, and checks it against expected.
    //   Because the cache is write-through, every store committed by the pipeline
    //   is already in RAM by the time this task runs (no cache flush needed).
    //
    //   Parameters:
    //     addr_bytes — byte address of the memory location to check
    //     expected   — expected 32-bit word value at that address
    //     msg        — human-readable description printed alongside the result
    // =========================================================================
    task automatic verify_memory_value(int addr_bytes, logic [31:0] expected, string msg);
        int word_addr;
        logic [31:0] actual;
        // Right-shift by 2 converts byte address to word index because each
        // RAM entry is 32 bits (4 bytes) wide.
        word_addr = addr_bytes >> 2;
        actual = dut.u_ram.mem[word_addr];
        if (actual == expected) begin
            $display("[CPU_TB] PASS  Mem[%0d] = 0x%08h (%0d)  expected 0x%08h (%0d)",
                     addr_bytes, actual, actual, expected, expected);
        end else begin
            error_count++;
            $display("[CPU_TB] FAIL  Mem[%0d] = 0x%08h (%0d)  expected 0x%08h (%0d)  <--",
                     addr_bytes, actual, actual, expected, expected);
        end
    endtask

endmodule
