module stalling_u #(parameter REG_WIDTH = 5) (
	// IF/ID stage register sources from current decode instruction
	input logic [REG_WIDTH-1:0] if_id_rs1,
	input logic [REG_WIDTH-1:0] if_id_rs2,
	input logic                 if_id_is_branch,

	// ID/EX stage destination/control (instruction ahead of decode)
	input logic                 id_ex_mem_read,
	input logic [REG_WIDTH-1:0] id_ex_rd,

	// EX/MEM stage destination/control (optional branch source stall)
	input logic                 ex_mem_reg_write,
	input logic [REG_WIDTH-1:0] ex_mem_rd,

	// Control hazard input (branch/jump resolved as taken)
	input logic                 ex_branch_taken,

	// Stall/flush outputs
	output logic                pc_en,
	output logic                if_id_en,
	output logic                id_ex_flush,
	output logic                if_id_flush,
	output logic                stall
);

	logic load_use_hazard;
	logic branch_src_hazard;

	always_comb begin
		// Canonical load-use hazard: value from a load in EX is needed by instr in ID.
		load_use_hazard = id_ex_mem_read && (id_ex_rd != '0) &&
						  ((id_ex_rd == if_id_rs1) || (id_ex_rd == if_id_rs2));

		// Optional branch-source hazard: branch compare in ID depends on result in EX/MEM.
		// Keep this if your branch decision uses register values in ID.
		branch_src_hazard = if_id_is_branch && ex_mem_reg_write && (ex_mem_rd != '0) &&
							((ex_mem_rd == if_id_rs1) || (ex_mem_rd == if_id_rs2));

		stall = load_use_hazard || branch_src_hazard;

		// On stall: freeze fetch/decode and inject bubble into EX.
		pc_en      = ~stall;
		if_id_en   = ~stall;
		id_ex_flush = stall;

		// On taken control transfer: squash next wrong-path instruction in IF/ID.
		if_id_flush = ex_branch_taken;
	end

endmodule
