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

    parameter buffer_size = 10, width = 10, buffer_size_out = 1;
    parameter MODE_ONE = 2'b00, MODE_TWO = 2'b01, MODE_THREE = 2'b10;

    /* Input vector size for the inner product. */
    parameter size = 5;
  
    reg clk, rst; 
    reg invoke;
    reg wr_en_input, wr_en_input_data, rd_en_input;
    reg [width - 1:0] data_in, length_in, command_in;
    reg [1 : 0]  next_mode_in;
    reg rd_en_result_fifo;
    
    /* Input memories for inner product. */
    reg [width - 1 : 0] data_mem [0 : width - 1];
    reg [width - 1 : 0] length_mem [0 : width - 1];
    reg [width - 1 : 0] command_mem [0 : width - 1];
  

    wire [width-1 : 0] command_loc_mem_state;
    wire [width-1 : 0] data_loc_mem_state;
    wire [width-1 : 0] len_loc_mem_state;
    wire [1:0] next_mode_out;  
    wire [width - 1 : 0] data_in_fifo, length_in_fifo, command_in_fifo, result_out, result_out_fifo;
    wire [log2(buffer_size) - 1:0] pop_in_data_fifo, pop_in_length_fifo, pop_in_command_fifo;
    wire [log2(buffer_size_out) - 1 : 0] pop_in_result_fifo;
    wire [log2(buffer_size) - 1 : 0] capacity_data_fifo, capacity_length_fifo, capacity_command_fifo;
    wire [log2(buffer_size_out) - 1 : 0] capacity_result_fifo;
    wire FC; 
    wire [width - 1 : 0] length;
 
    integer i, j, k;

    /***************************************************************************
    Instantiate the input and output FIFOs for the actor under test.
    ***************************************************************************/

    fifo #(buffer_size, width) data_fifo
            (clk, rst, wr_en_input_data, rd_in_data_fifo, data_in, 
            pop_in_data_fifo, capacity_data_fifo, data_in_fifo);

    fifo #(buffer_size, width) length_fifo
            (clk, rst, wr_en_input, rd_in_length_fifo, length_in, 
            pop_in_length_fifo, capacity_length_fifo, length_in_fifo);

    fifo #(buffer_size, width) command_fifo 
            (clk, rst, wr_en_input, rd_in_command_fifo, command_in, 
            pop_in_command_fifo, capacity_command_fifo, command_in_fifo);

    fifo #(buffer_size_out, width) result_fifo 
            (clk, rst, wr_out_fifo1, rd_en_result_fifo, result_out, 
            pop_in_result_fifo, capacity_result_fifo, result_out_fifo);

    /***************************************************************************
    Instantiate the enable and invoke modules for the actor under test.
    ***************************************************************************/

    stream_comp_invoke_top_module_FSM_1 #(.width(width)) 
            invoke_module(clk, rst, 
            data_in_fifo, length_in_fifo, command_in_fifo,
            invoke, 
            next_mode_in,
            command_loc_mem_state, data_loc_mem_state, len_loc_mem_state,
            rd_in_data_fifo, rd_in_length_fifo, rd_in_command_fifo,
            next_mode_out, length, FC, wr_out_fifo1, 
            result_out);
  
    stream_comp_enable #(.buffer_size(buffer_size), 
            .buffer_size_out(buffer_size_out)) enable_module(rst, 
            pop_in_command_fifo, pop_in_length_fifo, pop_in_data_fifo, pop_in_result_fifo,
            next_mode_in, length, enable);    

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
            $fdisplay(descr, "comp_state: %d, ram_curr_index: %d, data_write_counter: %d", command_loc_mem_state, len_loc_mem_state, data_loc_mem_state);
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
        $readmemh("data_in.txt", data_mem);
        $readmemh("length_in.txt", length_mem);
        $readmemh("command_in.txt", command_mem);

        #1;
        rst <= 0;
        wr_en_input <= 0;
        wr_en_input_data <= 0;
        rd_en_input <= 0;
        data_in <= 0;
        command_in <= 0;
        length_in <= 0;
    
        #2 rst <= 1;
        #2; 
    
        /* Write data into the input FIFOs. The FIFO requires a write enable
         * signal before the data is loaded, so "size" loop intereation are 
         * required here.
         */

        /*
         * Currently hardcoded the size to be the max length of the data fifo.
         */

        $fdisplay(descr, "Setting up input FIFOs");
        for (i = 0; i < 3; i = i + 1)
        begin 
               #2; 
               length_in <= length_mem[i];
               command_in <= command_mem[i];
               #2;
               wr_en_input <= 1;
               $fdisplay(descr, "command[%d] = %d", i, command_in);
               $fdisplay(descr, "length[%d] = %d", i, length_in);
               #2;
               wr_en_input  <= 0;
        end
        for (i = 0; i < 15; i = i + 1)
        begin 
               #2; 
               data_in <= data_mem[i];
               #2;
               wr_en_input_data <= 1;
               $fdisplay(descr, "data[%d] = %d", i, data_in);
               $fdisplay(descr, "data pop = %d", pop_in_data_fifo);
               #2;
               wr_en_input_data  <= 0;
        end
        $fdisplay(descr, "data pop = %d", pop_in_data_fifo);
        #2;     /* ensure that data is stored into memory before continuing */
        next_mode_in <= MODE_ONE;
        #2;
        if (enable)
        begin
            $fdisplay(descr, "Executing firing for mode no. 1");
            $fdisplay(descr, "command pop = %d", pop_in_command_fifo);
            $fdisplay(descr, "length pop = %d", pop_in_length_fifo);
            $fdisplay(descr, "data pop = %d", pop_in_data_fifo);
            $fdisplay(descr, "enable = %d", enable);
            invoke <= 1;
        end
        else  
        begin
            /* end the simulation here if we don't have enough data to fire */
            $fdisplay(descr, "Not enough data to fire the actor under test");

            $finish;
        end
        #2 invoke <= 0;

        /* Wait for mode 1 to complete */ 
        wait (FC) #2 next_mode_in <= MODE_TWO;
        $fdisplay(descr, "data pop = %d", pop_in_data_fifo);
        #2;
        if (enable)
        begin
            $fdisplay(descr, "Length %d", length);
            $fdisplay(descr, "data pop = %d", pop_in_data_fifo);
            $fdisplay(descr, "Executing firing for mode no. 2");
            invoke <= 1;
        end 
        else 
        begin 
            /* end the simulation here if we don't have enough data to fire */
            $fdisplay(descr, "Length %d", length);
            $fdisplay(descr, "data pop = %d", pop_in_data_fifo);
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
        rd_en_result_fifo <= 1;        
               
        #2;
        /* Set up recording of results */
        $fdisplay(descr, "time = %d, FIFO[0] = %d", $time, result_fifo.FIFO_RAM[0]);
        $fdisplay(descr, "time = %d, Result = %d", $time, result_out_fifo);
        $display("time = %d, Result = %d", $time, result_out_fifo);               
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


