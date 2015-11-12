library verilog;
use verilog.vl_types.all;
entity accumulator_mode_FSM_3 is
    generic(
        size            : integer := 3;
        width           : integer := 10
    );
    port(
        clk             : in     vl_logic;
        rst             : in     vl_logic;
        start_in        : in     vl_logic;
        ram_out1        : in     vl_logic_vector;
        ram_out2        : in     vl_logic_vector;
        done_out        : out    vl_logic;
        rd_en           : out    vl_logic;
        rd_addr         : out    vl_logic_vector;
        acc             : out    vl_logic_vector
    );
end accumulator_mode_FSM_3;
