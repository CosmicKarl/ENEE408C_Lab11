/*******************************************************************************
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
* Name        : tb_inner_product_FSM
* Description : testbench for inner_product actor
* Sub modules : Two input fifos, one output fifos, inner_product invoke/enable
*               modules
******************************************************************************/

/*******************************************************************************
*  Parameters     : A. size -- the numer of tokens (integers) in each
*                   input vector. So, if size = N, then this actor
*                   performs an N x N inner product.
*                   B. width -- the bit width for the integer data type
*                   used in the inner product operations
*******************************************************************************/

`timescale 1ns/1ps
module tb_stream_compute();

    parameter buffer_size = 5, width = 10, buffer_size_out = 1;
    parameter MODE_ONE = 2'b00, MODE_TWO = 2'b01, MODE_THREE = 2'b10;

    /* Input vector size for the inner product. */
  
    reg clk, rst; 
    reg start_in;
	reg [width - 1:0] data_in, length_in;
	wire [width - 1:0] rd_addr;
	wire done_out;
	wire rd_en;
	wire [width - 1:0] out;
    
    /* Input memories for inner product. */
    reg [width - 1 : 0] data_mem [0 : buffer_size - 1];

	min_comp #(.size(buffer_size), .width(width))
		_min_comp (clk, rst, start_in, length_in, data_in, 
		done_out, rd_en, rd_addr, out); 
  

		
    integer i, j, k;
    integer descr;

    /***************************************************************************
    Generate the clock waveform for the test.
    The clock period is 2 time units.
    ***************************************************************************/
    initial 
    begin
        clk <= 0;
        for(j = 0; j < 50; j = j + 1)
        begin 
            #1 clk <= 1;
            #1 clk <= 0;
        end
    end
 

	initial
	begin
        /* Set up a file to store the test output */
        descr = $fopen("out.txt");
        
        /* Read text files and load the data into memory for input of inner 
        product actor
        */
        $readmemh("data_mem.txt", data_mem);

        #1;
		rst <= 0;
		length_in <= 0;
		data_in <= 0;
		
    
        #2 rst <= 1;
		
		$fdisplay(descr, "Start Reading in data");
		
		#2
		
		start_in <= 1;
		length_in <= 5;
		
		
		#4

	    data_in <= data_mem[rd_addr];
		$fdisplay(descr, "data: %d, rd_addr: %d", 
				data_in, rd_addr);

		while(rd_en == 1 && done_out == 0)
        begin 
               #2; 
               data_in <= data_mem[rd_addr];
               $fdisplay(descr, "input[%d] = %d | out = %d", rd_addr, data_in,
					out);
        end
		$fdisplay(descr, "out: %d", out);
	end
endmodule
