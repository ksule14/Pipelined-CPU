import codes_pkg::DATA_WIDTH;

// write back module determines whether data written to registers is from alu result or memory
module write_back (
    input  logic                  mem_to_reg, // control signal that determines reg_write source
    input  logic [DATA_WIDTH-1:0] alu_data, // result calculated by alu
    input  logic [DATA_WIDTH-1:0] mem_data, // data from memory (cache or ram)
    output logic [DATA_WIDTH-1:0] wb_data // the data that is selected to be written to reg file
);
    assign wb_data = mem_to_reg ? mem_data : alu_data; // if mem_to_reg is high, mem_data written. If mem_to_reg is low, alu_data written
    // Note that WB does not have an enable, so something is always sent to reg_file, but reg_write enable prevents unwanted writes
endmodule
