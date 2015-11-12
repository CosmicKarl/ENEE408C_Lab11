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

/*******************************************************************************
This FSM implements a nested FSM for mode 1 of the inner product actor.
*******************************************************************************/

/*******************************************************************************
*  Parameters:      A. size -- the number of tokens (integers) in each
*                   input vector. So, if size = N, then this actor
*                   performs an N x N inner product.
*                   B. width -- the bit width for the integer data type
*                   used in the inner product operations
*******************************************************************************/
`timescale 1ns/1ps

module load_loc_mem_FSM_3
        #(parameter size = 3, width = 10)(  
        input clk, rst,
        input start_in,
        input [width - 1 : 0] data_in_fifo1, data_in_fifo2,
        output reg rd_in_fifo1, rd_in_fifo2,
        output reg done_out,
        output reg wr_en,
        output reg [log2(size) - 1 : 0] wr_addr,
        output reg [width - 1 : 0] data_out_one,
        output reg [width - 1 : 0] data_out_two);

    localparam START = 2'b00, STATE0 = 2'b01, STATE1 = 2'b10, END = 2'b11;
  
    reg [1 : 0] state, next_state;
    reg [width - 1 : 0] temp_reg_one, temp_reg_two, next_temp_reg_one, 
            next_temp_reg_two;
    reg [log2(size) - 1 : 0] counter, next_counter;
  
    always @(posedge clk)
    begin
        if (!rst)
        begin 
            state <= START;
            counter <= 0;
	          temp_reg_one <= 0;
       	    temp_reg_two <= 0;
        end
        else
        begin 
            state <= next_state;
            counter <= next_counter;
            temp_reg_one <= next_temp_reg_one;
            temp_reg_two <= next_temp_reg_two;
        end
    end

    always @(state, start_in, counter)
    begin 
        case (state)
        START:
	      begin 
            wr_en <= 0;
            done_out <= 0;
            next_counter <= 0;
            rd_in_fifo1 <= 0;
            rd_in_fifo2 <= 0;
            wr_addr <= 0;
            if (start_in)
                next_state <= STATE0;
            else
                next_state <= START;		    
        end
        STATE0:
        begin 
            wr_en <= 0;
            rd_in_fifo1 <= 1;
            rd_in_fifo2 <= 1;
            next_temp_reg_one <= data_in_fifo1;
            next_temp_reg_two <= data_in_fifo2;
            next_state <= STATE1;
        end
        STATE1:
        begin 
            next_counter <= counter + 1;
            wr_en <= 1;
            rd_in_fifo1 <= 0;
            rd_in_fifo2 <= 0;
            wr_addr <= counter;
            data_out_one <= temp_reg_one;
            data_out_two <= temp_reg_two;
            if (counter == (size - 1))
                next_state <= END;
            else
                next_state <= STATE0;
        end
        END:
        begin 
            done_out <= 1;
            next_counter <= 0;
            wr_en <= 0;
            next_state <= START;
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
  
