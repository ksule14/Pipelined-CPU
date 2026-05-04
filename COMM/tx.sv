module tx #(parameter UART_WIDTH=8) (
    input logic                  clk,
    input logic                  rst_n,

    input logic [UART_WIDTH-1:0] tx_data,
    input logic                  tx_start,

    output logic                 tx,
    output logic                 tx_busy
);

    typedef enum logic [2:0] {
        IDLE, START, DATA, STOP
    } uart_state_t;

    uart_state_t uart;

    

    