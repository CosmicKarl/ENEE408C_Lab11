library verilog;
use verilog.vl_types.all;
entity innner_product_enable is
    generic(
        size            : integer := 3;
        buffer_size     : integer := 5;
        buffer_size_out : integer := 1
    );
    port(
        rst             : in     vl_logic;
        pop_in_fifo1    : in     vl_logic_vector;
        pop_in_fifo2    : in     vl_logic_vector;
        cap_out_fifo1   : in     vl_logic_vector;
        mode            : in     vl_logic_vector(1 downto 0);
        enable          : out    vl_logic
    );
end innner_product_enable;
