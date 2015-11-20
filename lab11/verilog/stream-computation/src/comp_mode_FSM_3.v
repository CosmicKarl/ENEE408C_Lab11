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
This FSM implements the core computational mode for the stream_comp.
*******************************************************************************/

/*******************************************************************************
*  Parameters:      A. size -- the number of tokens (integers) in each
*                   input vector. So, if size = N
*   
*                   B. width -- the bit width for the integer data type
*                   used in the inner product operations
*******************************************************************************/
`timescale 1ns/1ps

module comp_mode_FSM_3
        #(parameter width = 10)(  
        input clk, rst,
        input start_in,
        input [width - 1 : 0] command_in, length_in, data_in,
        output [width-1:0] state_out,
        output reg done_out,
        output reg rd_en,
        output [width - 1 : 0] rd_addr,
        output reg [width - 1 : 0] out);

    localparam MIN = 2'b00, MAX = 2'b01, SUM = 2'b10;
  

	wire rd_en_wire, done_out_wire;
	wire [width - 1 : 0] module_out;
	reg en_min, en_max, en_sum;
	reg [1 : 0] state, next_state;
    reg [width - 1 : 0] counter, next_counter, prev_command;

	always @(posedge clk)
    begin
        if (!rst)
        begin 
	        counter <= 0;
        end
        else
        begin 
            state <= next_state;
	        counter <= next_counter;
        end
    end 
  
	sum_comp #(.width(width))
		_sum_comp(clk, rst, en_sum, length_in, data_in, done_out_wire, rd_en_wire,
		rd_addr, module_out);

	min_comp #(.width(width))
		_min_comp(clk, rst, en_min, length_in, data_in, done_out_wire, rd_en_wire,
		rd_addr, module_out);

	max_comp #(.width(width))
		_max_comp(clk, rst, en_max, length_in, data_in, done_out_wire, rd_en_wire,
		rd_addr, module_out);

	/*Connect sub module outs to fsm2*/
    assign rd_addr = counter;
    assign state_out = counter;
	
	always @(posedge clk)
	begin
		out <= module_out;
		rd_en <= rd_en_wire;
		done_out <= done_out_wire;
	end
	

	/*Choose what what module is enabled to read from data*/
    always @(state, start_in, command_in,  data_in)
    begin
        case(command_in)
			MIN:
			begin
				en_min <= 1;
				en_max <= 0;
				en_sum <= 0;
			end

			MAX:
			begin 
				en_min <= 0;
				en_max <= 1;
				en_sum <= 0;
			end

			SUM:
			begin
				en_min <= 0;
				en_max <= 0;
				en_sum <= 1;		
			end
			
			default:
			begin 
				en_min <= 0;
				en_max <= 0;
				en_sum <= 0;		
			end
        endcase
    end

endmodule    
  
