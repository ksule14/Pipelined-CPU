`timescale 1ns/1ps
import codes_pkg::*;

module alu_tb;
    // Testbench signals
    logic [DATA_WIDTH-1:0] reg_1;
    logic [DATA_WIDTH-1:0] reg_2;
    logic [DATA_WIDTH-1:0] sign_extended_imm;
    logic alu_src;
    alu_control control;
    logic [DATA_WIDTH-1:0] result;
    logic zero_flag;

    alu dut (
        .reg_1(reg_1),
        .reg_2(reg_2),
        .sign_extended_imm(sign_extended_imm),
        .alu_src(alu_src),
        .control(control),
        .result(result),
        .zero_flag(zero_flag)
    );

    initial begin
        // Test ADD
        reg_1 = 64'd10;
        reg_2 = 64'd20;
        alu_src = 0;
        control = ADD;
        #0;
        if (result !== 64'd30 || zero_flag !== 0) $error("ADD test failed");
        else $display("ADD test passed");

        // Test SUB
        control = SUB;
        #0;
        if (result !== -64'd10 || zero_flag !== 0) $error("SUB test failed");
        else $display("SUB test passed");

        // Test AND
        control = AND;
        #0;
        if (result !== (64'd0) || zero_flag !== 1) $error("AND test failed");
        else $display("AND test passed");
        // Test OR
        control = OR;
        #0;
        if (result !== (64'd30) || zero_flag !== 0) $error("OR test failed");
        else $display("OR test passed");

        // Test SLT
        reg_2 = -64'd20;
        control = SLT;
        #0;
        if (result !== 64'd0 || zero_flag !== 1) $error("SLT test failed");
        else $display("SLT test passed");

        // Test SLTU
        control = SLTU;
        #0;
        if (result !== 64'd1 || zero_flag !== 0) $error("SLTU test failed");
        else $display("SLTU test passed");

        // Test with immediate value
        sign_extended_imm = 64'd15;
        alu_src = 1;
        control = ADD;
        #0;
        if (result !== 64'd25 || zero_flag !== 0) $error("ADD with immediate test failed");
        else $display("ADD with immediate test passed");
        $finish;
    end
endmodule


