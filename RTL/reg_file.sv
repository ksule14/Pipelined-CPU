// Data width is 32 bits defined in codes package
import codes_pkg::DATA_WIDTH;

// register file with 32 registers, each of DATA_WIDTH (32) bits.
// registers can be written or read and are the fastest type of memory in the system
module reg_file (
    // clock for synchronous writes
    input logic clk,
    // control signal to enable writing to the register file
    input logic reg_write,
    // addresses for source registers (rs1 and rs2) on reads and destination register (rd) on writes
    input logic [4:0] rs1_addr,
    input logic [4:0] rs2_addr,
    input logic [4:0] rd_addr,
    // data to be written to the register file on a write
    input logic [DATA_WIDTH-1:0] write_data,
    // data outputs from the source registers (rs1 and rs2) for reads
    output logic [DATA_WIDTH-1:0] rs1_data,
    output logic [DATA_WIDTH-1:0] rs2_data
);
    // 32 registers of DATA_WIDTH bits each, indexed from 0 to 31
    logic [DATA_WIDTH-1:0] regs [0:31];

    always_comb begin // combination reads from the register file to avoid read-after-write hazards
        // register x0 is hardwired to zero, so if the address is 0, output 0; otherwise, output the value from the register file
        // this ensures that reads from x0 always return 0, regardless of any writes to it
        // also takes less time than actually reading from the reigster file, which is important for performance
        // if read register is not x0, value is fetched from the register file
        rs1_data = (rs1_addr == 5'd0) ? '0 : regs[rs1_addr];
        rs2_data = (rs2_addr == 5'd0) ? '0 : regs[rs2_addr];

        // read-after-write hazard handling:
        // if current instruction is writing to a register that is also being read, forward the write
        // data directly from the write_data input instead of waiting for next clock cycle
        // improves performance by avoiding stalls
        if (reg_write && (rd_addr != 5'd0)) begin
            if (rd_addr == rs1_addr) rs1_data = write_data;
            if (rd_addr == rs2_addr) rs2_data = write_data;
        end
    end

    // synchronous writes to the register file on rising edge of clock
    always_ff @(posedge clk) begin
        // register xo hardwired to zero, so ignore any writes to it
        regs[5'd0] <= '0;

        // if reg_write is high and destination register is not x0, write the data to the register file at the specified address
        if (reg_write && (rd_addr != 5'd0)) begin
            regs[rd_addr] <= write_data;
        end
    end
endmodule

