import codes_pkg::DATA_WIDTH;

class reg_trans;
    // Random inputs
    rand bit reg_write;
    rand bit mem_to_reg;
    rand bit [4:0] rs1;
    rand bit [4:0] rs2;
    rand bit [4:0] rd;
    rand bit [DATA_WIDTH-1:0] rd_data;
    rand bit [DATA_WIDTH-1:0] mem_data;

    // Outputs
    bit [DATA_WIDTH-1:0] rs1_data;
    bit [DATA_WIDTH-1:0] rs2_data;

    // Internal register file
    bit [DATA_WIDTH-1:0] regs [0:31];

    constraint used_regs { 0 < rs1 < 4; 0 < rs2 < 4; }
    constraint valid_rd { 4 < rd < 32; }
endclass

class golden_model;
    function void reg_data(const ref reg_trans trans);
        if (trans.reg_write) begin
            if (trans.mem_to_reg) begin
                trans.regs[trans.rd] = trans.mem_data;
            end else begin
                trans.regs[trans.rd] = trans.rd_data;
            end
        end
        trans.rs1_data = trans.regs[trans.rs1];
        trans.rs2_data = trans.regs[trans.rs2];
    endfunction
endclass

class scoreboard;
    // Compare DUT outputs with golden model
    function void compare(const ref reg_trans actual, const ref reg_trans expected);
        if (actual.rs1_data !== expected.rs1_data) begin
            $error("Mismatch in rs1_data: actual=%0h, expected=%0h", actual.rs1_data, expected.rs1_data);
        end
        if (actual.rs2_data !== expected.rs2_data) begin
            $error("Mismatch in rs2_data: actual=%0h, expected=%0h", actual.rs2_data, expected.rs2_data);
        end
    endfunction
endclass

module reg_file_tb;
    // Instantiate classes
    reg_trans actual, expected;
    golden_model gm;
    scoreboard sb;
    // Testbench signals
    bit clk;
    bit reg_write;
    bit mem_to_reg;
    bit [4:0] rs1;
    bit [4:0] rs2;
    bit [4:0] rd;
    bit [DATA_WIDTH-1:0] rd_data;
    bit [DATA_WIDTH-1:0] mem_data;
    bit [DATA_WIDTH-1:0] rs1_data;
    bit [DATA_WIDTH-1:0] rs2_data;

    bit [DATA_WIDTH-1:0] regs[0:31];

    // Instantiate the DUT
    reg_file dut(
        .clk(clk),
        .reg_write(reg_write),
        .mem_to_reg(mem_to_reg),
        .rs1_addr(rs1),
        .rs2_addr(rs2),
        .rd_addr(rd),
        .rd_data(rd_data),
        .mem_data(mem_data),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    always #5 clk = ~clk;
  
    initial begin
        // Initialize signals
        clk = 0;
        reg_write = 0;
        mem_to_reg = 0;
        rs1 = 0;
        rs2 = 0;
        rd = 0;
        rd_data = 0;
        mem_data = 0;

        gm = new();
        sb = new();

        // Initialize register file and internal DUT registers
        for(int i = 1; i < 4; i++) begin
            regs[i] = i;
        end

        for (int i = 1; i < 4; i++) begin
            dut.regs[i] = i;
        end

        @(posedge clk);

        repeat (100) begin
            actual = new();
            assert(actual.randomize()) else $fatal("Randomization failed");
            
            // Apply randomized inputs to DUT
            reg_write = actual.reg_write;
            mem_to_reg = actual.mem_to_reg;
            rs1 = actual.rs1;
            rs2 = actual.rs2;
            rd = actual.rd;
            rd_data = actual.rd_data;
            mem_data = actual.mem_data;

            expected = new();
            expected.regs = actual.regs;

            // Wait for a clock edge
            @(posedge clk);
            #1;



    end
endmodule