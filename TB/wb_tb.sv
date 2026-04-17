`timescale 1ns/1ps

module wb_tb;
    import codes_pkg::DATA_WIDTH;

    logic                  mem_to_reg;
    rand logic [DATA_WIDTH-1:0] alu_data;
    rand logic [DATA_WIDTH-1:0] mem_data;
    logic [DATA_WIDTH-1:0] wb_data;

    write_back dut (
        .mem_to_reg(mem_to_reg),
        .alu_data(alu_data),
        .mem_data(mem_data),
        .wb_data(wb_data)
    );

    initial begin
        wb_alu();
        wb_mem()
        $display("All tests passed!");
        $finish;
    end

    task automatic wb_alu();
        mem_to_reg = 0;
        repeat(100) begin
            assert(alu_data.randomize()) else $fatal("randomization failed");
            assert(mem_data.randomize()) else $fatal("randomization failed");
            #1;
            assert(wb_data == alu_data) else $fatal("wb does not equal alu_data. should be %0h, got %0h", wb_data, alu_data);
        end
    endtask

    task automatic wb_mem();
        mem_to_reg = 1;
        repeat(100) begin
            assert(alu_data.randomize()) else $fatal("randomization failed");
            assert(mem_data.randomize()) else $fatal("randomization failed");
            #1;
            assert(wb_data == mem_data) else $fatal("wb does not equal mem_data. should be %0h, got %0h", wb_data, mem_data);
        end
    endtask
endmodule


    
        
