import codes_pkg::*;

module single_cpu (
    input logic clk,
    input logic rst_n
);
    //internal signals
    logic [WORD_WIDTH-1:0] pc_current;
    logic pc_src;
    logic [WORD_WIDTH-1:0] pc_branch;
    logic [DATA_WIDTH-1:0] addr_imm;
    logic [WORD_WIDTH-1:0] instruction;
    logic [1:0] alu_op;
    logic branch;
    logic mem_read;
    logic mem_write;
    logic mem_to_reg;
    logic alu_src;
    logic reg_write;
    alu_control alu_control_signal;
    logic [DATA_WIDTH-1:0] rs1_data;
    logic [DATA_WIDTH-1:0] rs2_data;
    logic [DATA_WIDTH-1:0] rd_data;
    logic [DATA_WIDTH-1:0] mem_data;
    logic [DATA_WIDTH-1:0] sign_extended_imm;
    logic zero_flag;

    assign addr_imm = pc_current + (sign_extended_imm << 2);
    assign pc_branch = addr_imm[WORD_WIDTH-1:0];
    // INSTANTIATED MODULES

    // Program Counter
    pc pc_inst (
        .clk(clk),
        .rst_n(rst_n),
        .pc_src(pc_src),
        .pc_branch(pc_branch),
        .pc_current(pc_current)
    );

    // Instruction Memory
    instruction_mem instr_mem_inst (
        .addr(pc_current),
        .instruction(instruction)
    );

    // Main Control Unit
    main_control main_ctrl_inst (
        .opcode(instruction[6:0]),
        .alu_op(alu_op),
        .branch(branch),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_to_reg(mem_to_reg),
        .alu_src(alu_src),
        .reg_write(reg_write),
        .pc_src(pc_src)
    );

    // Register File
    reg_file reg_file_inst (
        .clk(clk),
        .reg_write(reg_write),
        .mem_to_reg(mem_to_reg),
        .rs1_addr(instruction[19:15]),
        .rs2_addr(instruction[24:20]),
        .rd_addr(instruction[11:7]),
        .rd_data(rd_data),
        .mem_data(mem_data),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );
    // ALU control
    alu_control alu_ctrl_inst (
        .alu_op(alu_op),
        .funct3(instruction[14:12]),
        .bit_30(instruction[30]),
        .control(alu_control_signal)
    );

    // ALU
    alu alu_inst (
        .reg_1(rs1_data),
        .reg_2(rs2_data),
        .sign_extended_imm(sign_extended_imm),
        .alu_src(alu_src),
        .control(alu_control_signal),
        .result(rd_data),
        .zero_flag(zero_flag)
    );

    // Immediate Generator
    imm_gen imm_gen_inst (
        .instruction(instruction),
        .sign_extended_imm(sign_extended_imm)
    );

    // Data Memory
    data_mem data_mem_inst (
        .clk(clk),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .addr(rd_data),
        .write_data(rs2_data),
        .read_data(mem_data)
    );
endmodule
