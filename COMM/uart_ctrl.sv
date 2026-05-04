import codes_pkg::WORD_WIDTH;
import codes_pkg::DATA_WIDTH;

module uart_ctrl #(
    parameter TX_WIDTH = 8, 
    parameter UART_ADDR = 32'h1000_000)(
    input logic                  clk,
    input logic                  rst_n,
    // CPU interface
    input logic [WORD_WIDTH-1:0] mem_addr,
    input logic [DATA_WIDTH-1:0] write_data,
    input logic                  mem_write,
    //FIFO interface- Writing to FIFO
    input logic                  fifo_full,
    output logic                 fifo_write_en,
    output logic [TX_WIDTH-1:0]  fifo_data_in,
    // FIFO interface- Reading from FIFO
    input logic [TX_WIDTH-1:0]   fifo_data_out,
    output logic                 fifo_read_en,
    input logic                  fifo_empty,

    // UART TX interface
    output logic [TX_WIDTH-1:0]  tx_data,
    output logic                 tx_start,
    input logic                  tx_busy   
);

    // Write FIFO with data from CPU on SW to UART address
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fifo_write_en <= 0;
            fifo_data_in <= 0;
        end else begin
            fifo_write_en <= 0; // default

            if (mem_write && mem_addr == UART_ADDR && !fifo_full) begin
            fifo_data_in <= write_data[TX_WIDTH-1:0];
            fifo_write_en <= 1;
            end
        end
    end

    // Read FIFO to send data from FIFO to UART TX
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fifo_read_en <= 0;
            tx_start <= 0;
            tx_data <= 0;
        end else begin
            fifo_read_en <= 0; // default
            tx_start <= 0;

            if (!fifo_empty && !tx_busy) begin
                fifo_read_en <= 1;
                tx_data <= fifo_dout;
                tx_start <= 1; // one cycle pulse
            end
        end
    end
endmodule