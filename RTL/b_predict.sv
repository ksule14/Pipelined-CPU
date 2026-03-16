import codes_pkg::DATA_WIDTH;
import branch_fsm_pkg::*;

module branch_predictor #(
    parameter INDEX_BITS = 4 // 2^4 = 16 entries
)
(
    input logic clk,
    input logic rst_n,

    // read port- prediction at fetch time
    input logic [DATA_WIDTH-1:0] pc_fetch,
    output logic predict_taken,

    // write port- update at branch resolve
    input logic update_en,
    input logic [DATA_WIDTH-1:0] update_pc,
    input logic actual_taken
);

    localparam ENTRIES = 2 ** INDEX_BITS;

    branch_state PHT [0:ENTRIES-1]; // Pattern History Table

    logic [INDEX_BITS-1:0] fetch_index;
    logic [INDEX_BITS-1:0] update_index;
    
    assign fetch_index = fetch_pc[INDEX_BITS+1:2];
    assign update_index = update_pc[INDEX_BITS+1:2]

    // combinational read- predict based on current state
    always_comb begin
        case(PHT[fetch_index])
            STRONG_NOT_TAKEN, WEAK_NOT_TAKEN: predict_taken = 1'b0;
            WEAK_TAKEN, STRONG_TAKEN: predict_taken = 1'b1;
            default: predict_taken = 1'b0;
        endcase
    end

    // synchronous update- state transitions
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i=0; i<ENTRIES; i++) begin
                PHT[i] <= WEAK_NOT_TAKEN;
            end
        end
            else if (update_en) begin
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

        





