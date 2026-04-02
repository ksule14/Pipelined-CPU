import codes_pkg::DATA_WIDTH;
import codes_pkg::DEPTH;
import codes_pkg::WORD_WIDTH;

module ram (
    input logic clk,
    input logic rst_n,
    input logic [DATA_WIDTH-1:0] write_data,
   
    cache_ram.ram mem_bus
);

    localparam READ_LATENCY = 2;

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    logic [1:0] counter;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            mem_bus.mem_ready <= 0;
            mem_bus.mem_read_data <= 0;
            for (int i=0; i<DEPTH; i++) begin
                mem[i] <= 0;
            end
        end
        else begin
            if (mem_bus.mem_write_en) begin
                mem[mem_bus.mem_address>>3] <= write_data;
                mem_bus.mem_ready <= 0;
                counter <= 0;
            end
            else if (mem_bus.mem_read_en) begin
                if (counter == READ_LATENCY) begin
                    mem_bus.mem_read_data <= mem[mem_bus.mem_address>>3];
                    mem_bus.mem_ready <= 1;
                    counter <=0;
                end
                else begin
                    counter <= counter + 1;
                    mem_bus.mem_ready <=0;
                end
            end
            else begin
                mem_bus.mem_ready <= 0;
                counter <= 0;
            end
        end
    end                      
endmodule


