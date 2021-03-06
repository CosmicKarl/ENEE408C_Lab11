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
module tb_inner_product_FSM();

    parameter buffer_size = 5, width = 10, buffer_size_out = 1;
    parameter MODE_ONE = 2'b00, MODE_TWO = 2'b01, MODE_THREE = 2'b10;

    /* Input vector size for the inner product. */
    parameter size = 4;
  
    reg clk, rst; 
    reg invoke;
    reg wr_en_input, rd_en_input;
    reg [width - 1:0] data_in_one, data_in_two;
    reg [1 : 0]  next_mode_in;
    reg rd_en_fifo1;
    
    /* Input memories for inner product. */
    reg [width - 1 : 0] mem_one [0 : size - 1];
    reg [width - 1 : 0] mem_two [0 : size - 1];
  
    wire [1:0] next_mode_out;  
    wire [width - 1 : 0] data_in_fifo1, data_in_fifo2, data_out, data_out_fifo1;
    wire [log2(buffer_size) - 1:0] pop_in_fifo1, pop_in_fifo2;
    wire [log2(buffer_size_out) - 1 : 0] pop_out_fifo1;
    wire [log2(buffer_size) - 1 : 0] capacity_fifo1, capacity_fifo2;
    wire [log2(buffer_size_out) - 1 : 0] cap_out_fifo1;
    wire FC; 
 
    integer i, j, k;

    /***************************************************************************
    Instantiate the input and output FIFOs for the actor under test.
    ***************************************************************************/

    fifo #(buffer_size, width) 
            in_fifo1 
            (clk, rst, wr_en_input, rd_in_fifo1, data_in_one, 
            pop_in_fifo1, capacity_fifo1, data_in_fifo1);

    fifo #(buffer_size, width) in_fifo2 
            (clk, rst, wr_en_input, rd_in_fifo2, data_in_two, 
            pop_in_fifo2, capacity_fifo2, data_in_fifo2);

    fifo #(buffer_size_out, width) out_fifo1 
            (clk, rst, wr_out_fifo1, rd_en_fifo1, data_out, 
            pop_out_fifo1, cap_out_fifo1, data_out_fifo1);

    /***************************************************************************
    Instantiate the enable and invoke modules for the actor under test.
    ***************************************************************************/

    inner_product_invoke_top_module_1 #(.size(size), .width(width)) 
            invoke_module(clk, rst, 
            data_in_fifo1, data_in_fifo2, invoke, next_mode_in,
            rd_in_fifo1, rd_in_fifo2, next_mode_out, FC, wr_out_fifo1, 
            data_out);
  
    innner_product_enable #(.size(size), .buffer_size(buffer_size), 
            .buffer_size_out(buffer_size_out)) enable_module(rst, pop_in_fifo1, 
            pop_in_fifo2, cap_out_fifo1, next_mode_in, enable);    

    integer descr;

    /***************************************************************************
    Generate the clock waveform for the test.
    The clock period is 2 time units.
    ***************************************************************************/
    initial 
    begin
        clk <= 0;
        for(j = 0; j < 100; j = j + 1)
        begin 
            #1 clk <= 1;
            #1 clk <= 0;
        end
    end
 
    /***************************************************************************
    Try to carry out three actor firings (to cycle through the three
    CFDF modes of the actor under test).
    ***************************************************************************/
    initial 
    begin 
        /* Set up a file to store the test output */
        descr = $fopen("out.txt");
        
        /* Read text files and load the data into memory for input of inner 
        product actor
        */
        $readmemh("mem_one.txt", mem_one);
        $readmemh("mem_two.txt", mem_two);

        #1;
        rst <= 0;
        wr_en_input <= 0;
        rd_en_input <= 0;
        data_in_one <= 0;
        data_in_two <= 0;
    
        #2 rst <= 1;
        #2; 
    
        /* Write data into the input FIFOs. The FIFO requires a write enable
         * signal before the data is loaded, so "size" loop intereation are 
         * required here.
         */

        $fdisplay(descr, "Setting up input FIFOs");
        for (i = 0; i < size; i = i + 1)
        begin 
               #2; 
               data_in_one <= mem_one[i];
               data_in_two <= mem_two[i];
               #2;
               wr_en_input <= 1;
               $fdisplay(descr, "input1[%d] = %d", i, data_in_one);
               $fdisplay(descr, "input2[%d] = %d", i, data_in_two);
               #2;
               wr_en_input  <= 0;
        end
 
        #2;     /* ensure that data is stored into memory before continuing */
        next_mode_in <= MODE_ONE;
        #2;
        if (enable)
        begin
            $fdisplay(descr, "Executing firing for mode no. 1");
            invoke <= 1;
        end
        else  
        begin
            /* end the simulation here if we don't have enough data to fire */
            $fdisplay (descr, "Not enough data to fire the actor under test");
            $finish;
        end
        #2 invoke <= 0;

        /* Wait for mode 1 to complete */ 
        wait (FC) #2 next_mode_in <= MODE_TWO;
        #2;
        if (enable)
        begin
            $fdisplay(descr, "Executing firing for mode no. 2");
            invoke <= 1;
        end 
        else 
        begin 
            /* end the simulation here if we don't have enough data to fire */
            $fdisplay (descr, "Not enough data to fire the actor under test");
            $finish;
        end
        #2 invoke <= 0;
        
        /* Wait for mode 2 to complete */ 
        wait(FC) #2 next_mode_in <= MODE_THREE;
        #2;
        if (enable)
        begin
            $fdisplay(descr, "Executing firing for mode no. 3");
            invoke <= 1;
        end 
        else 
        begin 
            /* end the simulation here if we don't have enough data to fire */
            $fdisplay (descr, "Not enough data to fire the actor under test");
            $finish;
        end
        #2 invoke <= 0;
        
        /* Wait for mode 3 to complete */ 
        wait(FC) #2;
        #2/* Read actor output value from result FIFO */
        rd_en_fifo1 <= 1;        
               
        #2;
        /* Set up recording of results */
        $fdisplay(descr, "time = %d, FIFO[0] = %d", $time, out_fifo1.FIFO_RAM[0]);
        $fdisplay(descr, "time = %d, Result = %d", $time, data_out_fifo1);
        $display("time = %d, Result = %d", $time, data_out_fifo1);               
    end
 
    function integer log2;
    input [31:0] value;
    begin
        value = value - 1;
        for (log2 = 0; value > 0; log2 = log2 + 1) begin
            value = value >> 1;
        end
    end
    endfunction 
  
endmodule


