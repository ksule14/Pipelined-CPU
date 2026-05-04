module tx #(
    parameter TX_WIDTH=8,
    parameter CLKS_PER_BIT = 868) // 100MHz / 115200 baud 
    (
    input logic                  clk,
    input logic                  rst_n,

    input logic [TX_WIDTH-1:0]   tx_data,
    input logic                  tx_start,

    output logic                 tx_busy,
    output logic                 tx_serial // output pin
);

    typedef enum logic [2:0] {
        IDLE, TX_START, TX_DATA, TX_STOP, CLEANUP
    } state_t;

    state_t state;

    // internal counters and registers
    logic [15:0] clk_count; // tracks time for one baud bit
    logic [2:0] bit_index; // tracks which bit is being sent
    logic [TX_WIDTH-1:0] data_reg; // latched data to ensure stability during TX

    assign tx_busy = (state != IDLE);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            tx_serial <= 1; // high one IDLE
            clk_count <= 0;
            bit_index <= 0;
            data_reg <= 0;
        end else begin
            case(state)
            IDLE: begin
                tx_serial <= 1;
                clk_count <= 0;
                bit_index <= 0;

                if (tx_start) begin
                    data_reg <= tx_data;
                    state <= TX_START;
                end
            end
            // send start bit 0
            TX_START: begin
                tx_serial <= 0;
                if (clk_count < CLKS_PER_BIT-1) begin
                    clk_count <= clk_count + 1;
                end else begin
                    clk_count <= 0;
                    state <= TX_DATA;
                end
            end
            // Send 8 bits (LSB first)
            TX_DATA: begin
                tx_serial <= data_reg[bit_index];

                if (clk_count < CLKS_PER_BIT-1) begin
                    clk_count <= clk_count + 1;
                end else begin
                    clk_count <= 0;
                    if (bit_index < (TX_WIDTH-1)) begin
                        bit_index <= bit_index + 1;
                    end else begin
                        bit_index <= 0;
                        state <= TX_STOP;
                    end

                end
            end
            // send stop bit 1
            TX_STOP: begin
                tx_serial <= 1;
                if (clk_count < CLKS_PER_BIT-1) begin
                    clk_count <= clk_count + 1;
                end else begin
                    clk_count <= 0;
                    state <= CLEANUP;
                end
            end
            // One cycle delay for stability
            CLEANUP:begin
                state <= IDLE;
            end

            default: state <= IDLE;
            endcase
        end
    end
endmodule
