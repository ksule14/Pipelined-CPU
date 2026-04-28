import codes_pkg::DATA_WIDTH;
import branch_fsm_pkg::*;

// 2-bit dynamic branch predictor that predicts whether branch instructions will be taken or not
// Used to improve pipeline performance by approximating when branches will be taken
// Works best when instructions are repeated
module branch_predictor #(
    parameter INDEX_BITS = 4 // 4 bits used to identify instructions in PHT
)
(
    input logic clk, // clock
    input logic rst_n, // active-low reset

    input logic [DATA_WIDTH-1:0] pc_fetch, // current instruction in fetch stage. Needs to be predicted.
    output logic predict_taken, // prediction for the current instruction being fetched

    input logic update_en, // high when a branch instruction resolves
    input logic [DATA_WIDTH-1:0] update_pc, // PC of resolved branch instruction
    input logic actual_taken // the actual outcome of the branch
);

    localparam ENTRIES = 2 ** INDEX_BITS; // 2^4 = 16 entries

    branch_state PHT [0:ENTRIES-1]; // 16-entry, 4 state Pattern History Table where each unit holds 2 bit state
    // important note: PHT can hold at most 16 instructions, so if there are more than 16 instructions or branch
    // instructions have the same index bits, one will be overwritten and the prediction data lost.
    logic [INDEX_BITS-1:0] fetch_index;
    logic [INDEX_BITS-1:0] update_index;
    
    assign fetch_index = pc_fetch[INDEX_BITS+1:2]; // bits 5-2 (ignore 1 and 0 for word alignment) of fetch instruction
    assign update_index = update_pc[INDEX_BITS+1:2]; // bits 5-2 of resolved branch instruction

    // branch predictor supplies prediction immediately to the instruction in the fetch stage
    always_comb begin
        case(PHT[fetch_index])
            STRONG_NOT_TAKEN, WEAK_NOT_TAKEN: predict_taken = 1'b0; // branch not taken for weak/strong not taken predictions
            WEAK_TAKEN, STRONG_TAKEN: predict_taken = 1'b1; // branch taken for weak/strong taken predictions
            default: predict_taken = 1'b0; // default to not taken
        endcase
    end

    // synchronous update- state transitions
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i=0; i<ENTRIES; i++) begin
                PHT[i] <= WEAK_NOT_TAKEN; // reset to weak not taken prediction
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
            end
    end
endmodule

        





