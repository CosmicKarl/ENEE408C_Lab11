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
* Name: inner product enable module
* Description: enable module for inner product actor, this actor has three
*              modes (MODE_ONE, MODE_TWO, MODE_THREE)
* Sub modules: None
* Input ports: pop_in_fifo1 - population of input fifo1
*              pop_in_fifo2 - population of input fifo2 
*              cap_out_fifo1 - capacity of output fifo1
*              mode - inner product actor mode for checking enable condition
* Output port: enable (active high)
*
* Refer to the corresponding invoke module (invoke_top_module_1.v) for 
* documentation about the actor modes and their production and consumption 
* rates.
******************************************************************************/

`timescale 1ns / 1ps
module stream_comp_enable
        #(parameter size = 3, buffer_size = 5, buffer_size_out = 1, width = 10)(
        input rst,
        input [log2(buffer_size) - 1 : 0] pop_in_command_fifo,
        input [log2(buffer_size) - 1 : 0] pop_in_length_fifo,
        input [log2(buffer_size) - 1 : 0] pop_in_data_fifo,
        input [log2(buffer_size_out) - 1 : 0] cap_out_fifo1,
        input [1 : 0] mode,
        input [width - 1 : 0] length,
        output reg enable);
  
    localparam MODE_ONE = 2'b00, MODE_TWO = 2'b01, MODE_THREE = 2'b10, MODE_FOUR = 2'b11;
  
    reg [1 : 0] state_mode;
    reg [1 : 0] next_state_mode;
 
    always @(mode, pop_in_command_fifo, pop_in_length_fifo, pop_in_data_fifo, cap_out_fifo1)
    begin 
        $display("in enable: pop in command: %d", pop_in_command_fifo); 
        case (mode)
        MODE_ONE:
        begin

            if (pop_in_command_fifo >= 1 && pop_in_length_fifo >= 1)
                enable <= 1;
            else
                enable <= 0;
        end
        MODE_TWO:
        begin
            if (pop_in_data_fifo >= length)
                enable <= 1;
            else 
                enable <= 0;
                        
        end
        MODE_THREE:
        begin
            //if (cap_out_fifo1 >= 1)
            // For some reason, this was not an accurate representation of the population in the out fifo!!
            enable <= 1;
        end
        default:
        begin 
            enable <= 0;
        end    
        // MODE_THREE:
        // begin
        //     enable <= 1;
        // end
        // MODE_FOUR:
        // begin 
        //     if (cap_out_fifo1 >= 1)
        //         enable <= 1;
        // end
        // default:
        // begin 
        //     enable <= 0;
        // end
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
