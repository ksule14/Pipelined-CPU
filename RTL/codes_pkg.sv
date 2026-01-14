package codes_pkg;
typedef enum logic [2:0] {
    ADD, SUB, AND, OR, SLT, SLTU // ALU control signals
} alu_control;

parameter DATA_WIDTH = 64;
parameter WORD_WIDTH = 32;
parameter DEPTH = 256;
endpackage

