`timescale 1ns/1ps

module reg_file_tb;
import codes_pkg::DATA_WIDTH;

    logic                  clk;
    logic                  reg_write;
    logic [4:0]            rs1_addr;
    logic [4:0]            rs2_addr;
    logic [4:0]            rd_addr;
    logic [DATA_WIDTH-1:0] write_data;
    logic [DATA_WIDTH-1:0] rs1_data;
    logic [DATA_WIDTH-1:0] rs2_data;

    reg_file dut(
        .clk(clk),
        .reg_write(reg_write),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rd_addr(rd_addr),
        .write_data(write_data),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    always #5 clk = ~clk;

    task automatic write_read_reg1();
        // Write to register 1 and read it back
        reg_write = 1;
        rd_addr = 'd1;
        write_data = 'h17459AC4;
        @(posedge clk);
        reg_write = 0;

        // Read from register 1
        rs1_addr = 'd1;
        #1;
        assert(rs1_data == 'h17459AC4) else $fatal("Test failed: Expected 0x17459AC4, got %h", rs1_data);
    endtask

    task automatic write_read_reg31();
        // Write to register 31 and read it back
        reg_write = 1;
        rd_addr = 'd31;
        write_data = 'hDECDBEAF;
        @(posedge clk);
        reg_write = 0;

        // Read from register 31
        rs1_addr = 'd31;
        #1;
        assert(rs1_data == 'hDECDBEAF) else $fatal("Test failed: Expected 0xDECDBEAF, got %h", rs1_data);
    endtask

    task automatic write_zero_reg();
        // Attempt to write to register 0 and read it back
        reg_write = 1;
        rd_addr = 'd0;
        write_data = 'hFFFFFFFF;
        @(posedge clk);
        reg_write = 0;

        // Read from register 0
        rs1_addr = 'd0;
        #1;
        assert(rs1_data == 'h00000000) else $fatal("Test failed: Expected 0x00000000, got %h", rs1_data);
    endtask

    task automatic write_read_same_reg();
        // Test combinational write-through forwarding before clock edge commits the write
        reg_write = 1;
        rd_addr = 'd2;
        write_data = 'hCAFE3475;
        rs1_addr = 'd2;
        #1;
        assert(rs1_data == 'hCAFE3475) else $fatal("Test failed: Expected 0xCAFE3475, got %h", rs1_data);
        @(posedge clk);
        reg_write = 0;
    endtask

    task automatic reg_write0();
        // Test that when reg_write is 0, no write occurs
        reg_write = 0;
        rd_addr = 'd2;
        write_data = 'h12345678;
        @(posedge clk);
        // Read from register 2
        rs2_addr = 'd2;
        #1;
        assert(rs2_data == 'hCAFE3475) else $fatal("Test failed: Expected 0xCAFE3475, got %h", rs2_data);
    endtask

    initial begin
        clk = 0;
        write_read_reg1();
        write_read_reg31();
        write_zero_reg();
        write_read_same_reg();
        reg_write0();

        $display("ALL TESTS PASSED!");
        $finish;
    end
endmodule
        

