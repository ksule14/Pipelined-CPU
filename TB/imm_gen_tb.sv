// DONE TESTING
`timescale 1ns/1ps

module imm_gen_tb;
    import codes_pkg::WORD_WIDTH;
    import codes_pkg::DATA_WIDTH;

    logic [WORD_WIDTH-1:0] instruction;
    logic [DATA_WIDTH-1:0] imm;
    logic                  error;

    imm_gen dut (
        .instruction(instruction),
        .imm(imm),
        .error(error)
    );

    initial begin
        load_addi_opcode();
        store_opcode();
        branch_opcode();
        rtype_opcode();
        unsupported_opcode();

        $display("All imm_gen test cases passed!");
        $finish;
    end

    task automatic load_addi_opcode(); // Test load/Addi immediates
        instruction = 32'b001010110001_00000_000_00000_0010011; // addi x0, x0, 1
        #1;
        assert(imm == {{DATA_WIDTH-12{1'b0}}, 12'b001010110001}) else $fatal("Failed I-type immediate generation, expected 32'b00000000000000000000001010110001, got %b", imm);
        assert(error == 1'b0) else $fatal("Unexpected error for valid I-type opcode, expected error=0, got %b", error);
    endtask

    task automatic store_opcode(); // Test store immediates
        instruction = 32'b1000000_00001_00000_010_00001_0100011; // sw x1, -2047(x0)
        #1;
        assert(imm == {{DATA_WIDTH-12{1'b1}}, 12'b100000000001}) else $fatal("Failed S-type immediate generation, expected 32'b11111111111111111111100000000001, got %b", imm);
        assert(error == 1'b0) else $fatal("Unexpected error for valid S-type opcode, expected error=0, got %b", error);
    endtask

    task automatic branch_opcode(); // Test branch immediates
        instruction = 32'b1000000_00000_00000_000_00001_1100011; // beq x0, x0, -2048
        #1;
        assert(imm == {{DATA_WIDTH-13{1'b1}}, 13'b1100000000000}) else $fatal("Failed B-type immediate generation, expected 32'b11111111111111111111111000000000, got %b", imm);
        assert(error == 1'b0) else $fatal("Unexpected error for valid B-type opcode, expected error=0, got %b", error);
    endtask

    task automatic rtype_opcode(); // Test R-type (no immediate)
        instruction = 32'b0000000_00000_00000_000_00000_0110011; // add x0, x0, x0
        #1;
        assert(imm == '0) else $fatal("Failed R-type immediate generation, expected 32'b00000000000000000000000000000000, got %b", imm);
        assert(error == 1'b0) else $fatal("Unexpected error for valid R-type opcode, expected error=0, got %b", error);
    endtask

    task automatic unsupported_opcode(); // Test unsupported opcode to esnure error is set
        instruction = 32'b0000000_00000_00000_000_00000_1111111; // Invalid opcode
        #1;
        assert(error == 1'b1) else $fatal("Failed to set error for unsupported opcode, expected error=1, got %b", error);
        assert(imm == 0) else $fatal("Unexpected immediate value for unsupported opcode, expected imm=0, got %b", imm);
    endtask
endmodule