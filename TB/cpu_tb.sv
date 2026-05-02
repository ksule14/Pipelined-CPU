`timescale 1ns/1ps

module cpu_tb.sv;
    import codes_pkg::*;
    import branch_fsm_pkg::*;
    import pipeline_pkg::*;

    logic clk;
    logic rst_n;
    logic error;
    logic prog_done;

    cpu_top dut(
        .clk(clk),
        .rst_n(rst_n),
        .error(error),
        .prog_done(prog_done)
    );