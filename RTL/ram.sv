import codes_pkg::DATA_WIDTH;
import codes_pkg::DEPTH;
import codes_pkg::WORD_WIDTH;

module ram (
    input logic clk,
    input logic rst_n,
    input logic [DATA_WIDTH-1:0] write_data,
    input logic [WORD_WIDTH-1:0] addr,
    input logic write_en,
    input logic read_en,
    output logic [DATA_WIDTH-1:0] read_data,
    output logic mem_ready
);

    localparam READ_LATENCY = 2;

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    logic [1:0] counter;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            mem_ready <= 0;
            read_data <= 0;
        end
        else begin
            if (write_en) begin
                mem[addr>>3] <= write_data;
                mem_ready <= 0;
                counter <= 0;
            end
            else if (read_en) begin
                if (counter == READ_LATENCY) begin
                    read_data <= mem[addr>>3];
                    mem_ready <= 1;
                    counter <=0;
                end
                else begin
                    counter <= counter + 1;
                    mem_ready <=0;
                end
            end
            else begin
                mem_ready <= 0;
                counter <= 0;
            end
        end
    end                      
endmodule


