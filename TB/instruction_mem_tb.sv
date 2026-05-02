// DONE TESTING
`timescale 1ns/1ps

module instr_mem_tb;
    import codes_pkg::WORD_WIDTH;

    logic [WORD_WIDTH-1:0] addr;
    logic [WORD_WIDTH-1:0] instruction;
    logic                  done;
    logic                  error;

    instruction_mem #(
        .PROGRAM_LENGTH(4)
    ) dut (
        .addr(addr),
        .instruction(instruction),
        .done(done),
        .error(error)
    );

    initial begin
        test_instr();
        $display("instr_mem_tb: all checks passed");
        $finish;
    end
    task automatic test_instr();
    addr = 0;
    #1;
    assert(instruction == 32'h00A00393) else $fatal("Instruction mismatch at addr 0: expected 00A00393, got %0h", instruction);
    addr = 4;
    #1;
    assert(instruction == 32'h00C00313) else $fatal("Instruction mismatch at addr 4: expected 00C00313, got %0h", instruction);
    addr = 8;
    #1;
    assert(instruction == 32'h00730433) else $fatal("Instruction mismatch at addr 8: expected 00730433, got %0h", instruction);
    addr = 20;
    #1;
    assert(instruction == 32'h00428103) else $fatal("Instruction mismatch at addr 20: expected 00428103, got %0h", instruction);
    addr = 12;
    #1;
    assert(done == 1'b1) else $fatal("Expected done at last program instruction, got %b", done);
    addr = 16;
    #1;
    assert(done == 1'b0) else $fatal("Expected done to be low before or after boundary, got %b", done);
    addr = 3;
    #1;
    assert(error == 1'b1) else $fatal("Expected error for unaligned address, got %b", error);
    endtask
endmodule
        
