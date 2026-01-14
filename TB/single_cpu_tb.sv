`timescale 1ns / 1ps
import codes_pkg::*;

module single_cpu_tb;
    // Testbench signals
    logic clk;
    logic rst_n;

    // Instantiated single_cpu module

    single_cpu dut (
        .clk(clk),
        .rst_n(rst_n)
    );


endmodule