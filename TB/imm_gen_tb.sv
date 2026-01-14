`timescale 1ns / 1ps
import codes_pkg::*;

module imm_gen_tb;
    // Testbench signals
    logic [WORD_WIDTH-1:0] instruction;
    logic [DATA_WIDTH-1:0] immediate;

    imm_gen dut(
        .instruction(instruction),
        .sign_extended_imm(immediate)
    );

    // Test procedure
    initial begin
        // Test ADDI
        instruction = 32'h00A58513;
        #0;
        assert(immediate === 64'h0000_0000_0000_000A) else $error("ADDI test failed");

        instruction = 32'hFF628293;
        #0;
        assert(immediate === 64'hFFFF_FFFF_FFFF_FFF6) else $error("ADDI test failed");

        instruction = 32'h12330313;
        #0;
        assert(immediate === 64'h0000_0000_0000_0123) else $error("ADDI test failed");

        instruction = 32'h80040413;
        #0;
        assert(immediate === 64'hFFFF_FFFF_FFFF_F800) else $error("ADDI test failed");

        instruction = 32'h7FF70793;
        #0;
        assert(immediate === 64'h0000_0000_0000_07FF) else $error("ADDI test failed");
        $display("Finished addi tests.");

        // Test LOAD
        instruction = 32'h0002A303;
        #0;
        assert(immediate === 64'h0000_0000_0000_0000) else $error("LOAD test failed");

        instruction = 32'hFFF30383;
        #0;
        assert(immediate === 64'hFFFF_FFFF_FFFF_FFFF) else $error("LOAD test failed");

        $display("Finished load tests.");

        // Test STORE
        instruction = 32'h00A5A023;
        #0;
        assert(immediate === 64'h0000_0000_0000_0000) else $error("STORE test failed");

        instruction = 32'hFEA5AE23;
        #0;
        assert(immediate === 64'hFFFF_FFFF_FFFF_FFFC) else $error("STORE test failed");
        $display("Finished store tests.");

        // Test BEQ
        instruction = 32'h00000263;
        #0;
        assert(immediate === 64'h0000_0000_0000_0004) else $error("BEQ test failed");

        instruction = 32'h00208463;
        #0;
        assert(immediate === 64'h0000_0000_0000_0008) else $error("BEQ test failed");
        $display("Finished beq tests.");
        $finish;
    end
endmodule