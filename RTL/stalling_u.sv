module stalling_u #(parameter REG_WIDTH = 5) (
	// IF/ID stage register sources from current decode instruction
	input logic [REG_WIDTH-1:0] if_id_rs1,
	input logic [REG_WIDTH-1:0] if_id_rs2,

	// ID/EX stage destination/control (instruction ahead of decode)
	input logic                 id_ex_mem_read,
	input logic [REG_WIDTH-1:0] id_ex_rd,

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

	always_comb begin
		// Canonical load-use hazard: value from a load in EX is needed by instr in ID.
		load_use_hazard = id_ex_mem_read && (id_ex_rd != '0) &&
						  ((id_ex_rd == if_id_rs1) || (id_ex_rd == if_id_rs2));

		// Branch compare in EX means forwarding should handle branch ALU sources;
		// stalling is only required for classic load-use cases.
		stall = load_use_hazard;

		// On stall: freeze fetch/decode and inject bubble into EX.
		pc_en      = ~stall;
		if_id_en   = ~stall;
		// Also flush ID/EX on taken branch to squash the younger instruction in ID.
		id_ex_flush = stall || ex_branch_taken;

		// On taken control transfer: squash next wrong-path instruction in IF/ID.
		if_id_flush = ex_branch_taken;
	end

endmodule
