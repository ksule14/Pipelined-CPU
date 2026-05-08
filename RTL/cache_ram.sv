import codes_pkg::WORD_WIDTH;
import codes_pkg::DATA_WIDTH;

// interface is used for communication between the cache and ram
interface cache_ram;
    logic [WORD_WIDTH-1:0] mem_address; // PC address of instruction
    logic mem_read_en; // read enable for ram
    logic mem_write_en; // write enable for ram
    logic [DATA_WIDTH-1:0] mem_read_data; // data from ram
    logic mem_ready; // read from RAM is ready to be copied into cache
    logic mem_write_done; // from ram. High when write to ram is done

    // signals relationship to cache
    modport cache (
        input mem_read_data,
        input mem_ready,
        input mem_write_done,

        output mem_address,
        output mem_read_en,
        output mem_write_en
    );
    // signals relationship to ram
    modport ram (
        input mem_address,
        input mem_read_en,
        input mem_write_en,

        output mem_read_data,
        output mem_ready,
        output mem_write_done
    );
endinterface
