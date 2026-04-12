`timescale 1ns/1ps

module main_ctrl_tb;
    logic [6:0] opcode;
    logic [1:0] alu_op;
    logic       branch;
    logic       mem_read;
    logic       mem_write;
    logic       mem_to_reg;
    logic       alu_src;
    logic       reg_write;
    logic       error;

    main_control dut (
        .opcode(opcode),
        .alu_op(alu_op),
        .branch(branch),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_to_reg(mem_to_reg),
        .alu_src(alu_src),
        .reg_write(reg_write),
        .error(error)
    );

    initial begin
        // Test R-type opcode
        r_type_opcode();

        // Test I-type opcode
        i_type_opcode();

        // Test Laod opcode
        load_opcode();

        // Test store opcode
        store_opcode();

        // Test BEQ opcode
        beq_opcode();

        // Test unsupported opcodes
        unsupported_opcode();

        $display("All tests passed!");
        $finish;
    end

    task automatic r_type_opcode();
        opcode = 7'b0110011; // R-type
        #1;
        assert(alu_op == 2'b10) else $fatal("R-type: alu_op should be 10, got %b", alu_op);
        assert(reg_write == 1'b1) else $fatal("R-type: reg_write should be 1, got %b", reg_write);
        assert(branch == 1'b0) else $fatal("R-type: branch should be 0, got %0b", branch);
        assert(mem_read == 1'b0) else $fatal("R-type: mem_read should be 0, got %b", mem_read);
        assert(mem_write == 1'b0) else $fatal("R-type: mem_write should be 0, got %b", mem_write);
        assert(mem_to_reg == 1'b0) else $fatal("R-type: mem_to_reg should be 0, got %b", mem_to_reg);
        assert(alu_src == 1'b0) else $fatal("R-type: alu_src should be 0, got %b", alu_src);
        assert(error == 1'b0) else $fatal("R-type: error should be 0, got %b", error);
    endtask

    task automatic i_type_opcode();
        opcode = 7'b0010011; // I-type
        #1;
        assert(alu_op == 2'b00) else $fatal("I-type: alu_op should be 00, got %b", alu_op);
        assert(alu_src == 1'b1) else $fatal("I-type: alu_src should be 1, got %b", alu_src);
        assert(reg_write == 1'b1) else $fatal("I-type: reg_write should be 1, got %b", reg_write);
        assert(branch == 1'b0) else $fatal("I-type: branch should be 0, got %0b", branch);
        assert(mem_read == 1'b0) else $fatal("I-type: mem_read should be 0, got %b", mem_read);
        assert(mem_write == 1'b0) else $fatal("I-type: mem_write should be 0, got %b", mem_write);
        assert(mem_to_reg == 1'b0) else $fatal("I-type: mem_to_reg should be 0, got %b", mem_to_reg);
        assert(error == 1'b0) else $fatal("I-type: error should be 0, got %b", error);
    endtask

    task automatic load_opcode();
        opcode = 7'b0000011; // Load
        #1;
        assert(alu_op == 2'b00) else $fatal("Load: alu_op should be 00, got %b", alu_op);
        assert(mem_read == 1'b1) else $fatal("Load: mem_read should be 1, got %b", mem_read);
        assert(mem_to_reg == 1'b1) else $fatal("Load: mem_to_reg should be 1, got %b", mem_to_reg);
        assert(alu_src == 1'b1) else $fatal("Load: alu_src should be 1, got %b", alu_src);
        assert(reg_write == 1'b1) else $fatal("Load: reg_write should be 1, got %b", reg_write);
        assert(branch == 1'b0) else $fatal("Load: branch should be 0, got %0b", branch);
        assert(mem_write == 1'b0) else $fatal("Load: mem_write should be 0, got %b", mem_write);
        assert(error == 1'b0) else $fatal("Load: error should be 0, got %b", error);
    endtask

    task automatic store_opcode();
        opcode = 7'b0100011; // Store
        #1;
        assert(alu_op == 2'b00) else $fatal("Store: alu_op should be 00, got %b", alu_op);
        assert(mem_write == 1'b1) else $fatal("Store: mem_write should be 1, got %b", mem_write);
        assert(alu_src == 1'b1) else $fatal("Store: alu_src should be 1, got %b", alu_src);
        assert(branch == 1'b0) else $fatal("Store: branch should be 0, got %0b", branch);
        assert(mem_read == 1'b0) else $fatal("Store: mem_read should be 0, got %b", mem_read);
        assert(mem_to_reg == 1'b0) else $fatal("Store: mem_to_reg should be 0, got %b", mem_to_reg);
        assert(reg_write == 1'b0) else $fatal("Store: reg_write should be 0, got %b", reg_write);
        assert(error == 1'b0) else $fatal("Store: error should be 0, got %b", error);
    endtask

    task automatic beq_opcode();
        opcode = 7'b1100011; // BEQ
        #1;
        assert(alu_op == 2'b01) else $fatal("BEQ: alu_op should be 01, got %b", alu_op);
        assert(branch == 1'b1) else $fatal("BEQ: branch should be 1, got %0b", branch);
        assert(mem_read == 1'b0) else $fatal("BEQ: mem_read should be 0, got %b", mem_read);
        assert(mem_write == 1'b0) else $fatal("BEQ: mem_write should be 0, got %b", mem_write);
        assert(mem_to_reg == 1'b0) else $fatal("BEQ: mem_to_reg should be 0, got %b", mem_to_reg);
        assert(alu_src == 1'b0) else $fatal("BEQ: alu_src should be 0, got %b", alu_src);
        assert(reg_write == 1'b0) else $fatal("BEQ: reg_write should be 0, got %b", reg_write);
        assert(error == 1'b0) else $fatal("BEQ: error should be 0, got %b", error);
    endtask

    function automatic is_supported_opcode(logic [6:0] opc);
        return (opc == 7'b0110011) || // R-type
               (opc == 7'b0010011) || // I-type
               (opc == 7'b0000011) || // Load
               (opc == 7'b0100011) || // Store
               (opc == 7'b1100011);   // BEQ
    endfunction

    task automatic unsupported_opcode();
        repeat(100) begin
            do begin
                opcode = $urandom_range(0, 127);
            end while (is_supported_opcode(opcode));
            #1;
            assert(error == 1'b1) else $fatal("Unsupported opcode: %b, error should be 1, got %b", opcode, error);
            assert(alu_op == 2'b00) else $fatal("Unsupported opcode: %b, alu_op should be 00, got %b", opcode, alu_op);
            assert(branch == 1'b0) else $fatal("Unsupported opcode: %b, branch should be 0, got %0b", opcode, branch);
            assert(mem_read == 1'b0) else $fatal("Unsupported opcode: %b, mem_read should be 0, got %b", opcode, mem_read);
            assert(mem_write == 1'b0) else $fatal("Unsupported opcode: %b, mem_write should be 0, got %b", opcode, mem_write);
            assert(mem_to_reg == 1'b0) else $fatal("Unsupported opcode: %b, mem_to_reg should be 0, got %b", opcode, mem_to_reg);
            assert(alu_src == 1'b0) else $fatal("Unsupported opcode: %b, alu_src should be 0, got %b", opcode, alu_src);
            assert(reg_write == 1'b0) else $fatal("Unsupported opcode: %b, reg_write should be 0, got %b", opcode, reg_write);   
        end
    endtask
endmodule
