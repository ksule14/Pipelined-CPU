`timescale 1ns/1ps

module forwarding_tb;
    parameter REG_WIDTH = 5;
    
    // Source registers for instruction currently in EX
    logic [REG_WIDTH-1:0] ex_rs1;
    logic [REG_WIDTH-1:0] ex_rs2;

    // Destination registers of older instructions in MEM and WB
    logic [REG_WIDTH-1:0] rd_mem;
    logic [REG_WIDTH-1:0] rd_wb;

    // write intent for MEM/WB producers
    logic reg_write_mem;

    // High when MEM-stage produce is load (data not ready for EX/MEM bypass)
    logic ex_mem_is_load;
    logic reg_write_wb;

    // Forwarding select encoding:
    // 2'b00 = use register file value
    // 2b'10 = forweard from EX/MEM
    // 2b'01 = forward from MEM/WB
    logic [1:0] forward_a;
    logic [1:0] forward_b;

    forwarding_u #(.REG_WIDTH(REG_WIDTH)) dut (
        .ex_rs1(ex_rs1),
        .ex_rs2(ex_rs2),
        .rd_mem(rd_mem),
        .rd_wb(rd_wb),
        .reg_write_mem(reg_write_mem),
        .ex_mem_is_load(ex_mem_is_load),
        .reg_write_wb(reg_write_wb),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    