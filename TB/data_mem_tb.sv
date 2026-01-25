import codes_pkg::DATA_WIDTH;
import codes_pkg::DEPTH;
import codes_pkg::WORD_WIDTH;

class data_trans;
    // Transaction inputs
    rand bit clk;
    rand bit mem_write;
    rand bit mem_read;
    rand bit [DATA_WIDTH-1:0] addr;
    rand bit [WORD_WIDTH-1:0] write_data;


    // Transaction outputs
    rand bit [WORD_WIDTH-1:0] read_data;

    // Transaction RAM block
    bit [DATA_WIDTH-1:0] ram [0:DEPTH-1];
    
endclass

class golden_model;

endclass


class scoreboard;

endclass


module ram_tb;
    // Testbench components
    data_trans trans;
    golden_model gm;
    scoreboard sb;

    // Input signals
    logic clk;
    logic mem_read;
    logic mem_write;
    logic [DATA_WIDTH-1:0] addr;
    logic [WORD_WIDTH-1:0] write_data;

    // Output signals
    logic [WORD_WIDTH-1:0] read_data;

    // Internal signals
    logic [DATA_WIDTH-1:0] data_mem [0:DEPTH-1];
    localparam ADDR_WIDTH = $clog2(DEPTH);
    logic [ADDR_WIDTH-1:0] word_addr;

    data_mem dut(
        .clk(clk),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .addr(addr),
        .write_data(write_data),
        .read_data(read_data)
    );

endmodule