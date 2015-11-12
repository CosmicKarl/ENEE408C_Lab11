library verilog;
use verilog.vl_types.all;
entity inner_product_invoke_top_module_1 is
    generic(
        size            : integer := 3;
        width           : integer := 10
    );
    port(
        clk             : in     vl_logic;
        rst             : in     vl_logic;
        data_in_fifo1   : in     vl_logic_vector;
        data_in_fifo2   : in     vl_logic_vector;
        invoke          : in     vl_logic;
        next_mode_in    : in     vl_logic_vector(1 downto 0);
        rd_in_fifo1     : out    vl_logic;
        rd_in_fifo2     : out    vl_logic;
        next_mode_out   : out    vl_logic_vector(1 downto 0);
        FC              : out    vl_logic;
        wr_out_fifo1    : out    vl_logic;
        data_out        : out    vl_logic_vector
    );
end inner_product_invoke_top_module_1;
