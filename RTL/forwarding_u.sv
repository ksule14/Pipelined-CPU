
module forwarding_u #(parameter REG_WIDTH = 5) (
    input logic [REG_WIDTH-1:0] ex_rs1,
    input logic [REG_WIDTH-1:0] ex_rs2,
    input logic [REG_WIDTH-1:0] rd_mem,
    input logic [REG_WIDTH-1:0] rd_wb,
    input logic reg_write_mem,
    input logic reg_write_wb,
    output logic[1:0] forward_a,
    output logic[1:0] forward_b
);

    always_comb begin 
        if (reg_write_mem && (rd_mem != 0) && (rd_mem == ex_rs1)) begin // Forward for rs1 in MEM stage
            forward_a = 2'b10; 
        end
        else if (reg_write_wb && (rd_wb != 0) && (rd_wb == ex_rs1)) begin // Forward for rs1 in WB stage
            forward_a = 2'b01; 
        end else begin
            forward_a = 2'b00; // No forwarding
        end

        if (reg_write_mem && (rd_mem != 0) && (rd_mem == ex_rs2)) begin // Forward for rs2 in MEM stage
            forward_b = 2'b10;
        end
        else if (reg_write_wb && (rd_wb != 0) && (rd_wb == ex_rs2)) begin // Forward for rs2 in WB stage
            forward_b = 2'b01;
        end else begin
            forward_b = 2'b00; // No forwarding
        end
    end
endmodule