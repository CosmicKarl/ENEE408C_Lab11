library verilog;
use verilog.vl_types.all;
entity load_loc_mem_FSM_3 is
    generic(
        size            : integer := 3;
        width           : integer := 10
    );
    port(
        clk             : in     vl_logic;
        rst             : in     vl_logic;
        start_in        : in     vl_logic;
        data_in_fifo1   : in     vl_logic_vector;
        data_in_fifo2   : in     vl_logic_vector;
        rd_in_fifo1     : out    vl_logic;
        rd_in_fifo2     : out    vl_logic;
        done_out        : out    vl_logic;
        wr_en           : out    vl_logic;
        wr_addr         : out    vl_logic_vector;
        data_out_one    : out    vl_logic_vector;
        data_out_two    : out    vl_logic_vector
    );
end load_loc_mem_FSM_3;
