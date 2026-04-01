import codes_pkg::*;
import branch_fsm_pkg::*;

module cpu_top (
    input logic clk,
    input logic rst_n
);

    // =========================================================================
    // IF/ID pipeline register
    // =========================================================================
    logic [DATA_WIDTH-1:0] if_id_pc;
    logic [WORD_WIDTH-1:0] if_id_instr;

    // =========================================================================
    // ID/EX pipeline register
    // =========================================================================
    logic [1:0]            id_ex_alu_op;
    logic                  id_ex_alu_src;
    logic                  id_ex_branch;
    logic                  id_ex_mem_read;
    logic                  id_ex_mem_write;
    logic                  id_ex_mem_to_reg;
    logic                  id_ex_reg_write;
    logic [DATA_WIDTH-1:0] id_ex_rs1_data;
    logic [DATA_WIDTH-1:0] id_ex_rs2_data;
    logic [DATA_WIDTH-1:0] id_ex_imm;
    logic [DATA_WIDTH-1:0] id_ex_pc;
    logic [4:0]            id_ex_rs1;
    logic [4:0]            id_ex_rs2;
    logic [4:0]            id_ex_rd;
    logic [2:0]            id_ex_funct3;
    logic                  id_ex_bit_30;

    // =========================================================================
    // EX/MEM pipeline register
    // =========================================================================
    logic                  ex_mem_branch;
    logic                  ex_mem_mem_read;
    logic                  ex_mem_mem_write;
    logic                  ex_mem_mem_to_reg;
    logic                  ex_mem_reg_write;
    logic [DATA_WIDTH-1:0] ex_mem_alu_result;
    logic                  ex_mem_zero_flag;
    logic [DATA_WIDTH-1:0] ex_mem_rs2_data;
    logic [DATA_WIDTH-1:0] ex_mem_branch_addr;
    logic [DATA_WIDTH-1:0] ex_mem_pc;
    logic [4:0]            ex_mem_rd;

    // =========================================================================
    // MEM/WB pipeline register
    // =========================================================================
    logic                  mem_wb_mem_to_reg;
    logic                  mem_wb_reg_write;
    logic [DATA_WIDTH-1:0] mem_wb_alu_data;
    logic [DATA_WIDTH-1:0] mem_wb_mem_data;
    logic [4:0]            mem_wb_rd;

    // =========================================================================
    // IF stage wires
    // =========================================================================
    logic [DATA_WIDTH-1:0] pc_current;
    logic [WORD_WIDTH-1:0] if_instruction;

    // =========================================================================
    // ID stage wires (combinational outputs of decode modules)
    // =========================================================================
    logic [1:0]            id_alu_op;
    logic                  id_alu_src;
    logic                  id_branch;
    logic                  id_mem_read;
    logic                  id_mem_write;
    logic                  id_mem_to_reg;
    logic                  id_reg_write;
    logic [DATA_WIDTH-1:0] id_rs1_data;
    logic [DATA_WIDTH-1:0] id_rs2_data;
    logic [DATA_WIDTH-1:0] id_imm;

    // =========================================================================
    // EX stage wires
    // =========================================================================
    alu_control            ex_alu_ctrl;
    logic [DATA_WIDTH-1:0] ex_alu_result;
    logic                  ex_zero_flag;
    logic [DATA_WIDTH-1:0] ex_branch_addr;
    logic [1:0]            ex_forward_a;
    logic [1:0]            ex_forward_b;
    logic [DATA_WIDTH-1:0] ex_alu_a;       // forwarded rs1 into ALU
    logic [DATA_WIDTH-1:0] ex_alu_b_pre;   // forwarded rs2 (before alu_src mux)

    // =========================================================================
    // MEM stage wires
    // =========================================================================
    logic [DATA_WIDTH-1:0] mem_read_data;
    logic                  mem_stall;
    logic [31:0]           ram_addr;
    logic                  ram_read_en;
    logic                  ram_write_en;
    logic [DATA_WIDTH-1:0] ram_read_data;
    logic                  ram_ready;

    // =========================================================================
    // WB stage wires
    // =========================================================================
    logic [DATA_WIDTH-1:0] wb_data;

    // =========================================================================
    // Hazard / branch control wires
    // =========================================================================
    logic branch_taken;
    logic predict_taken;
    logic pc_en;
    logic if_id_en;
    logic id_ex_en;
    logic ex_mem_en;
    logic mem_wb_en;
    logic stall;
    logic id_ex_flush_stall;   // from stalling_u
    logic if_id_flush_stall;   // from stalling_u
    logic flush_IF_ID;         // from flush_controller
    logic flush_ID_EX;         // from flush_controller
    logic pc_redirect;

    assign branch_taken = ex_mem_branch && ex_mem_zero_flag;

    // =========================================================================
    // IF stage
    // =========================================================================

    pc u_pc (
        .clk        (clk),
        .rst_n      (rst_n),
        .pc_en      (pc_en),
        .pc_redirect(pc_redirect),
        .pc_branch  (ex_mem_branch_addr),
        .pc_current (pc_current)
    );

    instruction_mem u_imem (
        .addr       (pc_current),
        .instruction(if_instruction)
    );

    // =========================================================================
    // ID stage
    // =========================================================================

    main_control u_ctrl (
        .opcode    (if_id_instr[6:0]),
        .alu_op    (id_alu_op),
        .branch    (id_branch),
        .mem_read  (id_mem_read),
        .mem_write (id_mem_write),
        .mem_to_reg(id_mem_to_reg),
        .alu_src   (id_alu_src),
        .reg_write (id_reg_write)
    );

    imm_gen u_immgen (
        .instruction(if_id_instr),
        .imm        (id_imm)
    );

    reg_file u_regfile (
        .clk       (clk),
        .reg_write (mem_wb_reg_write),
        .rs1_addr  (if_id_instr[19:15]),
        .rs2_addr  (if_id_instr[24:20]),
        .rd_addr   (mem_wb_rd),
        .write_data(wb_data),
        .rs1_data  (id_rs1_data),
        .rs2_data  (id_rs2_data)
    );

    stalling_u u_stall (
        .if_id_rs1      (if_id_instr[19:15]),
        .if_id_rs2      (if_id_instr[24:20]),
        .id_ex_mem_load (id_ex_mem_read),
        .id_ex_rd       (id_ex_rd),
        .ex_branch_taken(branch_taken),
        .pc_redirect    (pc_redirect),
        .mem_stall      (mem_stall),
        .pc_en          (pc_en),
        .if_id_en       (if_id_en),
        .id_ex_en       (id_ex_en),
        .id_ex_flush    (id_ex_flush_stall),
        .if_id_flush    (if_id_flush_stall),
        .ex_mem_en      (ex_mem_en),
        .mem_wb_en      (mem_wb_en),
        .stall          (stall)
    );

    // =========================================================================
    // EX stage
    // =========================================================================

    alu_ctrl u_aluctrl (
        .alu_op (id_ex_alu_op),
        .bit_30 (id_ex_bit_30),
        .funct3 (id_ex_funct3),
        .control(ex_alu_ctrl)
    );

    forwarding_u u_fwd (
        .ex_rs1        (id_ex_rs1),
        .ex_rs2        (id_ex_rs2),
        .rd_mem        (ex_mem_rd),
        .rd_wb         (mem_wb_rd),
        .reg_write_mem (ex_mem_reg_write),
        .ex_mem_is_load(ex_mem_mem_read),
        .reg_write_wb  (mem_wb_reg_write),
        .forward_a     (ex_forward_a),
        .forward_b     (ex_forward_b)
    );

    always_comb begin
        unique case (ex_forward_a)
            2'b10:   ex_alu_a = ex_mem_alu_result;
            2'b01:   ex_alu_a = wb_data;
            default: ex_alu_a = id_ex_rs1_data;
        endcase

        unique case (ex_forward_b)
            2'b10:   ex_alu_b_pre = ex_mem_alu_result;
            2'b01:   ex_alu_b_pre = wb_data;
            default: ex_alu_b_pre = id_ex_rs2_data;
        endcase
    end

    alu u_alu (
        .rs1_data  (ex_alu_a),
        .rs2_data  (ex_alu_b_pre),
        .imm       (id_ex_imm),
        .alu_src   (id_ex_alu_src),
        .control   (ex_alu_ctrl),
        .alu_result(ex_alu_result),
        .zero_flag (ex_zero_flag)
    );

    branch_calc u_branchcalc (
        .pc         (id_ex_pc),
        .imm        (id_ex_imm),
        .branch_addr(ex_branch_addr)
    );

    // =========================================================================
    // MEM stage
    // =========================================================================

    cache u_cache (
        .clk          (clk),
        .rst_n        (rst_n),
        .addr         (ex_mem_alu_result),
        .write_data   (ex_mem_rs2_data),
        .read_en      (ex_mem_mem_read),
        .write_en     (ex_mem_mem_write),
        .cache_stall  (mem_stall),
        .read_data    (mem_read_data),
        .mem_address  (ram_addr),
        .mem_read_en  (ram_read_en),
        .mem_write_en (ram_write_en),
        .mem_read_data(ram_read_data),
        .mem_ready    (ram_ready)
    );

    ram u_ram (
        .clk       (clk),
        .rst_n     (rst_n),
        .write_data(ex_mem_rs2_data),
        .addr      (ram_addr),
        .write_en  (ram_write_en),
        .read_en   (ram_read_en),
        .read_data (ram_read_data),
        .mem_ready (ram_ready)
    );

    // =========================================================================
    // WB stage
    // =========================================================================

    write_back u_wb (
        .mem_to_reg(mem_wb_mem_to_reg),
        .alu_data  (mem_wb_alu_data),
        .mem_data  (mem_wb_mem_data),
        .wb_data   (wb_data)
    );

    // =========================================================================
    // Branch prediction and flush control
    // =========================================================================

    branch_predictor u_bpred (
        .clk          (clk),
        .rst_n        (rst_n),
        .pc_fetch     (pc_current),
        .predict_taken(predict_taken),
        .update_en    (ex_mem_branch),
        .update_pc    (ex_mem_pc),
        .actual_taken (branch_taken)
    );

    flush_controller u_flush (
        .clk             (clk),
        .rst_n           (rst_n),
        .branch_resolved (ex_mem_branch),
        .branch_taken    (branch_taken),
        .branch_target   (ex_mem_branch_addr),
        .branch_addr     (ex_mem_branch_addr),
        .predicted_taken (predict_taken),
        .flush_IF_ID     (flush_IF_ID),
        .flush_ID_EX     (flush_ID_EX),
        .pc_redirect     (pc_redirect)
    );

    // =========================================================================
    // IF/ID pipeline register
    // =========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n || flush_IF_ID || if_id_flush_stall) begin
            if_id_pc    <= '0;
            if_id_instr <= '0;
        end else if (if_id_en) begin
            if_id_pc    <= pc_current;
            if_id_instr <= if_instruction;
        end
    end

    // =========================================================================
    // ID/EX pipeline register
    // =========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n || id_ex_flush_stall || flush_ID_EX) begin
            id_ex_alu_op     <= '0;
            id_ex_alu_src    <= 1'b0;
            id_ex_branch     <= 1'b0;
            id_ex_mem_read   <= 1'b0;
            id_ex_mem_write  <= 1'b0;
            id_ex_mem_to_reg <= 1'b0;
            id_ex_reg_write  <= 1'b0;
            id_ex_rs1_data   <= '0;
            id_ex_rs2_data   <= '0;
            id_ex_imm        <= '0;
            id_ex_pc         <= '0;
            id_ex_rs1        <= '0;
            id_ex_rs2        <= '0;
            id_ex_rd         <= '0;
            id_ex_funct3     <= '0;
            id_ex_bit_30     <= 1'b0;
        end else if (id_ex_en) begin
            id_ex_alu_op     <= id_alu_op;
            id_ex_alu_src    <= id_alu_src;
            id_ex_branch     <= id_branch;
            id_ex_mem_read   <= id_mem_read;
            id_ex_mem_write  <= id_mem_write;
            id_ex_mem_to_reg <= id_mem_to_reg;
            id_ex_reg_write  <= id_reg_write;
            id_ex_rs1_data   <= id_rs1_data;
            id_ex_rs2_data   <= id_rs2_data;
            id_ex_imm        <= id_imm;
            id_ex_pc         <= if_id_pc;
            id_ex_rs1        <= if_id_instr[19:15];
            id_ex_rs2        <= if_id_instr[24:20];
            id_ex_rd         <= if_id_instr[11:7];
            id_ex_funct3     <= if_id_instr[14:12];
            id_ex_bit_30     <= if_id_instr[30];
        end
    end

    // =========================================================================
    // EX/MEM pipeline register
    // =========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ex_mem_branch      <= 1'b0;
            ex_mem_mem_read    <= 1'b0;
            ex_mem_mem_write   <= 1'b0;
            ex_mem_mem_to_reg  <= 1'b0;
            ex_mem_reg_write   <= 1'b0;
            ex_mem_alu_result  <= '0;
            ex_mem_zero_flag   <= 1'b0;
            ex_mem_rs2_data    <= '0;
            ex_mem_branch_addr <= '0;
            ex_mem_pc          <= '0;
            ex_mem_rd          <= '0;
        end else if (ex_mem_en) begin
            ex_mem_branch      <= id_ex_branch;
            ex_mem_mem_read    <= id_ex_mem_read;
            ex_mem_mem_write   <= id_ex_mem_write;
            ex_mem_mem_to_reg  <= id_ex_mem_to_reg;
            ex_mem_reg_write   <= id_ex_reg_write;
            ex_mem_alu_result  <= ex_alu_result;
            ex_mem_zero_flag   <= ex_zero_flag;
            ex_mem_rs2_data    <= ex_alu_b_pre;
            ex_mem_branch_addr <= ex_branch_addr;
            ex_mem_pc          <= id_ex_pc;
            ex_mem_rd          <= id_ex_rd;
        end
    end

    // =========================================================================
    // MEM/WB pipeline register
    // =========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_wb_mem_to_reg <= 1'b0;
            mem_wb_reg_write  <= 1'b0;
            mem_wb_alu_data   <= '0;
            mem_wb_mem_data   <= '0;
            mem_wb_rd         <= '0;
        end else if (mem_wb_en) begin
            mem_wb_mem_to_reg <= ex_mem_mem_to_reg;
            mem_wb_reg_write  <= ex_mem_reg_write;
            mem_wb_alu_data   <= ex_mem_alu_result;
            mem_wb_mem_data   <= mem_read_data;
            mem_wb_rd         <= ex_mem_rd;
        end
    end

endmodule
