import codes_pkg::WORD_WIDTH;
import codes_pkg::DATA_WIDTH;

interface cache_ram;
    logic [WORD_WIDTH-1:0] mem_address;
    logic mem_read_en;
    logic mem_write_en;
    logic [DATA_WIDTH-1:0] mem_read_data;
    logic mem_ready;
    logic mem_write_done;

    modport cache (
        input mem_read_data,
        input mem_ready,
        input mem_write_done,

        output mem_address,
        output mem_read_en,
        output mem_write_en
    );

    modport ram (
        input mem_address,
        input mem_read_en,
        input mem_write_en,

        output mem_read_data,
        output mem_ready,
        output mem_write_done
    );
endinterface
