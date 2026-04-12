`timescale 1ns/1ps

module branch_calc_tb;
    import codes_pkg::DATA_WIDTH;
    import codes_pkg::WORD_WIDTH;

    logic [WORD_WIDTH-1:0] pc;
    logic [DATA_WIDTH-1:0] imm;
    logic [WORD_WIDTH1:0] branch_addr;

    branch_calc dut (
        .pc(pc),
        .imm(imm),
        .branch_addr(branch_addr)
    );

    initial begin
        // Backward branch
        pc = 32'h0000_0010; // 16
        imm = 32'hFFFFFFF8; // -8
        #1;
        assert(branch_addr == 32'h0000_0008) else $fatal("Test 1 failed: expected 0x0000_0008, got %h", branch_addr);

        // Forward branch
        pc = 32'h0000_0010; // 16
        imm = 32'h0000_0008; // 8
        #1;
        assert(branch_addr == 32'h0000_0018) else $fatal("Test 2 failed: expected 0x0000_0018, got %h", branch_addr);
    end
endmodule

