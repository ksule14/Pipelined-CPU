import codes_pkg::*;
import branch_fsm_pkg::*;
import pipeline_pkg::*;

module cpu_top #(
    parameter integer PROGRAM_LENGTH = codes_pkg::PROGRAM_LENGTH
)(
    input  logic clk,
    input  logic rst_n,
    output logic error,
    output logic prog_done,
    output logic tx_serial
);

    // =========================================================================
    // IF/ID pipeline register
    // =========================================================================
    if_id_t if_id_reg;

    // =========================================================================
    // ID/EX pipeline register
    // =========================================================================
    id_ex_t id_ex_reg;

    // =========================================================================
    // EX/MEM pipeline register
    // =========================================================================
    ex_mem_t ex_mem_reg;

    // =========================================================================
    // MEM/WB pipeline register
    // =========================================================================
    mem_wb_t mem_wb_reg;

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

    cache_ram u_mem_bus();

    // UART interconnect
    logic                  uart_store;
    logic                  uart_stall;
    logic                  fifo_full;
    logic                  fifo_write_en;
    logic [7:0]            fifo_data_in;
    logic [7:0]            fifo_data_out;
    logic                  fifo_read_en;
    logic                  fifo_empty;
    logic [7:0]            uart_tx_data;
    logic                  uart_tx_start;
    logic                  uart_tx_busy;
    
    // prog_done logic
    logic                  imem_done;
    logic                  prog_done_nb;
    logic                  halt_request;
    logic                  halt_gate;
    logic                  halt_branch_request;
    logic                  halt_branch_gate;
    logic                  prog_end_seen;
    logic                  prog_done_pulse;
    logic                  prog_done_held;
    logic                  actual_pc_en;
    logic                  actual_if_id_en;
    logic [DATA_WIDTH-1:0] redirect_target;

    // =========================================================================
    // WB stage wires
    // =========================================================================
    logic [DATA_WIDTH-1:0] wb_data;

    // =========================================================================
    // Error signals
    // =========================================================================
    logic ctrl_error;      // unsupported opcode in main_control
    logic immgen_error;    // unsupported opcode in imm_gen
    logic aluctrl_error;   // unsupported funct3/alu_op in alu_ctrl
    logic imem_error;      // unaligned instruction fetch
    logic cache_error;     // unaligned data access

    localparam logic [31:0] UART_ADDR = 32'd1024;

    

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
    logic flush_IF_ID;         // from flush_controller
    logic flush_ID_EX;         // from flush_controller
    logic pc_redirect;

    // =========================================================================
    // IF stage
    // =========================================================================

    pc u_pc (
        .clk        (clk),
        .rst_n      (rst_n),
        .pc_en      (actual_pc_en),
        .pc_redirect(pc_redirect),
        .pc_branch  (redirect_target),
        .pc_current (pc_current)
    );

    instruction_mem #(
        .PROGRAM_LENGTH(PROGRAM_LENGTH)
    ) u_imem (
        .addr       (pc_current),
        .instruction(if_instruction),
        .done       (imem_done),
        .error      (imem_error)
    );

    // =========================================================================
    // ID stage
    // =========================================================================

    main_control u_ctrl (
        .opcode    (if_id_reg.instr[6:0]),
        .prog_end  (if_id_reg.prog_end),
        .alu_op    (id_alu_op),
        .branch    (id_branch),
        .mem_read  (id_mem_read),
        .mem_write (id_mem_write),
        .mem_to_reg(id_mem_to_reg),
        .alu_src   (id_alu_src),
        .reg_write (id_reg_write),
        .prog_done (prog_done_nb),
        .error     (ctrl_error)
    );

    imm_gen u_immgen (
        .instruction(if_id_reg.instr),
        .imm        (id_imm),
        .error      (immgen_error)
    );

    reg_file u_regfile (
        .clk       (clk),
        .reg_write (mem_wb_reg.reg_write),
        .rs1_addr  (if_id_reg.instr[19:15]),
        .rs2_addr  (if_id_reg.instr[24:20]),
        .rd_addr   (mem_wb_reg.rd),
        .write_data(wb_data),
        .rs1_data  (id_rs1_data),
        .rs2_data  (id_rs2_data)
    );

    stalling_u u_stall (
        .if_id_rs1      (if_id_reg.instr[19:15]),
        .if_id_rs2      (if_id_reg.instr[24:20]),
        .id_ex_mem_load (id_ex_reg.mem_read),
        .id_ex_rd       (id_ex_reg.rd),
        .pc_redirect    (pc_redirect),
        .mem_stall      (mem_stall),
        .uart_stall     (uart_stall),
        .pc_en          (pc_en),
        .if_id_en       (if_id_en),
        .id_ex_en       (id_ex_en),
        .id_ex_flush    (id_ex_flush_stall),
        .ex_mem_en      (ex_mem_en),
        .mem_wb_en      (mem_wb_en),
    );

    // =========================================================================
    // EX stage
    // =========================================================================

    alu_ctrl u_aluctrl (
        .alu_op (id_ex_reg.alu_op),
        .bit_30 (id_ex_reg.bit_30),
        .funct3 (id_ex_reg.funct3),
        .control(ex_alu_ctrl),
        .error  (aluctrl_error)
    );

    forwarding_u u_fwd (
        .ex_rs1        (id_ex_reg.rs1),
        .ex_rs2        (id_ex_reg.rs2),
        .rd_mem        (ex_mem_reg.rd),
        .rd_wb         (mem_wb_reg.rd),
        .reg_write_mem (ex_mem_reg.reg_write),
        .ex_mem_is_load(ex_mem_reg.mem_read),
        .reg_write_wb  (mem_wb_reg.reg_write),
        .forward_a     (ex_forward_a),
        .forward_b     (ex_forward_b)
    );

    always_comb begin
        unique case (ex_forward_a)
            2'b10:   ex_alu_a = ex_mem_reg.alu_result;
            2'b01:   ex_alu_a = wb_data;
            default: ex_alu_a = id_ex_reg.rs1_data;
        endcase

        unique case (ex_forward_b)
            2'b10:   ex_alu_b_pre = ex_mem_reg.alu_result;
            2'b01:   ex_alu_b_pre = wb_data;
            default: ex_alu_b_pre = id_ex_reg.rs2_data;
        endcase
    end

    alu u_alu (
        .rs1_data  (ex_alu_a),
        .rs2_data  (ex_alu_b_pre),
        .imm       (id_ex_reg.imm),
        .alu_src   (id_ex_reg.alu_src),
        .control   (ex_alu_ctrl),
        .alu_result(ex_alu_result),
        .zero_flag (ex_zero_flag)
    );

    branch_calc u_branchcalc (
        .pc         (id_ex_reg.pc),
        .imm        (id_ex_reg.imm),
        .branch_addr(ex_branch_addr)
    );

    // =========================================================================
    // MEM stage
    // =========================================================================

    cache u_cache (
        .clk          (clk),
        .rst_n        (rst_n),
        .addr         (ex_mem_reg.alu_result),
        .write_data   (ex_mem_reg.rs2_data),
        .read_en      (ex_mem_reg.mem_read),
        .write_en     (ex_mem_reg.mem_write && !uart_store),
        .cache_stall  (mem_stall),
        .read_data    (mem_read_data),
        .error        (cache_error),
        .mem_bus      (u_mem_bus.cache)
    );

    ram u_ram (
        .clk       (clk),
        .write_data(ex_mem_reg.rs2_data),
        .mem_bus   (u_mem_bus.ram)
    );

    sync_fifo u_uart_fifo (
        .clk          (clk),
        .rst_n        (rst_n),
        .fifo_write_en(fifo_write_en),
        .fifo_data_in (fifo_data_in),
        .fifo_full    (fifo_full),
        .fifo_read_en (fifo_read_en),
        .fifo_data_out(fifo_data_out),
        .fifo_empty   (fifo_empty)
    );

    uart_ctrl #(
        .UART_ADDR(UART_ADDR)
    ) u_uart (
        .clk          (clk),
        .rst_n        (rst_n),
        .mem_addr     (ex_mem_reg.alu_result),
        .write_data   (ex_mem_reg.rs2_data),
        .mem_write    (ex_mem_reg.mem_write),
        .fifo_full    (fifo_full),
        .fifo_write_en(fifo_write_en),
        .fifo_data_in (fifo_data_in),
        .fifo_data_out(fifo_data_out),
        .fifo_read_en (fifo_read_en),
        .fifo_empty   (fifo_empty),
        .tx_data      (uart_tx_data),
        .tx_start     (uart_tx_start),
        .tx_busy      (uart_tx_busy)
    );

    tx u_tx (
        .clk      (clk),
        .rst_n    (rst_n),
        .tx_data  (uart_tx_data),
        .tx_start (uart_tx_start),
        .tx_busy  (uart_tx_busy),
        .tx_serial(tx_serial)
    );

    // =========================================================================
    // WB stage
    // =========================================================================

    write_back u_wb (
        .mem_to_reg(mem_wb_reg.mem_to_reg),
        .alu_data  (mem_wb_reg.alu_data),
        .mem_data  (mem_wb_reg.mem_data),
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
        .update_en    (ex_mem_reg.branch),
        .update_pc    (ex_mem_reg.pc),
        .actual_taken (branch_taken)
    );

    flush_controller u_flush (
        .branch_resolved (ex_mem_reg.branch),
        .branch_taken    (branch_taken),
        .predicted_taken (ex_mem_reg.predict_taken),
        .flush_IF_ID     (flush_IF_ID),
        .flush_ID_EX     (flush_ID_EX),
        .pc_redirect     (pc_redirect)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            halt_request        <= 1'b0;
            halt_gate           <= 1'b0;
            halt_branch_request <= 1'b0;
            halt_branch_gate    <= 1'b0;
            prog_end_seen       <= 1'b0;
        end else begin
            halt_request        <= if_id_reg.prog_end && !id_branch;
            halt_gate           <= halt_request;
            halt_branch_request <= ex_mem_reg.prog_end && ex_mem_reg.branch && !branch_taken;
            halt_branch_gate    <= halt_branch_request;
            if (if_id_reg.prog_end)
                prog_end_seen   <= 1'b1;
        end
    end

    // =========================================================================
    // IF/ID pipeline register
    // =========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        if_id_reg.pc            <= '0;
        if_id_reg.instr         <= 32'h00000013; // NOP
        if_id_reg.prog_end      <= 1'b0;
        if_id_reg.predict_taken <= 1'b0;
    end else begin
        // Move the flush inside the synchronous 'else' block
        if (flush_IF_ID) begin
            if_id_reg.pc            <= '0;
            if_id_reg.instr         <= 32'h00000013;
            if_id_reg.prog_end      <= 1'b0;
            if_id_reg.predict_taken <= 1'b0;
        end else if (actual_if_id_en) begin
            if_id_reg.pc            <= pc_current;
            if_id_reg.instr         <= if_instruction;
            if_id_reg.prog_end      <= imem_done;
            if_id_reg.predict_taken <= predict_taken;
        end else if (prog_end_seen && id_ex_en) begin
            // Last instruction has advanced into ID/EX; clear IF/ID to NOP so it
            // cannot re-dispatch if the pipeline later unstalls (e.g. after uart_stall).
            if_id_reg.pc            <= '0;
            if_id_reg.instr         <= 32'h00000013;
            if_id_reg.prog_end      <= 1'b0;
            if_id_reg.predict_taken <= 1'b0;
        end
    end
end

    // =========================================================================
    // ID/EX pipeline register
    // =========================================================================
    // ID/EX pipeline register
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Only the hardware reset is asynchronous
        id_ex_reg <= '0;
    end else begin
        // Everything below is synchronous to the clock edge
        if (id_ex_flush_stall || flush_ID_EX) begin
            id_ex_reg <= '0;
        end else if (id_ex_en) begin
            id_ex_reg.alu_op     <= id_alu_op;
            id_ex_reg.alu_src    <= id_alu_src;
            id_ex_reg.branch     <= id_branch;
            id_ex_reg.mem_read   <= id_mem_read;
            id_ex_reg.mem_write  <= id_mem_write;
            id_ex_reg.mem_to_reg <= id_mem_to_reg;
            id_ex_reg.reg_write  <= id_reg_write;
            id_ex_reg.rs1_data   <= id_rs1_data;
            id_ex_reg.rs2_data   <= id_rs2_data;
            id_ex_reg.imm        <= id_imm;
            id_ex_reg.pc         <= if_id_reg.pc;
            id_ex_reg.rs1        <= if_id_reg.instr[19:15];
            id_ex_reg.rs2        <= if_id_reg.instr[24:20];
            id_ex_reg.rd         <= if_id_reg.instr[11:7];
            id_ex_reg.funct3        <= if_id_reg.instr[14:12];
            id_ex_reg.bit_30        <= if_id_reg.instr[30];
            id_ex_reg.prog_end      <= if_id_reg.prog_end;
            id_ex_reg.predict_taken <= if_id_reg.predict_taken;
        end
    end
end

    // =========================================================================
    // EX/MEM pipeline register
    // =========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ex_mem_reg <= '0;
        end else if (ex_mem_en) begin
            ex_mem_reg.branch      <= id_ex_reg.branch;
            ex_mem_reg.mem_read    <= id_ex_reg.mem_read;
            ex_mem_reg.mem_write   <= id_ex_reg.mem_write;
            ex_mem_reg.mem_to_reg  <= id_ex_reg.mem_to_reg;
            ex_mem_reg.reg_write   <= id_ex_reg.reg_write;
            ex_mem_reg.alu_result  <= ex_alu_result;
            ex_mem_reg.zero_flag   <= ex_zero_flag;
            ex_mem_reg.rs2_data    <= ex_alu_b_pre;
            ex_mem_reg.branch_addr <= ex_branch_addr;
            ex_mem_reg.pc            <= id_ex_reg.pc;
            ex_mem_reg.rd            <= id_ex_reg.rd;
            ex_mem_reg.prog_end      <= id_ex_reg.prog_end;
            ex_mem_reg.predict_taken <= id_ex_reg.predict_taken;
        end
    end

    // =========================================================================
    // MEM/WB pipeline register
    // =========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_wb_reg <= '0;
        end else if (mem_wb_en) begin
            mem_wb_reg.mem_to_reg <= ex_mem_reg.mem_to_reg;
            mem_wb_reg.reg_write  <= ex_mem_reg.reg_write;
            mem_wb_reg.alu_data   <= ex_mem_reg.alu_result;
            mem_wb_reg.mem_data   <= mem_read_data;
            mem_wb_reg.rd         <= ex_mem_reg.rd;
        end
    end

    assign branch_taken = ex_mem_reg.branch && ex_mem_reg.zero_flag;

    assign error = ctrl_error | immgen_error | aluctrl_error | imem_error | cache_error;
    assign uart_store = ex_mem_reg.mem_write && (ex_mem_reg.alu_result == UART_ADDR);
    assign uart_stall = uart_store && fifo_full;
    assign redirect_target = branch_taken ? ex_mem_reg.branch_addr : (ex_mem_reg.pc + 4);

    // prog_done_pulse is high for the 1-2 cycles when the last instruction is at the
    // appropriate stage. prog_done_held latches that pulse so the output stays asserted
    // for the rest of the run. Required to drive a board LED visibly.
    assign prog_done_pulse = (prog_done_nb     && !id_ex_reg.branch && !(ex_mem_reg.branch && branch_taken))
                           || (id_ex_reg.prog_end && !id_ex_reg.branch && !(ex_mem_reg.branch && branch_taken))
                           || (ex_mem_reg.prog_end && ex_mem_reg.branch);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)               prog_done_held <= 1'b0;
        else if (prog_done_pulse) prog_done_held <= 1'b1;
    end

    assign prog_done = prog_done_pulse | prog_done_held;
    assign actual_pc_en    = pc_en    && ~halt_gate && ~halt_branch_gate && ~prog_end_seen;
    assign actual_if_id_en = if_id_en && ~halt_gate && ~halt_branch_gate && ~prog_end_seen;

endmodule
