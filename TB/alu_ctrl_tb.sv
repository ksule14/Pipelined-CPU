// DONE TESTING
`timescale 1ns/1ps

module alu_ctrl_tb;
    import codes_pkg::*;

    logic [1:0] alu_op;
    logic       bit_30;
    logic [2:0] funct3;
    alu_control control;
    logic       error;

    alu_ctrl dut (
        .alu_op(alu_op),
        .bit_30(bit_30),
        .funct3(funct3),
        .control(control),
        .error(error)
    );

    initial begin
    // test load/store/addi
        alu_op_00();

    // test beq
        alu_op_01();

    // test r-type
        alu_op_10();

    // test invalid alu_op
        alu_op_invalid();

        $display("All tests passed!");
        $finish;
    end

    task automatic alu_op_00(); // load/store/addi
        alu_op = 2'b00;
        #1;
        assert(control == ADD) else $fatal("alu_op=00, control expected ADD, got %0d", control);
        assert(error == 1'b0) else $fatal("alu_op=00, error expected 0, got %b", error);
    endtask

    task automatic alu_op_01(); // beq
        alu_op = 2'b01;
        #1;
        assert(control == SUB) else $fatal("alu_op=01, control expected SUB, got %0d", control);
        assert(error == 1'b0) else $fatal("alu_op=01, error expected 0, got %b", error);
    endtask

    task automatic alu_op_10(); // r-type
        alu_op = 2'b10;

        bit_30 = 0;
        funct3 = 3'b000; // ADD
        #1;
        assert(control == ADD) else $fatal("alu_op=10, bit_30=0, funct3=000, control expected ADD, got %0d", control);
        assert(error == 1'b0) else $fatal("alu_op=10, bit_30=0, funct3=000, error expected 0, got %b", error);

        bit_30 = 1; 
        funct3 = 3'b000; // SUB
        #1;
        assert(control == SUB) else $fatal("alu_op=10, bit_30=1, funct3=000, control expected SUB, got %0d", control);
        assert(error == 1'b0) else $fatal("alu_op=10, bit_30=1, funct3=000, error expected 0, got %b", error);

        bit_30 = 0; 
        funct3 = 3'b111; // AND
        #1; 
        assert(control == AND) else $fatal("alu_op=10, bit_30=0, funct3=111, control expected AND, got %0d", control);
        assert(error == 1'b0) else $fatal("alu_op=10, bit_30=0, funct3=111, error expected 0, got %b", error);

        bit_30 = 0; 
        funct3 = 3'b110; // OR
        #1;
        assert(control == OR) else $fatal("alu_op=10, bit_30=0, funct3=110, control expected OR, got %0d", control);
        assert(error == 1'b0) else $fatal("alu_op=10, bit_30=0, funct3=110, error expected 0, got %b", error);

        bit_30 = 0; 
        funct3 = 3'b010; // SLT
        #1; 
        assert(control == SLT) else $fatal("alu_op=10, bit_30=0, funct3=010, control expected SLT, got %0d", control);
        assert(error == 1'b0) else $fatal("alu_op=10, bit_30=0, funct3=010, error expected 0, got %b", error);

        bit_30 = 0;
        funct3 = 3'b011; // SLTU
        #1;
        assert(control == SLTU) else $fatal("alu_op=10, bit_30=0, funct3=011, control expected SLTU, got %0d", control);
        assert(error == 1'b0) else $fatal("alu_op=10, bit_30=0, funct3=011, error expected 0, got %b", error);

        bit_30 = 1;
        funct3 = 3'b111; // invalid combination
        #1;
        assert(error == 1'b1) else $fatal("alu_op=10, bit_30=1, funct3=111, error expected 1, got %b", error);
    endtask

    task automatic alu_op_invalid(); // invalid alu_op
        alu_op = 2'b11;
        #1;
        assert(error == 1'b1) else $fatal("alu_op=11, error expected 1, got %b", error);
    endtask

endmodule