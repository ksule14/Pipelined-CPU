import codes_pkg::DATA_WIDTH;
import codes_pkg::WORD_WIDTH;
import branch_fsm_pkg::*;

// 2-bit dynamic branch predictor combined with a branch target buffer (BTB).
// The PHT predicts direction (taken/not-taken); the BTB remembers each branch's
// resolved target address so a correctly-predicted-taken branch can redirect
// fetch immediately instead of waiting ~3 cycles for the branch to resolve in
// EX/MEM. Works best when instructions are repeated.
module branch_predictor #(
    parameter INDEX_BITS = 4 // 4 bits used to identify instructions in PHT/BTB
)
(
    input logic clk, // clock
    input logic rst_n, // active-low reset

    input logic [DATA_WIDTH-1:0] pc_fetch, // current instruction in fetch stage. Needs to be predicted.
    output logic predict_taken, // direction prediction for the current instruction being fetched
    output logic [DATA_WIDTH-1:0] predict_target, // BTB's remembered target address for pc_fetch
    output logic btb_hit, // high when the BTB entry at this index is valid AND tagged for this exact pc_fetch

    input logic update_en, // high when a branch instruction resolves
    input logic [DATA_WIDTH-1:0] update_pc, // PC of resolved branch instruction
    input logic actual_taken, // the actual outcome of the branch
    input logic [DATA_WIDTH-1:0] update_target // the resolved branch's actual target address (pc + imm)
);

    localparam ENTRIES = 2 ** INDEX_BITS; // 2^4 = 16 entries
    localparam TAG_BITS = DATA_WIDTH - INDEX_BITS - 2; // remaining PC bits above the index, same scheme as cache.sv

    branch_state PHT [0:ENTRIES-1]; // 16-entry, 4 state Pattern History Table where each unit holds 2 bit state
    // important note: PHT can hold at most 16 instructions, so if there are more than 16 instructions or branch
    // instructions have the same index bits, one will be overwritten and the prediction data lost.

    // BTB storage: remembers the target address of the last branch resolved at
    // each index, tagged with the upper PC bits so a tag mismatch (aliasing
    // with a different, unrelated instruction at this index) is detected
    // rather than trusted. This tag is what makes it safe to act on the
    // prediction immediately at fetch time, before decode even confirms the
    // fetched instruction is a branch: an untagged hit could wrongly redirect
    // fetch off of a non-branch instruction that merely aliases some other
    // branch's index.
    logic [DATA_WIDTH-1:0] btb_target [0:ENTRIES-1];
    logic [TAG_BITS-1:0]   btb_tag    [0:ENTRIES-1];
    logic                  btb_valid  [0:ENTRIES-1];

    logic [INDEX_BITS-1:0] fetch_index;
    logic [INDEX_BITS-1:0] update_index;
    logic [TAG_BITS-1:0]   fetch_tag;

    assign fetch_index = pc_fetch[INDEX_BITS+1:2]; // bits 5-2 (ignore 1 and 0 for word alignment) of fetch instruction
    assign update_index = update_pc[INDEX_BITS+1:2]; // bits 5-2 of resolved branch instruction
    assign fetch_tag = pc_fetch[DATA_WIDTH-1:INDEX_BITS+2]; // remaining upper bits of fetch instruction's PC

    // branch predictor supplies prediction immediately to the instruction in the fetch stage
    always_comb begin
        case(PHT[fetch_index])
            STRONG_NOT_TAKEN, WEAK_NOT_TAKEN: predict_taken = 1'b0; // branch not taken for weak/strong not taken predictions
            WEAK_TAKEN, STRONG_TAKEN: predict_taken = 1'b1; // branch taken for weak/strong taken predictions
            default: predict_taken = 1'b0; // default to not taken
        endcase
    end

    assign predict_target = btb_target[fetch_index];
    assign btb_hit         = btb_valid[fetch_index] && (btb_tag[fetch_index] == fetch_tag);

    // synchronous update- state transitions
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i=0; i<ENTRIES; i++) begin
                PHT[i] <= WEAK_NOT_TAKEN; // reset to weak not taken prediction
                btb_valid[i] <= 1'b0; // BTB entries start invalid; tag/target are don't-care until then
            end
        end
            else if (update_en) begin // only when an insruction resolves
            // update logic for branch prediction based on result of resolved branch
                case (PHT[update_index])
                    STRONG_NOT_TAKEN: PHT[update_index] <= actual_taken ? WEAK_NOT_TAKEN : STRONG_NOT_TAKEN;
                    WEAK_NOT_TAKEN:   PHT[update_index] <= actual_taken ? WEAK_TAKEN     : STRONG_NOT_TAKEN;
                    WEAK_TAKEN:       PHT[update_index] <= actual_taken ? STRONG_TAKEN   : WEAK_NOT_TAKEN;
                    STRONG_TAKEN:     PHT[update_index] <= actual_taken ? STRONG_TAKEN   : WEAK_TAKEN;
                    default:          PHT[update_index] <= WEAK_NOT_TAKEN;
                endcase

                // learn this branch's target unconditionally (even if not taken this
                // time) so the very next time it IS predicted taken, the BTB already
                // has a validated entry ready to redirect fetch immediately.
                btb_target[update_index] <= update_target;
                btb_tag[update_index]    <= update_pc[DATA_WIDTH-1:INDEX_BITS+2];
                btb_valid[update_index]  <= 1'b1;
            end
    end
endmodule
