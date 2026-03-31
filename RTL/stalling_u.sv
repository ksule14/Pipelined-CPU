module stalling_u #(parameter REG_WIDTH = 5) (
	// IF/ID stage register sources from current decode instruction
	input logic [REG_WIDTH-1:0] if_id_rs1,
	input logic [REG_WIDTH-1:0] if_id_rs2,

	// ID/EX stage destination/control (instruction ahead of decode)
	input logic                 id_ex_mem_load,
	input logic [REG_WIDTH-1:0] id_ex_rd,

	// Control hazard input (branch/jump resolved as taken)
	input logic                 ex_branch_taken,

	// Cache miss stall input
	input logic                 mem_stall,

	// Stall/flush outputs
	output logic                pc_en,
	output logic                if_id_en,
	output logic                id_ex_en,
	output logic                id_ex_flush,
	output logic                if_id_flush,
	output logic                ex_mem_en,
	output logic                mem_wb_en,
	output logic                stall
);

	logic load_use_hazard;

	always_comb begin
		// Canonical load-use hazard: value from a load in EX is needed by instr in ID.
		load_use_hazard = id_ex_mem_load && (id_ex_rd != '0) &&
						  ((id_ex_rd == if_id_rs1) || (id_ex_rd == if_id_rs2));

		stall = load_use_hazard || mem_stall;

		// On any stall: freeze fetch/decode
		pc_en      = ~stall;
		if_id_en   = ~stall;

		// On cache miss: freeze entire pipeline (hold all registers, no flushes)
		// On load-use:   only freeze fetch/decode, flush ID/EX to insert bubble
		id_ex_en   = ~mem_stall;
		id_ex_flush = (load_use_hazard && !mem_stall) || ex_branch_taken;
		ex_mem_en  = ~mem_stall;
		mem_wb_en  = ~mem_stall;

		// On taken control transfer: squash next wrong-path instruction in IF/ID.
		if_id_flush = ex_branch_taken;
	end

endmodule
