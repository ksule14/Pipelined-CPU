import codes_pkg::WORD_WIDTH;
import codes_pkg::DATA_WIDTH;

module uart_ctrl #(
    parameter TX_WIDTH = 8, 
    parameter UART_ADDR = 32'd1024)(
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
            fifo_data_in <= write_data[TX_WIDTH-1:0]; // Only takes last 8 bits of data for UART
            fifo_write_en <= 1;
            end
        end
    end

    typedef enum logic [1:0] {IDLE, WAIT_DATA, WAIT_DONE, SEND} state_t; // FSM for reading from FIFO and sending to TX
    state_t state;

    // Read FIFO to send data from FIFO to UART TX
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fifo_read_en <= 0;
            tx_start <= 0;
            tx_data <= 0;
            state <= IDLE;
        end else begin
            fifo_read_en <= 0;
            tx_start <= 0;

            case (state)
                IDLE: begin
                    if (!fifo_empty && !tx_busy) begin
                        fifo_read_en <= 1;
                        state <= WAIT_DATA; // read enable is high for one cycle
                    end
                end
                WAIT_DATA: begin
                    tx_data  <= fifo_data_out; // latch data from FIFO to ensure stability
                    tx_start <= 1; // send start signal to TX to initiate data transfer
                    state <= WAIT_DONE;
                end
                WAIT_DONE: begin
                    if (tx_busy)
                        state <= SEND; // when TX acknowledges start signal by going busy, move to SEND state
                end
                SEND: begin
                    if (!tx_busy)
                        state <= IDLE; // once TX finishes sending return to IDLE
                end
            endcase
        end
    end
endmodule