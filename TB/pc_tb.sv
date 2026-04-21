`timescale 1ns/1ps

module pc_tb;
import codes_pkg::WORD_WIDTH;

    logic                  clk;
    logic                  rst_n;
    logic                  pc_en;
    logic                  pc_redirect;
    logic [WORD_WIDTH-1:0] pc_branch;
    logic [WORD_WIDTH-1:0] pc_current;

    pc pc_dut (
        .clk(clk),
        .rst_n(rst_n),
        .pc_en(pc_en),
        .pc_redirect(pc_redirect),
        .pc_branch(pc_branch),
        .pc_current(pc_current)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end

    initial begin
        reset();
        pc_plus4();
        pc_enable_test();
        pc_redirect_test();

        $display("pc_tb: all checks passed");
        $finish;
    end

    task automatic reset();
        rst_n = 0;
        #20;
        @(posedge clk);
        assert(pc_current == 0) else $fatal("Reset failed");
        rst_n = 1;
    endtask

    task automatic pc_plus4();
        logic [WORD_WIDTH-1:0] old_pc;

        old_pc = pc_current;
        pc_en = 1;
        pc_redirect = 0;
        @(posedge clk); #1;
        assert(pc_current == old_pc + 4)
            else $fatal("PC did not increment by 4: old=%0h new=%0h", old_pc, pc_current);
    endtask

    task automatic pc_enable_test();
        logic [WORD_WIDTH-1:0] old_pc;

        old_pc = pc_current;
        pc_en = 0;
        pc_redirect = 0;
        repeat (2) begin
            @(posedge clk); #1;
            assert(pc_current == old_pc)
                else $fatal("PC changed when enable was low: old=%0h new=%0h", old_pc, pc_current);
        end
    endtask

    task automatic pc_redirect_test();
        logic [WORD_WIDTH-1:0] old_pc;

        // Redirect should load the branch target when enabled
        pc_branch = WORD_WIDTH'(32'h0000_0040);
        old_pc = pc_current;
        pc_en = 1;
        pc_redirect = 1;
        @(posedge clk); #1;
        assert(pc_current == pc_branch)
            else $fatal("PC did not redirect to branch: expected=%0h, got=%0h", pc_branch, pc_current);

        // Redirect must not change PC when enable is low
        old_pc = pc_current;
        pc_branch = WORD_WIDTH'(32'h0000_0080);
        pc_en = 0;
        pc_redirect = 1;
        @(posedge clk); #1;
        assert(pc_current == old_pc)
            else $fatal("PC changed on redirect while enable was low: old=%0h new=%0h", old_pc, pc_current);
    endtask

endmodule