// stalling unit stalls the pipeline for hazards that cannot be avoided with forwarding
// these hazards are: load-use and cache miss
module stalling_u #(parameter REG_WIDTH = 5) (
	// IF/ID stage register sources from current decode instruction
	input logic [REG_WIDTH-1:0] if_id_rs1,
	input logic [REG_WIDTH-1:0] if_id_rs2,

	// ID/EX stage signals
	input logic                 id_ex_mem_load, // high if the instruction in EX is load
	input logic [REG_WIDTH-1:0] id_ex_rd, // destination register of instruction in EX

	input logic                 pc_redirect, // high when bp was wrong and PC must jump to correct target

	// Cache miss stall input
	input logic                 mem_stall, // high if there is a cache miss

	// UART FIFO full stall input
	input logic                 uart_stall, // high when SW targets UART addr and FIFO is full

	// Stall/flush outputs
	output logic                pc_en, // normally freezes pc during stall, but lets PC redirect even mid-stall
									   // so correct branch is captured immediately
	output logic                if_id_en, // freezes IF/ID during any stall
	output logic                id_ex_en, // freezes ID/EX only on cache miss. Stays enabled on load-use so bubble can be inserted
	output logic                id_ex_flush, // clears ID/EX to inject bubble on load-use hazard. not high on mem stall because data is still valid

	output logic                ex_mem_en, // freezes EX/MEM during cache miss
	output logic                mem_wb_en, // freezes MEM/WB during cache miss
	output logic                stall // high during cache miss or load-use hazard
);

	logic load_use_hazard;
	logic pipe_freeze; // any stall that requires the full pipeline to hold (no flushes)

	always_comb begin
		// load use hazard is when the EX/MEM instruction is load and ID/EX instruction writes the same register
		load_use_hazard = id_ex_mem_load && (id_ex_rd != '0) &&
						  ((id_ex_rd == if_id_rs1) || (id_ex_rd == if_id_rs2));

		pipe_freeze = mem_stall || uart_stall;
		stall = load_use_hazard || pipe_freeze;

		// On any stall: freeze fetch/decode
		pc_en      = pc_redirect || ~stall;
		if_id_en   = ~stall;
		id_ex_flush = load_use_hazard && !pipe_freeze;
		// On cache miss or UART FIFO full: freeze entire pipeline (hold all registers, no flushes)
		// On load-use:   only freeze fetch/decode, flush ID/EX to insert bubble
		id_ex_en   = ~pipe_freeze;
		ex_mem_en  = ~pipe_freeze;
		mem_wb_en  = ~pipe_freeze;

	end
endmodule
