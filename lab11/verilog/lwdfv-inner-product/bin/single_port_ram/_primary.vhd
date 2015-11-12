library verilog;
use verilog.vl_types.all;
entity single_port_ram is
    generic(
        size            : integer := 3;
        width           : integer := 10
    );
    port(
        data            : in     vl_logic_vector;
        addr            : in     vl_logic_vector;
        rd_addr         : in     vl_logic_vector;
        wr_en           : in     vl_logic;
        re_en           : in     vl_logic;
        clk             : in     vl_logic;
        q               : out    vl_logic_vector
    );
end single_port_ram;
