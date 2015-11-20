/******************************************************************************
@ddblock_begin copyright

Copyright (c) 1999-2013
Maryland DSPCAD Research Group, The University of Maryland at College Park 

Permission is hereby granted, without written agreement and without
license or royalty fees, to use, copy, modify, and distribute this
software and its documentation for any purpose, provided that the above
copyright notice and the following two paragraphs appear in all copies
of this software.

IN NO EVENT SHALL THE UNIVERSITY OF MARYLAND BE LIABLE TO ANY PARTY
FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF
THE UNIVERSITY OF MARYLAND HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGE.

THE UNIVERSITY OF MARYLAND SPECIFICALLY DISCLAIMS ANY WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE
PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
MARYLAND HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
ENHANCEMENTS, OR MODIFICATIONS.

@ddblock_end copyright
******************************************************************************/

/******************************************************************************
* Name            : Inner product invoke firing state FSM level 2
* Description     : A level 2 FSM. This FSM helps to implement the firing state 
*                   of the invoke module for the inner product actor 
*
* FSM description : STATE_START - nested FSM start state
*
*                   STATE_MODE_ONE_START - nested FSM for mode 1 start state
*                   
*                   STATE_MODE_ONE_WAIT - execute CFDF mode 1 for the inner 
*                   product actor (read input vectors in to local actor 
*                   memory). This state has two sub-states associated with 
*                   executing a nested FSM.
*                                    
*                   STATE_MODE_TWO_START - nested FSM for mode 2 start state
*
*                   STATE_MODE_TWO_WAIT - execute CFDF mode 2 for the inner 
*                   product actor (computer the inner product from local 
*                   memory). This state has two sub-states associated with 
*                   executing a nested FSM.
*
*                   STATE_MODE_THREE - execute CFDF mode 3 for the inner
*                   product actor (write the inner product result to the
*                   the output FIFO.
*
*                   STATE_END - nested FSM end state.
*                              
* Input ports     : data_in_fifo1 - data from input fifo1
*                   data_in_fifo2 - data from input fifo2
*                   start_in - nested FSM start signal from parent FSM
*                   next_mode_in - selected actor mode
*
* Output ports    : rd_data_in_fifo - read enable signal for data imput
*                   rd_command_in_fifo - read enable signal for command imput
*                   rd_length_in_fifo - read enable signal for length imput
*                   next_mode_out - CFDF next mode output for actor firing
*                   done_out - nested FSM end signal to parent FSM
*                   wr_out_fifo1 - output fifo write enable signal
*                   data_out - output data for writing into output fifo
*
*  Parameters     : A. size -- the number of tokens (integers) in each
*                   input vector. So, if size = N, then this actor
*                   performs an N x N inner product.
*                   B. width -- the bit width for the integer data type
*                   used in the inner product operations

******************************************************************************/
`timescale 1ns/1ps

module firing_state_FSM2
        #(parameter width = 10)(
        input clk,rst,
        input [width - 1 : 0] data_in_fifo,
        input [width - 1 : 0] length_in_fifo, 
        input [width - 1 : 0] command_in_fifo,
        input start_in,
        input [1 : 0] next_mode_in,
        output [width-1 : 0] command_loc_mem_state,
        output [width-1 : 0] data_loc_mem_state,
        output [width-1 : 0] len_loc_mem_state,
        output rd_data_in_fifo,
        output rd_length_in_fifo,
        output rd_command_in_fifo,
        output [width - 1 : 0]length_out_again,
        output reg [1 : 0] next_mode_out,
        output reg done_out,
        output reg wr_out_fifo1,
        output reg [width - 1 : 0] result_out 
        );

    localparam MODE_ONE = 2'b00, MODE_TWO = 2'b01, MODE_THREE = 2'b10;
    localparam STATE_START = 3'b000, STATE_MODE_ONE_START = 3'b001, 
	        STATE_MODE_ONE_WAIT = 3'b010, STATE_MODE_TWO_START = 3'b011,
	        STATE_MODE_TWO_WAIT = 3'b100, STATE_MODE_TWO_WAIT_COMPUTE = 3'b101,
            STATE_MODE_THREE = 3'b110,
            STATE_END = 3'b111;

    reg [2 : 0] state_module, next_state_module;
    reg begin_read_command, begin_read_length, begin_read_data, begin_compute;
    reg wr_en;
    
    wire [width - 1 : 0] result;
    wire done_out_mode1, done_out_mode2;
    wire [width - 1 : 0] ram_out1, ram_out2, ram_out3;
    wire [width - 1 : 0] wr_addr, wr_addr_data, rd_addr;
    wire [width - 1 : 0] command_out, length_out, data_out;
    wire rd_en, rd_en_data;

    //reg [width-1:0] na;
    //reg [width-1:0] naa;


    //assign command_loc_mem_state = 0;
    //assign data_loc_mem_state = 0;
    assign len_loc_mem_state = ram_out3;
    /* 
     * Since we'll only be reading one value at a time, we can rest assured ram is always
     * at address 0
     */
    assign length_out_again = length_out;
        
    single_port_ram #(.width(width))
            RAM1(command_out, wr_addr, rd_addr, wr_en_ram, rd_en, clk, 
            ram_out1);
    single_port_ram #(.width(width))
            RAM2(length_out, wr_addr, rd_addr, wr_en_ram, rd_en, clk, 
            ram_out2);
    single_port_ram #(.width(width))
            RAM3(data_out, wr_addr_data, rd_addr, wr_en_ram_data, rd_en_data, clk, 
            ram_out3);

    /* Instantiation of nested FSM for core compuation CFDF mode 1. */	    
    load_loc_mem_FSM_3 #(.width(width))
            loc_mem_command(clk, rst, begin_read_command, 1, command_in_fifo, ,
            rd_command_in_fifo, read_from_command_done, 
            wr_en_ram, wr_addr, command_out);

    load_loc_mem_FSM_3 #(.width(width))
            loc_mem_length(clk, rst, begin_read_length, 1, length_in_fifo, ,
            rd_length_in_fifo, read_from_length_done, 
            wr_en_ram, wr_addr, length_out);

    load_loc_mem_FSM_3 #(.width(width))
            loc_mem_data(clk, rst, begin_read_data, length_out, data_in_fifo, data_loc_mem_state,
            rd_data_in_fifo, read_from_data_done, 
            wr_en_ram_data, wr_addr_data, data_out);

    /* Instantiation of nested FSM for core compuation CFDF mode 2. */
    comp_mode_FSM_3 #(.width(width)) accumulator(clk, rst, 
            begin_compute, command_out, length_out, ram_out3, 
            command_loc_mem_state,
            done_compute, 
            rd_en_data, rd_addr, result);
       
    always @(posedge clk)
    begin 
        if(!rst)
        begin
            state_module <= STATE_START;
        end
        else
        begin 
            state_module <= next_state_module;
        end
    end
       
    always @(state_module, start_in, result, read_from_command_done, 
            read_from_length_done, read_from_data_done, done_compute)
    begin 
        case (state_module)
        STATE_START:
        begin
            wr_out_fifo1 <= 0;
            begin_read_command <= 0;
            begin_read_length <= 0;
            begin_read_data <= 0;
            done_out <= 0;
            wr_en <= 0;
            if (start_in)
                if(next_mode_in == MODE_ONE)
                    next_state_module <= STATE_MODE_ONE_START;
                else if (next_mode_in == MODE_TWO)
                    next_state_module <= STATE_MODE_TWO_START;
                else if (next_mode_in == MODE_THREE)
                    next_state_module <= STATE_MODE_THREE;
                else
                    next_state_module <= STATE_START;    
            else
                next_state_module <= STATE_START;
        end

        /***********************************************************************
        CFDF firing mode: "mode one"
        -- Consumption rate is 1 for command FIFO.
        -- Production rate is 0 for the output FIFO.
        ***********************************************************************/
        STATE_MODE_ONE_START:
        /* This is a hierarchical state --- the core computaitonal mode */
        begin 
            begin_read_command <= 1;
            begin_read_length <= 1;
            next_state_module <= STATE_MODE_ONE_WAIT;
        end

        STATE_MODE_ONE_WAIT:
        begin
            /* Continue after nested FSM completes */
            begin_read_command <= 0;
            begin_read_length <= 0;
            if (read_from_command_done && read_from_length_done)
            begin
                next_state_module <= STATE_END;
            end
            else 
            begin
                next_state_module <= STATE_MODE_ONE_WAIT;
            end
        end

        /***********************************************************************
        CFDF firing mode: "mode two"
        -- Consumption rate is 0 for each input FIFO.
        -- Production rate is 0 for the output FIFO.
        This mode updates the internal state (accumulated inner product value)
        associated with the inner product.
        ***********************************************************************/
        STATE_MODE_TWO_START:
        begin
            begin_read_data <= 1;
            /* Configure and execute nested FSM */
            next_state_module <= STATE_MODE_TWO_WAIT;
        end
        STATE_MODE_TWO_WAIT:
        begin
            /* Continue after nested FSM completes */
            begin_read_data <= 0;
            if (read_from_data_done)
            begin
                begin_compute <= 1;
                next_state_module <= STATE_MODE_TWO_WAIT_COMPUTE;
            end
            else 
            begin
                next_state_module <= STATE_MODE_TWO_WAIT;
            end
        end


        STATE_MODE_TWO_WAIT_COMPUTE:
        begin
            begin_compute <= 0;
            if(done_compute)
            begin
                next_state_module <= STATE_END;
            end
            else 
            begin
                next_state_module <= STATE_MODE_TWO_WAIT_COMPUTE;
            end
        end

        /***********************************************************************
        CFDF firing mode: "mode three"
        -- Consumption rate is 0 for each input FIFO.
        -- Production rate is 1 for the output FIFO.
        ***********************************************************************/
        STATE_MODE_THREE:
        /* This is a leaf-level state (no nested FSM) */
        begin 
            wr_out_fifo1 <= 1;          
            result_out <= result;
            wr_en <= 0;
            next_state_module <= STATE_END;
        end
        STATE_END:
        /* This is a leaf-level state (no nested FSM) */
        begin 
            wr_out_fifo1 <= 0;          
            done_out <= 1;
            wr_en <= 0;
            next_state_module <= STATE_START;
        end
        default:
        begin 
            wr_out_fifo1 <= 0;          
            done_out <= 0;
            next_state_module <= STATE_START;
        end
        endcase
    end

    function integer log2;
    input [31 : 0] value;
    begin
        value = value - 1;
        for (log2 = 0; value > 0; log2 = log2 + 1) begin
            value = value >> 1;
        end
    end
    endfunction 

 endmodule               
               
