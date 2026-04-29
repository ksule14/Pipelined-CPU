// Cache is a smaller memory than RAM but it is much faster and used to avoid the delay
// of accessing RAM every time there is a load instruction
// cache-ram utlilizes write-through logic where both are written on write instructions
import codes_pkg::DATA_WIDTH;
import codes_pkg::WORD_WIDTH;
module cache #(parameter INDEX_BITS = 4) // 4 bits are used for cache addresses
(
    input logic clk, // clock
    input logic rst_n, // active-low reset
    input logic [WORD_WIDTH-1:0] addr, // PC address of instruction, split into index and tag bits
    input logic [DATA_WIDTH-1:0] write_data, // data to be written to cache and ram
    input logic read_en, // read enable that trigges cache lookup
    input logic write_en, // write enable that triggers write-through
    output logic cache_stall, // high when cache is busy or during mem fetch. Sent to stalling unit to stall pipeline

    // memory interface signals
    output logic [DATA_WIDTH-1:0] read_data, // data read from cache. Valid at cache hit or after mem fetch
    output logic                  error, // high when memory access is not word aligned

    cache_ram.cache mem_bus // interface struct connecting cache to RAM
);
    localparam ENTRIES = 2**INDEX_BITS; // 2^4 = 16 entries in cache
    localparam TAG_BITS = WORD_WIDTH - INDEX_BITS - 2; // 32-4-2 = 26 tag bits used to distinguish between addresses that have same index
                                                       // -2 is to discard bits 0 and 1 which are 00 due to word alignment

    //cache storage
    logic [DATA_WIDTH-1:0] cache_data [0:ENTRIES-1]; // cache is 16 entries, 32 bits each. Stores actual data
    logic [TAG_BITS-1:0] cache_tag [0:ENTRIES-1]; // tag storage is 16 entries, 26 bits each
    logic cache_valid [0:ENTRIES-1]; // 16 single bits. Stores 16 validity flags. 1 means valid data, 0 means invalid data.

    logic [INDEX_BITS-1:0] index;
    logic [TAG_BITS-1:0] tag;

    assign index = addr[INDEX_BITS+1:2]; // bits [5:2] of addr. selcts cache location
    assign tag = addr[WORD_WIDTH-1:INDEX_BITS+2]; // bits [31:6] of addr. Identifies memory location

    //hit detection
    logic hit;
    assign hit = cache_valid[index] && (cache_tag[index] == tag); // cache holds correct data if data is valid and tag from addr = tag from cache storage

    //FSM states
    typedef enum logic {
        IDLE, FETCH_MEMORY
    } state_t;

    state_t state;

    assign read_data = cache_data[index]; // outputted data is from cache at appropriate index
    assign error     = (read_en || write_en) && (addr[1:0] != 2'b00); // unaligned data access

    assign mem_bus.mem_address = addr; // pc address sent to ram
    assign mem_bus.mem_read_en  = (state == FETCH_MEMORY); // read enable for ram high if memory fetch from ram is necessary
    assign mem_bus.mem_write_en = (state == IDLE) && write_en; // write enable for ram high if cache state is idle and cache write enable is high
    assign cache_stall = (state != IDLE) || (read_en && !hit) || (mem_bus.mem_write_done == 0 && write_en); // pipeline stalls on 3 instances:
                                                                                                            // 1. mem fetch
                                                                                                            // 2. read enable is high and cache miss
                                                                                                            // 3. mem write is not done and write enable is high
    always_ff @(posedge clk or negedge rst_n) begin
        // reset makes all cache values invalid
        if (!rst_n) begin
            state <= IDLE;
            for(int i=0; i<ENTRIES; i++) begin
                cache_valid[i] <=0;
            end
        end
            else begin
                case(state)
                    IDLE: begin
                        if (read_en && !hit) begin // fetch data from ram during cache miss
                            state <= FETCH_MEMORY;
                        end
                        else if (write_en) begin // write to cache and overwrite data that is in same index location.
                            cache_data[index] <= write_data; // data and tag replace what was there originally, even if it was different instruction.
                            cache_tag[index] <= tag;
                            cache_valid[index] <= 1;
                        end
                    end
                    FETCH_MEMORY: begin
                        if(mem_bus.mem_ready) begin // copy data from ram into cache
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
   




    





