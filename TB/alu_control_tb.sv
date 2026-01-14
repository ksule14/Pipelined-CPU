`timescale 1ns / 1ps

import codes_pkg::*;

module alu_control_tb;

    // Testbench signals
    logic [1:0] alu_op;
    logic       bit_30;
    logic [2:0] funct3;
    alu_control control;

    // Instantiate the ALU Control module
    alu_ctrl dut (
        .alu_op(alu_op),
        .bit_30(bit_30),
        .funct3(funct3),
        .control(control)
    );

    // Test procedure
    initial begin
        // Test case 1: Load/Store/Add immediate (alu_op = 00)
        alu_op = 2'b00; bit_30 = 1'b0; funct3 = 3'b000;
        #0;
        assert(control == ADD) else $error("Test case 1 failed");

        // Test case 2: BEQ (alu_op = 01)
        alu_op = 2'b01; bit_30 = 1'b0; funct3 = 3'b000;
        #0;
        assert(control == SUB) else $error("Test case 2 failed");

        // Test case 3: R-type ADD (alu_op = 10, bit_30 = 0, funct3 = 000)
        alu_op = 2'b10; bit_30 = 1'b0; funct3 = 3'b000;
        #0;
        assert(control == ADD) else $error("Test case 3 failed");

        // Test case 4: R-type SUB (alu_op = 10, bit_30 = 1, funct3 = 000)
        alu_op = 2'b10; bit_30 = 1'b1; funct3 = 3'b000;
        #0;
        assert(control == SUB) else $error("Test case 4 failed");

        // Test case 5: R-type AND (alu_op = 10, bit_30 = 0, funct3 = 111)
        alu_op = 2'b10; bit_30 = 1'b0; funct3 = 3'b111;
        #0;
        assert(control == AND) else $error("Test case 5 failed");

        // Test case 6: R-type OR (alu_op = 10, bit_30 = 0, funct3 = 110)
        alu_op = 2'b10; bit_30 = 1'b0, funct3 = 3'b110;
        #0;
        assert(control == OR) else $error("Test case 6 failed");

        // Test case 7: R-type SLT (alu_op = 10, bit_30 = 0, funct3 = 010)
        alu_op = 2'b10; bit_30 = 1'b0; funct3 = 3'b010;
        #0;
        assert(control == SLT) else $error("Test case 7 failed");

        // Test case 8: R-type SLTU (alu_op = 10, bit_30 = 0, funct3 = 011)
        alu_op = 2'b10; bit_30 = 1'b0; funct3 = 3'b011;
        #0;
        assert(control == SLTU) else $error("Test case 8 failed");

        $display("All test cases completed.");
        $finish;
    end
endmodule


                                                         

