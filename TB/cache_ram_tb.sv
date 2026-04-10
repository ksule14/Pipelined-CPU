`timescale 1ns/1ps

module cache_ram_tb;
import codes_pkg::*;

    // clock and reset
    logic                  clk;
    logic                  rst_n;

    // cache inputs
    logic [WORD_WIDTH-1:0] addr;
    logic [DATA_WIDTH-1:0] write_data;
    logic                  read_en;
    logic                  write_en;

    // cache outputs
    logic [DATA_WIDTH-1:0] read_data;
    logic                  cache_stall;

    // memory interface signals
    cache_ram mem_bus();

    class write;
        rand logic [WORD_WIDTH-1:0] addr;
        rand logic [DATA_WIDTH-1:0] write_data;

        constraint addr_align {
            addr[1:0] == 2'b00;
            (addr >> 2) < DEPTH;
        }
    endclass

    // instantiate cache and ram
    cache dut_cache (
        .clk(clk),
        .rst_n(rst_n),
        .addr(addr),
        .write_data(write_data),
        .read_en(read_en),
        .write_en(write_en),
        .cache_stall(cache_stall),
        .read_data(read_data),
        .mem_bus(mem_bus.cache)
    );

    ram dut_ram (
        .clk(clk),
        .write_data(write_data),
        .mem_bus(mem_bus.ram)
    );

    // clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // test sequence
    initial begin
        // reset DUT
        reset_dut();
        // write through test
        write_through();

    $finish;
    end

task automatic reset_dut();
    rst_n = 0;
    #20;
    @(posedge clk);
    rst_n = 1;
endtask

task automatic write_through();
// instantiate class and randomize variables
    write w = new();
    assert(w.randomize()) else $fatal("Randomization failed");
    assert(w.addr < DEPTH) else $fatal ("Address out of range");
    addr = w.addr;
    write_data = w.write_data;
    write_en = 1;
    read_en = 0;
    @(posedge clk);
    write_en = 0;
    // verify data is written to cache and ram
    assert(dut_cache.cache_data[addr >> 2] == write_data) else $fatal("Cache write failed");
    assert(dut_ram.mem[addr >> 2] == write_data) else $fatal("RAM write failed");
endtask

task automatic read_miss();
    // create testbenche for read miss scenario
    // FINISH ME

endmodule