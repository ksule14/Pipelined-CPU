import codes_pkg::DATA_WIDTH;
import codes_pkg::WORD_WIDTH;
module cache #(parameter INDEX_BITS = 4)
(
    // pipeline signals
    input logic clk,
    input logic rst_n,
    input logic [WORD_WIDTH-1:0] addr,
    input logic [DATA_WIDTH-1:0] write_data,
    input logic read_en,
    input logic write_en,
    output logic cache_stall,

    // memory interface signals
    output logic [DATA_WIDTH-1:0] read_data,
   
   cache_ram.cache mem_bus
);
    localparam ENTRIES = 2**INDEX_BITS;
    localparam TAG_BITS = WORD_WIDTH - INDEX_BITS - 2;

    //cache storage

    logic [DATA_WIDTH-1:0] cache_data [0:ENTRIES-1];
    logic [TAG_BITS-1:0] cache_tag [0:ENTRIES-1];
    logic cache_valid [0:ENTRIES-1];

    logic [INDEX_BITS-1:0] index;
    logic [TAG_BITS-1:0] tag;

    assign index = addr[INDEX_BITS+1:2];
    assign tag = addr[WORD_WIDTH-1:INDEX_BITS+2];

    //hit detection
    logic hit;
    assign hit = cache_valid[index] && (cache_tag[index] == tag);

    //FSM states

    typedef enum logic {
        IDLE, FETCH_MEMORY
    } state_t;

    state_t state;

    assign read_data = cache_data[index];

    assign mem_bus.mem_address = addr;
    assign mem_bus.mem_read_en  = (state == FETCH_MEMORY);
    assign mem_bus.mem_write_en = (state == IDLE) && write_en;
    assign cache_stall = (state != IDLE) || (read_en && !hit);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            for(int i=0; i<ENTRIES; i++) begin
                cache_valid[i] <=0;
            end
        end
            else begin
                case(state)
                    IDLE: begin
                        if (read_en && !hit) begin
                            state <= FETCH_MEMORY;
                        end
                        else if (write_en) begin
                            cache_data[index] <= write_data;
                            cache_tag[index] <= tag;
                            cache_valid[index] <= 1;
                        end
                    end
                    FETCH_MEMORY: begin
                        if(mem_bus.mem_ready) begin
                            cache_data[index] <= mem_bus.mem_read_data;
                            cache_tag[index] <= tag;
                            cache_valid[index] <= 1;
                            state <= IDLE;
                        end
                    end
                endcase
            end
    end
endmodule
   




    





