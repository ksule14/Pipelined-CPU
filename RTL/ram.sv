import codes_pkg::DATA_WIDTH;
import codes_pkg::DEPTH;
import codes_pkg::WORD_WIDTH;

module ram (
    input logic clk,
    input logic [DATA_WIDTH-1:0] write_data,
   
    cache_ram.ram mem_bus
);

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    initial begin
        $readmemh("data_mem.hex", mem);
        mem_bus.mem_ready = 0;
        mem_bus.mem_write_done = 0;
    end

    always_ff @(posedge clk) begin
            if (mem_bus.mem_write_en) begin
                mem[mem_bus.mem_address>>2] <= write_data;
                mem_bus.mem_ready <= 0;
                mem_bus.mem_write_done <= 1;
            end
            else if (mem_bus.mem_read_en) begin
                    mem_bus.mem_read_data <= mem[mem_bus.mem_address>>2];
                    mem_bus.mem_ready <= 1;
                    mem_bus.mem_write_done <= 0;
                end
                else begin
                    mem_bus.mem_ready <=0;
                    mem_bus.mem_write_done <= 0;
                end
            end                    
endmodule


