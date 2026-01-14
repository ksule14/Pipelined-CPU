`timescale 1ns / 1ps
import codes_pkg::WORD_WIDTH;
import codes_pkg::DEPTH;

class instr_trans;
    // Random inputs
    rand bit [WORD_WIDTH-1:0] addr;

    // Output
    bit [WORD_WIDTH-1:0] instruction;

    constraint addr_c {
        addr <= 36;
     addr % 4 ==0;}
endclass

class golden_model;

    localparam int BYTES = WORD_WIDTH/8;
    localparam int SHIFT = $clog2(BYTES);

    bit [WORD_WIDTH-1:0] instr_mem[0:DEPTH-1];

    function bit [WORD_WIDTH-1:0] instr(const ref instr_trans tx);
        return instr_mem[tx.addr[WORD_WIDTH-1:2]]; // word aligned
    endfunction

    task load_rom(string filename);
        $readmemh(filename, instr_mem);
    endtask
endclass

class scoreboard;
    function void compare(const ref instr_trans actual, const ref instr_trans expected);
        if (actual.instruction !== expected.instruction) begin
            $error("Mismatch at address %h: expected %h, got %h", actual.addr, expected.instruction, actual.instruction);
        end
        else $display("CORRECT: address %0d, instruction %h", actual.addr, actual.instruction); 
    endfunction
endclass

module instr_mem_tb;
    // Testbench signals
    instr_trans actual, expected;
    golden_model gm;
    scoreboard sb;

    bit [WORD_WIDTH-1:0] addr;
    bit [WORD_WIDTH-1:0] instruction;


    instruction_mem dut(
        .addr(addr),
        .instruction(instruction)
    );


    initial begin
        gm = new();
        sb = new();
        gm.load_rom("instr_mem.hex");

        repeat(100) begin
            actual = new();
            if(!actual.randomize()) $fatal("Randomization failed");
            expected = new();

            // Drive dut input and assign expected input
            addr = actual.addr;
            expected.addr = actual.addr;
        
            #1; // Let dut process address
            actual.instruction = instruction;
            expected.instruction = gm.instr(expected);
            sb.compare(actual, expected);
        end
        $display("Tests completed");
        $finish;
    end
endmodule



    

