// Word width is defined in codes_pkg,currently set to 32 bits
import codes_pkg::WORD_WIDTH;

// Program counter increments by 4 every clock cycle
// It's purpose is to point to the next instruction in the instruction memory
module pc (
    // clock to synchronize the pc updates
    input  logic                  clk,
    // active low reset to initialize the pc to 0
    input  logic                  rst_n,
    // pc enable signal. When high, the pc will update to the next value on the next clock edge
    // when low, the pc will hold its current value
    input  logic                  pc_en,
    // pc redirect signal. When high, the pc will update to the branch target address instead of incrementing by 4
    input  logic                  pc_redirect,
    // pc_bracnh is the target address for a branch instruction. It is used when pc_redirect is high to update the pc to the branch target address
    input  logic [WORD_WIDTH-1:0] pc_branch,
    // pc_current is the current value of the program counter and the address of the isntruction to be fetched from the instruction memory.
    output logic [WORD_WIDTH-1:0] pc_current
); 
    logic [WORD_WIDTH-1:0] pc_next;
    // pc next is the next value of the pc. If pc_redirect is high it takes the branch value, otherwise it increments the current pc by 4
    assign pc_next = pc_redirect ? pc_branch : (pc_current + 4);

    // signals update on low reset or rising edge of clock.
    always_ff @(posedge clk or negedge rst_n) begin
        // if reset is active low, set pc to 0. Otherwise, if pc enable is high, update pc to the next value
        if (!rst_n)       pc_current <= '0;
        else if (pc_en)   pc_current <= pc_next;
    end
endmodule
