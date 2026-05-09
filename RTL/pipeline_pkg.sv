package pipeline_pkg;
import codes_pkg::DATA_WIDTH;
import codes_pkg::WORD_WIDTH;

// 5 pipeline stages used in this processor
// the control signals are passed along to further stages until they are used up

    // IF/ID stage
    // sends pc and instruction
    typedef struct packed {
        logic [WORD_WIDTH-1:0] pc;
        logic [WORD_WIDTH-1:0] instr;
        logic                  prog_end;
        logic                  predict_taken;
    } if_id_t;

    // ID/EX stage
    // instruction is decoded so everything must be sent to further stages
    typedef struct packed {
        logic [1:0]             alu_op;
        logic                   alu_src;
        logic                   branch;
        logic                   mem_read;
        logic                   mem_write;
        logic                   mem_to_reg;
        logic                   reg_write;
        logic [DATA_WIDTH-1:0]  rs1_data;
        logic [DATA_WIDTH-1:0]  rs2_data;
        logic [DATA_WIDTH-1:0]  imm;
        logic [DATA_WIDTH-1:0]  pc;
        logic [4:0]             rs1;
        logic [4:0]             rs2;
        logic [4:0]             rd;
        logic [2:0]             funct3;
        logic                   bit_30;
        logic                   prog_end;
        logic                   predict_taken;
    } id_ex_t;

    // EX/MEM stage
    // alu-specific signals are used up here and not passed along
    typedef struct packed {
        logic                  branch;
        logic                  mem_read;
        logic                  mem_write;
        logic                  mem_to_reg;
        logic                  reg_write;
        logic [DATA_WIDTH-1:0] alu_result;
        logic                  zero_flag;
        logic [DATA_WIDTH-1:0] rs2_data;
        logic [DATA_WIDTH-1:0] branch_addr;
        logic [DATA_WIDTH-1:0] pc;
        logic [4:0]            rd;
        logic                  prog_end;
        logic                  predict_taken;
    } ex_mem_t;

    // MEM/WB stage
    // memory-specific signals are used up here and not passed along
    // processor goes back to IF/ID stage after this
    typedef struct packed {
        logic                  mem_to_reg;
        logic                  reg_write;
        logic [DATA_WIDTH-1:0] alu_data;
        logic [DATA_WIDTH-1:0] mem_data;
        logic [4:0]            rd;
    } mem_wb_t;

endpackage