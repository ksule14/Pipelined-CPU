`timescale 1ns / 1ps

module main_ctrl_tb;

    // Input
    logic [6:0] opcode;

    // Outputs
    logic [1:0] alu_op;
    logic branch;
    logic mem_read;
    logic mem_write;
    logic mem_to_reg;
    logic alu_src;
    logic reg_write;
    logic pc_src;
    logic zero_flag = 0;

    main_control dut (
        .opcode(opcode),
        .alu_op(alu_op),
        .branch(branch),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_to_reg(mem_to_reg),
        .alu_src(alu_src),
        .reg_write(reg_write),
        .pc_src(pc_src),
        .zero_flag(zero_flag)
    );

        initial begin
       
        opcode = 7'b01100011;
        #1;
        assert(alu_op == 2'b01) else $error("Type test failed");
        assert(branch == 1) else $error("branch signal incorrect");
        assert(mem_read == 0) else $error("mem_read signal incorrect");
        assert(mem_write == 0) else $error("mem_write signal incorrect");
        assert(mem_to_reg == 0) else $error("mem_to_reg signal incorrect");
        assert(alu_src == 0) else $error("alu_src signal incorrect");
        assert(reg_write == 0) else $error("reg_write signal incorrect");
        assert(pc_src == 0) else $error("pc_src signal incorrect");
        $display("All tests completed");
        $finish;
        end

endmodule
            