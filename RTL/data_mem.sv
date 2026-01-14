import codes_pkg::DATA_WIDTH;
import codes_pkg::DEPTH;
import codes_pkg::WORD_WIDTH;

module data_mem (
    input logic clk,
    input logic mem_read,
    input logic mem_write,
    input logic [DATA_WIDTH-1:0] addr,
    input logic [DATA_WIDTH-1:0] write_data,
    output logic [DATA_WIDTH-1:0] read_data
);
    logic [DATA_WIDTH-1:0] data_mem [0:DEPTH-1]; //8 bits for 256 words
    localparam ADDR_WIDTH = $clog2(DEPTH);
    logic [ADDR_WIDTH-1:0] word_addr;
    assign word_addr = addr[ADDR_WIDTH-1:0];

    always_ff @(posedge clk) begin
        if (mem_write) begin
            data_mem[word_addr] <= write_data;
        end
        if (mem_read) begin
            read_data <= data_mem[word_addr];
        end else begin
            read_data <= '0;
        end
    end
endmodule


