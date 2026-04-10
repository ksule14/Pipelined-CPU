`timescale 1ns/1ps

module alu_tb;
import codes_pkg::*;

logic alu_src;
alu_control control;
logic [DATA_WIDTH-1:0] alu_result;
logic zero_flag;

class alu_trans;
    rand logic [DATA_WIDTH-1:0] rs1_data;
    rand logic [DATA_WIDTH-1:0] rs2_data;
    rand logic [DATA_WIDTH-1:0] imm;

    constraint c_rs1_data {rs1_data inside {[0:255]};}
    constraint c_rs2_data {rs2_data inside {[0:255]};}
    constraint c_imm {imm inside {[0:255]};}
endclass

alu_trans trans;

alu dut (
    .rs1_data(trans.rs1_data),
    .rs2_data(trans.rs2_data),
    .imm(trans.imm),
    .alu_src(alu_src),
    .control(control),
    .alu_result(alu_result),
    .zero_flag(zero_flag)
);

initial begin
trans = new();
add();
sub();
and_op();
or_op();
slt();
sltu();
end

task automatic add();
    repeat(100) begin
        assert(trans.randomize()) else $fatal("Randomization failed");
        alu_src = 0;
        control = ADD;
        #1;
        assert(alu_result == trans.rs1_data + trans.rs2_data) 
        else($fatal("ADD failed: %0d + %0d != %0d", trans.rs1_data, trans.rs2_data, alu_result));
    end
endtask

task automatic sub();
    repeat(100) begin
        assert(trans.randomize()) else $fatal("Randomization failed");
        alu_src = 0;
        control = SUB;
        #1;
         assert(alu_result == trans.rs1_data - trans.rs2_data) 
        else($fatal("SUB failed: %0d - %0d != %0d", trans.rs1_data, trans.rs2_data, alu_result));
    end
endtask

task automatic and_op();
    repeat(100) begin
        assert(trans.randomize()) else $fatal("Randomization failed");
        alu_src = 0;
        control = AND;
        #1;
         assert(alu_result == (trans.rs1_data & trans.rs2_data)) 
        else($fatal("AND failed: %0d & %0d != %0d", trans.rs1_data, trans.rs2_data, alu_result));
    end
endtask

task automatic or_op();
    repeat(100) begin
        assert(trans.randomize()) else $fatal("Randomization failed");
        alu_src = 0;
        control = OR;
        #1;
         assert(alu_result == (trans.rs1_data | trans.rs2_data)) 
        else($fatal("OR failed: %0d | %0d != %0d", trans.rs1_data, trans.rs2_data, alu_result));
    end
endtask

task automatic slt();
    repeat(100) begin
        assert(trans.randomize() with {$signed(rs1_data) < $signed(rs2_data);}) else $fatal("Randomization failed");
        alu_src = 0;
        control = SLT;
        #1;
         assert(alu_result == 1)
        else($fatal("SLT failed: %0d < %0d != %0d", trans.rs1_data, trans.rs2_data, alu_result));
    end

    repeat(100) begin
        assert(trans.randomize() with {$signed(rs1_data) >= $signed(rs2_data);}) else $fatal("Randomization failed");
        alu_src = 0;
        control = SLT;
        #1;
         assert(alu_result == 0)
        else($fatal("SLT failed: %0d < %0d != %0d", trans.rs1_data, trans.rs2_data, alu_result));
    end
endtask

task automatic sltu();
    repeat(100) begin
        assert(trans.randomize() with {rs1_data < rs2_data;}) else $fatal("Randomization failed");
        alu_src = 0;
        control = SLTU;
        #1;
         assert(alu_result == 1)
        else($fatal("SLTU failed: %0d < %0d != %0d", trans.rs1_data, trans.rs2_data, alu_result));
    end

    repeat(100) begin
        assert(trans.randomize() with {rs1_data >= rs2_data;}) else $fatal("Randomization failed");
        alu_src = 0;
        control = SLTU;
        #1;
         assert(alu_result == 0)
        else($fatal("SLTU failed: %0d < %0d != %0d", trans.rs1_data, trans.rs2_data, alu_result));
    end   
endtask