import codes_pkg::DATA_WIDTH;
import codes_pkg::DEPTH;
import codes_pkg::WORD_WIDTH;

module ram_tb;
   
    // Input signals
    logic clk;
    logic mem_read;
    logic mem_write;
    logic [DATA_WIDTH-1:0] addr;
    logic [DATA_WIDTH-1:0] write_data;

    // Output signals
    logic [DATA_WIDTH-1:0] read_data;

    data_mem dut(
        .clk(clk),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .addr(addr),
        .write_data(write_data),
        .read_data(read_data)
    );

    // ---------------------------
    // Testbench parameters
    // ---------------------------
    localparam int READ_LATENCY = 1; // sync read

    // ---------------------------
    // Golden model
    // ---------------------------
    logic [DATA_WIDTH-1:0] model_mem [0:DEPTH-1];

    // Clock
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset/init
    task automatic init_tb();
        mem_read   = 0;
        mem_write  = 0;
        addr       = '0;
        write_data = '0;
        for (int i = 0; i < DEPTH; i++) begin
            model_mem[i] = '0;
        end
        repeat (2) @(posedge clk);
    endtask

    // Write transaction
    task automatic do_write(input logic [DATA_WIDTH-1:0] a,
                            input logic [DATA_WIDTH-1:0] d);
        // drive on negedge to avoid race with posedge logic
        @(negedge clk);
        mem_write  = 1'b1;
        mem_read   = 1'b0;
        addr       = a;
        write_data = d;
        @(posedge clk);
        // update model on write edge
        model_mem[a] = d;
        @(negedge clk);
        mem_write  = 1'b0;
        write_data = '0;
    endtask

    // Read transaction + check
    task automatic do_read_check(input logic [DATA_WIDTH-1:0] a);
        logic [DATA_WIDTH-1:0] exp;
        exp = model_mem[a];

        // sync read: present address before posedge, sample after posedge update
        @(negedge clk);
        mem_read  = 1'b1;
        mem_write = 1'b0;
        addr      = a;
        @(posedge clk);
        #1;
        if (read_data !== exp) $error("READ MISMATCH (sync) addr=%0d exp=%h got=%h", a, exp, read_data);
        @(negedge clk);
        mem_read = 1'b0;
    endtask

    // Test sequence
    initial begin
        init_tb();

        // Directed tests
        do_write(0, 'hA5A5);
        do_read_check(0);

        do_write(DEPTH-1, 'h5A5A);
        do_read_check(DEPTH-1);

        // Random tests
        for (int t = 0; t < 50; t++) begin
            logic [DATA_WIDTH-1:0] a;
            logic [DATA_WIDTH-1:0] d;
            a = $urandom_range(0, DEPTH-1);
            d = $urandom();
            do_write(a, d);
            do_read_check(a);
        end

        $display("TB completed.");
        $finish;
    end

endmodule