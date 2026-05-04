module sync_fifo #(
    paramter FIFO_WIDTH = 8,
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
    input logic [FIFO_WIDTH-1:0] fifo_data_out,
    output logic                 fifo_empty
);
    // FIFO array
    logic [FIFO_WIDTH-1:0] fifo [0:FIFO_DEPTH-1];

    logic [$clog2(FIFO_DEPTH)-1:0] wr_ptr;
    logic [$clog2(FIFO_DEPTH)-1:0] rd_ptr;
    logic [$clog2(DEPTH+1)-1:0] count;

    // status flags
    assign fifo_full = (count == FIFO_DEPTH); // full when count reaches full depth
    assign fifo_empty = (count == 0); // empty when count is at beginning

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count <= 0;
            fifo_data_out <= 0;
        end else begin
            // WRITE
            if (fifo_write_en && !fifo_full) begin
                fifo[wr_ptr] <= fifo_data_in;
                wr_ptr <= wr_ptr + 1;
            end

            // READ
            if (fifo_read_en && !fifo_empty) begin
                fifo_data_out <= fifo[rd_ptr];
                rd_ptr <= rd_ptr + 1;
            end

            // COUNT UPDATE
            case ({(fifo_write_en && !fifo_full),(fifo_read_en && !fifo_empty)})
                2'b10: count <= count + 1;
                2'b01: count <= count -1;
                default: count <= count;
            endcase
        end
    end
endmodule