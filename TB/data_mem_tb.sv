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