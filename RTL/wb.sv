import codes_pkg::DATA_WIDTH;

module write_back (
    input  logic                  mem_to_reg,
    input  logic [DATA_WIDTH-1:0] alu_data,
    input  logic [DATA_WIDTH-1:0] mem_data,
    output logic [DATA_WIDTH-1:0] wb_data
);
    assign wb_data = mem_to_reg ? mem_data : alu_data;
endmodule
