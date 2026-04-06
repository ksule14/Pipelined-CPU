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

    end
endmodule

task automatic reset_dut();
    rst_n = 0;
    @(posedge clk);
    rst_n = 1;
endtask

