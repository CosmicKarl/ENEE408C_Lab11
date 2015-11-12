library verilog;
use verilog.vl_types.all;
entity fifo is
    generic(
        buffer_size     : integer := 5;
        width           : integer := 6
    );
    port(
        clk             : in     vl_logic;
        rst             : in     vl_logic;
        wr_en           : in     vl_logic;
        rd_en           : in     vl_logic;
        data_in         : in     vl_logic_vector;
        population      : out    vl_logic_vector;
        capacity        : out    vl_logic_vector;
        data_out        : out    vl_logic_vector
    );
end fifo;
