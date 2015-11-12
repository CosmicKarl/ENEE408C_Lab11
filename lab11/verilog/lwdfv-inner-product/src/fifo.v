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
* Name: fifo module
* Description: LWDF-V fifo module 
* Sub modules: None
* Input ports: wr_en: write enable for the fifo 
*              rd_en: read enable for the fifo
*              data_in: data for writing into the fifo
* Output ports: data_out: data that is read out of the fifo
*               population: number of tokens in the fifo
*               capacity: maximum number of tokens that can coexist in the fifo
                          (determined by the buffer_size parameter)
* Regs & wires: rd_addr: fifo read address (read pointer)
*               wr_addr: fifo write address (write pointer)
* Parameters: buffer_size: max. number of tokens that can coexist in the fifo
*             width: bit width of each token
******************************************************************************/

`timescale 1ns / 1ns

module fifo #(parameter buffer_size = 5, width = 6)
(
    input clk, rst,
    input wr_en, rd_en,
    input[width - 1 : 0] data_in,
    output reg [log2(buffer_size) - 1 : 0] population,
    output reg [log2(buffer_size) - 1 : 0] capacity,
    output [width - 1 : 0] data_out     
);
    reg [width - 1 : 0] FIFO_RAM [0 : buffer_size - 1];
    reg [log2(buffer_size) - 1 : 0] rd_addr, wr_addr;
        
    wire[1:0] pop_control = {wr_en, rd_en};
    assign data_out = FIFO_RAM[rd_addr];
    
    integer i;
        
    always @(posedge clk)
    begin 
        if(!rst)
        begin
            rd_addr <= 0;
            wr_addr <= 0;
            population <= 0;
            capacity <= buffer_size;            
        end
        else
        begin
            if(wr_en)
            begin 
                FIFO_RAM[wr_addr] <= data_in;
                wr_addr <= (wr_addr != buffer_size - 1) ? wr_addr + 1 : 0;
            end
            
            if(rd_en)
                rd_addr <= (rd_addr != buffer_size - 1) ? rd_addr + 1 : 0;
            
            case (pop_control)
            2'b00 : 
            begin 
                population <= population;
                capacity <= capacity;
            end
            2'b01 : 
            begin 
                population <= population - 1;
                capacity <= capacity + 1;
            end
            2'b10 : 
            begin 
                population <= population + 1;
                capacity <= capacity - 1;
            end    
            2'b11 : 
            begin 
                population <= population;
                capacity <= capacity;
            end
            default:
            begin 
                population <= population;
                capacity <= capacity;
            end
            endcase
        end    
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
