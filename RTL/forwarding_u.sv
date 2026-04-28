// forwarding unit detects read-after-write data hazards and selects the most recent value for each alu operand
// by forwarding results from later pipeline stages back to EX, bypassing the register file. Prevents stalls in most cases
// except in load-use hazards, where it defers to the stalling unit
module forwarding_u #(parameter REG_WIDTH = 5) (
    // IDs of the registers currently in EX stage that could require forwarded data
    input logic [REG_WIDTH-1:0] ex_rs1,
    input logic [REG_WIDTH-1:0] ex_rs2,

    // IDs of destination registers currently in MEM stage (1 ahead of EX) and WB stage (2 ahead of EX)
    input logic [REG_WIDTH-1:0] rd_mem,
    input logic [REG_WIDTH-1:0] rd_wb,

    // high when MEM-stage instruction actually writes a register.
    // Prevents forwarding when MEM instruction isn't a producer (store/branch).
    input logic reg_write_mem,

    // same purpose but for WB stage
    input logic reg_write_wb,

    // High when MEM stage instruction is load. Load result comes uot of data memory at the end of MEM stage
    // cannot be forwarded at EX/MEM boundary because it is not ready yet.
    input logic ex_mem_is_load,

    // Forwarding select encoding:
    // 2'b00 = use register file value
    // 2'b10 = forward from EX/MEM
    // 2'b01 = forward from MEM/WB
    output logic[1:0] forward_a, // mux select for rs1 fed into ALU
    output logic[1:0] forward_b // mux select for rs2 fed into ALU
);

    always_comb begin
        forward_a = 2'b00;
        forward_b = 2'b00;

        // EX/MEM has priority over WB for newest-data wins,
        // except loads, which must be taken from MEM/WB.
        
        // forwarding unit cannot forward load-use hazards in the MEM stage because the data is not ready.
        // This means the pipeline must stall in this instance. Forwarding unit treats load-use hazard in WB stage
        // as a read-after-write hazard because the data can simply be forwarded as it is sitting in the WB register
        if (reg_write_mem && !ex_mem_is_load && (rd_mem != '0) && (rd_mem == ex_rs1)) begin
            forward_a = 2'b10; 
        end else if (reg_write_wb && (rd_wb != '0) && (rd_wb == ex_rs1)) begin
            forward_a = 2'b01;
        end

        if (reg_write_mem && !ex_mem_is_load && (rd_mem != '0) && (rd_mem == ex_rs2)) begin
            forward_b = 2'b10;
        end else if (reg_write_wb && (rd_wb != '0) && (rd_wb == ex_rs2)) begin
            forward_b = 2'b01;
        end
    end
endmodule