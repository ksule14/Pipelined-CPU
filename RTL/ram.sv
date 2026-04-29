import codes_pkg::DATA_WIDTH;
import codes_pkg::DEPTH;
import codes_pkg::WORD_WIDTH;
// ram is main memory. Much larger than cache but slower to access
// Only accessed on cache miss
module ram (
    input logic clk, // clock
    input logic [DATA_WIDTH-1:0] write_data, // the data to be written
   
    cache_ram.ram mem_bus // interface communication with cache

    // No direct outputs because the only outputs the ram sends are to the cache through interface.
);

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1]; // memory array. Much larger than cache

    initial begin
        $readmemh("data_mem.hex", mem); // initialized with zeros in every slot from data_mem hex file
    end

    always_ff @(posedge clk) begin
            if (mem_bus.mem_write_en) begin // if ram write enable is high, write data to appropriate address in ram
                mem[mem_bus.mem_address>>2] <= write_data; // address must be word aligned
                mem_bus.mem_ready <= 0; // read signal is not used
                mem_bus.mem_write_done <= 1; // write_done signals writing is done and pipeline can resume
            end
            else if (mem_bus.mem_read_en) begin // if ram read enable is high,read data from appropriate address in ram
                    mem_bus.mem_read_data <= mem[mem_bus.mem_address>>2]; // address must be word aligned 
                    mem_bus.mem_ready <= 1; // data is ready to be copied into cache
                    mem_bus.mem_write_done <= 0; // write_done signal not used
                end
                else begin
                    mem_bus.mem_ready <=0; // default to 0
                    mem_bus.mem_write_done <= 0;
                end
            end                    
endmodule


