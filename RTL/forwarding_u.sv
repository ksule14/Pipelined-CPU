
module forwarding_u #(parameter REG_WIDTH = 5) (
    // Source registers for instruction currently in EX.
    input logic [REG_WIDTH-1:0] ex_rs1,
    input logic [REG_WIDTH-1:0] ex_rs2,

    // Destination registers of older instructions in MEM and WB.
    input logic [REG_WIDTH-1:0] rd_mem,
    input logic [REG_WIDTH-1:0] rd_wb,

    // Write intent for MEM/WB producers.
    input logic reg_write_mem,

    // High when MEM-stage producer is a load (data not ready for EX/MEM bypass).
    input logic ex_mem_is_load,
    input logic reg_write_wb,

    // Forwarding select encoding:
    // 2'b00 = use register file value
    // 2'b10 = forward from EX/MEM
    // 2'b01 = forward from MEM/WB
    output logic[1:0] forward_a,
    output logic[1:0] forward_b
);

    always_comb begin
        forward_a = 2'b00;
        forward_b = 2'b00;

        // EX/MEM has priority over WB for newest-data wins,
        // except loads, which must be taken from MEM/WB.
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