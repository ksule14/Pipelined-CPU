`timescale 1ns / 1ps
import codes_pkg::WORD_WIDTH;

class pc_transaction;
    // Random inputs
    rand logic pc_src;
    rand logic [WORD_WIDTH-1:0] pc_branch;
         logic rst_n;
    
    constraint valid_branch {
        pc_branch % 2 == 0;
    }

    // Outputs
    logic [WORD_WIDTH-1:0] pc_current;
endclass

class golden_model;
    function logic [WORD_WIDTH-1:0] compute_pc(
      const ref pc_transaction tx
    );  
        if(!tx.rst_n) begin
            return WORD_WIDTH'd0;
        end else if (tx.pc_src) begin
            return tx.pc_branch;
        end else begin
            return tx.pc_current + WORD_WIDTH'd4;
        end   
    endfunction
endclass

class scoreboard;
    function void compare(
        const ref pc_transaction actual, const ref pc_transaction expected
    );
        assert(actual.pc_current == expected.pc_current)
            else $error("Mismatch: Actual PC = %0h, Expected PC = %0h, pc_src = %0d, pc_branch = %0d",
                         actual.pc_current, expected.pc_current, actual.pc_src, actual.pc_branch);
    endfunction
endclass

module pc_tb;
    pc_transaction actual_tx, expected_tx;
    golden_model gm;
    scoreboard sb;

    logic [WORD_WIDTH-1:0] pc_branch;
    logic pc_src;
    logic clk;
    logic rst_n;
    logic [WORD_WIDTH-1:0] pc_current;
    logic [WORD_WIDTH-1:0] prev_pc;

    pc dut (
        .clk(clk),
        .rst_n(rst_n),
        .pc_src(pc_src),
        .pc_branch(pc_branch),
        .pc_current(pc_current)
    );

    always #5 clk = ~clk;

    initial begin
        clk   = 0;
        rst_n = 0;
        #10;
        rst_n = 1;

        gm = new();
        sb = new();

        @(posedge clk);

        repeat (100) begin
            actual_tx = new();
            if(!actual_tx.randomize()) $fatal("Randomization failed");

            // Get previous value of pc drive DUT inputs
            prev_pc = pc_current;
            pc_src = actual_tx.pc_src;
            pc_branch = actual_tx.pc_branch;

            // Create expected object and assign common inputs
            expected_tx = new();
            expected_tx.pc_current = prev_pc;
            expected_tx.pc_src = actual_tx.pc_src;
            expected_tx.pc_branch = actual_tx.pc_branch;
            expected_tx.rst_n = rst_n;

            @(posedge clk);
            #1;
            // Get value of pc after the clock edge
            actual_tx.pc_current = pc_current;
            // Golden model predicts what will appear after clock edge
            expected_tx.pc_current = gm.compute_pc(expected_tx);

            sb.compare(actual_tx, expected_tx);
        end
        $display("Test completed");
        $finish;
    end
endmodule





              
