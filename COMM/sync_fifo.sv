module sync_fifo #(
    parameter FIFO_WIDTH = 8,
    parameter FIFO_DEPTH = 8
)(
    input logic                  clk,
    input logic                  rst_n,
    // Write side
    input logic                  fifo_write_en,
    input logic [FIFO_WIDTH-1:0] fifo_data_in,
    output logic                 fifo_full,
    //READ side
    input logic                  fifo_read_en,
    output logic [FIFO_WIDTH-1:0] fifo_data_out,
    output logic                 fifo_empty
);
    // FIFO array
    logic [FIFO_WIDTH-1:0] fifo [0:FIFO_DEPTH-1];

    logic [$clog2(FIFO_DEPTH)-1:0] wr_ptr; // 3 bit pointers
    logic [$clog2(FIFO_DEPTH)-1:0] rd_ptr;
    logic [$clog2(FIFO_DEPTH+1)-1:0] count;

    // status flags
    assign fifo_full     = (count == FIFO_DEPTH); // fifo full when count is over 7 (limit)
    assign fifo_empty    = (count == 0);
    // combinational read: data is available the same cycle fifo_read_en is seen,
    // so uart_ctrl can latch it in WAIT_DATA without an extra pipeline bubble
    assign fifo_data_out = fifo[rd_ptr];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin // resets fifo to empty
            wr_ptr <= 0;
            rd_ptr <= 0;
            count  <= 0;
        end else begin
            // WRITE
            if (fifo_write_en && !fifo_full) begin // writes data and increments pointers
                fifo[wr_ptr] <= fifo_data_in;
                wr_ptr <= wr_ptr + 1;
            end

            // READ — only advance the pointer; data is read combinationally above
            if (fifo_read_en && !fifo_empty) begin
                rd_ptr <= rd_ptr + 1;
            end

            // COUNT UPDATE
            case ({(fifo_write_en && !fifo_full),(fifo_read_en && !fifo_empty)})
                2'b10: count <= count + 1; // increases when write enabled and not full
                2'b01: count <= count - 1; // decreases when read enabled and not empty
                default: count <= count;
            endcase
        end
    end
endmodule