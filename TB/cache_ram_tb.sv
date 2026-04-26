// DONE TESTING
`timescale 1ns/1ps

module cache_ram_tb;
import codes_pkg::*;

    localparam INDEX_BITS = 4;

    logic                  clk;
    logic                  rst_n;
    logic [WORD_WIDTH-1:0] addr;
    logic [DATA_WIDTH-1:0] write_data;
    logic                  read_en;
    logic                  write_en;
    logic [DATA_WIDTH-1:0] read_data;
    logic                  cache_stall;
    logic                  error;

    cache_ram mem_bus();

    class cache_stimulus;
        rand logic [WORD_WIDTH-1:0] addr;
        rand logic [DATA_WIDTH-1:0] data;
        constraint addr_align {
            addr[1:0] == 2'b00;
            (addr >> 2) < DEPTH;
        }
    endclass

    cache #(.INDEX_BITS(INDEX_BITS)) dut_cache (
        .clk(clk), .rst_n(rst_n),
        .addr(addr), .write_data(write_data),
        .read_en(read_en), .write_en(write_en),
        .cache_stall(cache_stall), .read_data(read_data),
        .error(error),
        .mem_bus(mem_bus.cache)
    );

    ram dut_ram (
        .clk(clk), .write_data(write_data),
        .mem_bus(mem_bus.ram)
    );

    initial begin clk = 0; forever #5 clk = ~clk; end

    // ----------------------------------------------------------------
    // Test sequence
    // ----------------------------------------------------------------
    initial begin
        reset_dut();
        test_write_through();
        test_read_hit();
        reset_dut();
        test_read_miss();
        reset_dut();
        test_cache_eviction();
        test_unaligned_error();
        $display("ALL TESTS PASSED!.");
        $finish;
    end

    // ----------------------------------------------------------------
    // Helpers
    // ----------------------------------------------------------------
    task automatic wait_for_ready();
        while (cache_stall) @(posedge clk);
    endtask

    task automatic reset_dut();
        rst_n      = 0;
        read_en    = 0;
        write_en   = 0;
        addr       = '0;
        write_data = '0;
        repeat(3) @(posedge clk);
        rst_n = 1;
        @(posedge clk);
    endtask

    // ----------------------------------------------------------------
    // Test: write-through
    //   A write goes to cache and RAM simultaneously.
    //   Checks both internal arrays contain the written data.
    // ----------------------------------------------------------------
    task automatic test_write_through();
        cache_stimulus s = new();
        assert(s.randomize()) else $fatal("Randomization failed");

        addr       = s.addr;
        write_data = s.data;
        write_en   = 1;
        read_en    = 0;
        @(posedge clk);  // cache and RAM latch simultaneously
        #1;              // allow NBA updates to settle before sampling
        write_en = 0;

        assert(dut_cache.cache_data[s.addr[INDEX_BITS+1:2]] == s.data)
            else $fatal("Write-through: cache mismatch  addr=%0h expected=%0h",
                        s.addr, s.data);
        assert(dut_ram.mem[s.addr >> 2] == s.data)
            else $fatal("Write-through: RAM mismatch  addr=%0h expected=%0h",
                        s.addr, s.data);

        // verify no spurious read-miss stall was raised
        assert(!mem_bus.mem_read_en)
            else $fatal("Write-through: mem_read_en should be low during write");

        $display("PASS  write_through  addr=%0h  data=%0h", s.addr, s.data);
    endtask

    // ----------------------------------------------------------------
    // Test: read hit
    //   After writing a word, reading the same address must hit with
    //   no stall and return the correct data.
    // ----------------------------------------------------------------
    task automatic test_read_hit();
        cache_stimulus s = new();
        assert(s.randomize()) else $fatal("Randomization failed");

        // populate cache line
        addr = s.addr; write_data = s.data; write_en = 1; read_en = 0;
        @(posedge clk);
        write_en = 0;

        // read same address — combinational hit, no stall
        read_en = 1;
        @(negedge clk);  // sample combinational outputs at stable point
        assert(!cache_stall)
            else $fatal("Read-hit: unexpected stall  addr=%0h", s.addr);
        assert(read_data == s.data)
            else $fatal("Read-hit: data mismatch  expected=%0h  got=%0h",
                        s.data, read_data);

        @(posedge clk);
        read_en = 0;
        $display("PASS  read_hit  addr=%0h  data=%0h", s.addr, s.data);
    endtask

    // ----------------------------------------------------------------
    // Test: read miss + cache-RAM transaction
    //   Write a known word (populates RAM), then reset to clear cache
    //   valid bits, then read — must stall while RAM fetch completes,
    //   then return the correct data.
    //   This exercises the full cache-RAM handshake:
    //     IDLE→FETCH_MEMORY, mem_read_en asserted, RAM drives
    //     mem_read_data + mem_ready, cache captures and returns to IDLE.
    // ----------------------------------------------------------------
    task automatic test_read_miss();
        cache_stimulus s = new();
        logic [DATA_WIDTH-1:0] expected;
        assert(s.randomize()) else $fatal("Randomization failed");

        // write known data — lands in both cache and RAM
        addr = s.addr; write_data = s.data; write_en = 1; read_en = 0;
        @(posedge clk);
        write_en = 0;
        expected = s.data;

        // reset clears cache valid bits; RAM retains its data
        reset_dut();

        // --- initiate read (cold miss expected) ---
        addr     = s.addr;
        read_en  = 1;
        write_en = 0;
        @(negedge clk);
        assert(cache_stall)
            else $fatal("Read-miss: stall not asserted on cold miss  addr=%0h", s.addr);
        assert(!mem_bus.mem_write_en)
            else $fatal("Read-miss: mem_write_en must be low during read");

        // --- wait one more posedge; FETCH_MEMORY entered, mem_read_en rises ---
        @(posedge clk);  // state → FETCH_MEMORY
        @(negedge clk);
        assert(mem_bus.mem_read_en)
            else $fatal("Read-miss: mem_read_en not asserted in FETCH_MEMORY");

        // --- wait for RAM to respond and cache to capture ---
        wait_for_ready();
        @(negedge clk);

        assert(!cache_stall)
            else $fatal("Read-miss: stall persists after fetch  addr=%0h", s.addr);
        assert(!mem_bus.mem_read_en)
            else $fatal("Read-miss: mem_read_en should deassert after fetch");
        assert(read_data == expected)
            else $fatal("Read-miss: data mismatch after fetch  expected=%0h  got=%0h",
                        expected, read_data);

        // --- verify the fetched line now hits on a second read ---
        @(posedge clk);
        @(negedge clk);
        assert(!cache_stall)
            else $fatal("Read-miss: second read should be a hit");
        assert(read_data == expected)
            else $fatal("Read-miss: second read data mismatch");

        @(posedge clk);
        read_en = 0;
        $display("PASS  read_miss  addr=%0h  data=%0h", s.addr, s.data);
    endtask

    // ----------------------------------------------------------------
    // Test: cache eviction (direct-mapped conflict miss)
    //   Two addresses map to the same cache index but carry different
    //   tags.  Writing the second address evicts the first; a
    //   subsequent read of the first must miss and re-fetch from RAM.
    // ----------------------------------------------------------------
    task automatic test_cache_eviction();
        // addr[INDEX_BITS+1:2] = index, addr[WORD_WIDTH-1:INDEX_BITS+2] = tag
        // Choose index=5: addr_a tag=1, addr_b tag=2
        logic [WORD_WIDTH-1:0] addr_a, addr_b;
        logic [DATA_WIDTH-1:0] data_a, data_b;

        addr_a = (32'd1 << (INDEX_BITS + 2)) | (32'd5 << 2);  // 0x44
        addr_b = (32'd2 << (INDEX_BITS + 2)) | (32'd5 << 2);  // 0x54 — same index, different tag
        data_a = 32'hDEAD_BEEF;
        data_b = 32'hCAFE_F00D;

        // write addr_a
        addr = addr_a; write_data = data_a; write_en = 1; read_en = 0;
        @(posedge clk); write_en = 0;

        // write addr_b (same index → overwrites addr_a's cache line)
        addr = addr_b; write_data = data_b; write_en = 1; read_en = 0;
        @(posedge clk); write_en = 0;

        // addr_b should hit immediately (just written)
        addr = addr_b; read_en = 1; write_en = 0;
        @(negedge clk);
        assert(!cache_stall)
            else $fatal("Eviction: addr_b should hit after write");
        assert(read_data == data_b)
            else $fatal("Eviction: addr_b mismatch  expected=%0h  got=%0h",
                        data_b, read_data);
        @(posedge clk); read_en = 0;

        // addr_a was evicted — must miss and re-fetch from RAM
        addr = addr_a; read_en = 1; write_en = 0;
        @(negedge clk);
        assert(cache_stall)
            else $fatal("Eviction: addr_a should miss after eviction");
        wait_for_ready();
        @(negedge clk);
        assert(!cache_stall)
            else $fatal("Eviction: stall persists after addr_a refetch");
        assert(read_data == data_a)
            else $fatal("Eviction: addr_a mismatch after refetch  expected=%0h  got=%0h",
                        data_a, read_data);

        @(posedge clk); read_en = 0;
        $display("PASS  cache_eviction");
    endtask

    // ----------------------------------------------------------------
    // Test: unaligned address error flag
    //   error is combinational: (read_en||write_en) && addr[1:0]!=0
    // ----------------------------------------------------------------
    task automatic test_unaligned_error();
        // byte-unaligned read
        addr = 32'h0000_0001; read_en = 1; write_en = 0;
        @(negedge clk);
        assert(error)
            else $fatal("Unaligned: error not set for read addr=0x1");

        // half-word-unaligned write
        addr = 32'h0000_0002; write_en = 1; read_en = 0; write_data = 32'hFF;
        @(negedge clk);
        assert(error)
            else $fatal("Unaligned: error not set for write addr=0x2");

        // aligned access must not raise error
        addr = 32'h0000_0004; read_en = 1; write_en = 0;
        @(negedge clk);
        assert(!error)
            else $fatal("Unaligned: error spuriously set for aligned addr=0x4");

        @(posedge clk);
        read_en = 0; write_en = 0; addr = '0;
        $display("PASS  unaligned_access_error");
    endtask

endmodule
