package pipeline_pkg;
import codes_pkg::DATA_WIDTH;
import codes_pkg::WORD_WIDTH;

    typedef struct packed {
        logic [WORD_WIDTH-1:0] pc;
        logic [WORD_WIDTH-1:0] instr;
    } if_id_t;

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
    } id_ex_t;

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
    } ex_mem_t;

    typedef struct packed {
        logic                  mem_to_reg;
        logic                  reg_write;
        logic [DATA_WIDTH-1:0] alu_data;
        logic [DATA_WIDTH-1:0] mem_data;
        logic [4:0]            rd;
    } mem_wb_t;

endpackage