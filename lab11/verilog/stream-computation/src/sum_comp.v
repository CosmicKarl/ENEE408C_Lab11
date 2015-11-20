
/*******************************************************************************
This FSM implements the core computational mode for the sum_comp
*******************************************************************************/

/*******************************************************************************
*  Parameters:      A. size -- the number of tokens (integers) in each
*                   input vector. 

*                   B. width -- the bit width for the integer data type
*                   used in the inner product operations
*******************************************************************************/
`timescale 1ns/1ps

module sum_comp
        #(parameter size = 3, width = 10)(  
        input clk, rst,
        input start_in,
        input [width - 1 : 0] length, data,
        output reg done_out,
        output reg rd_en,
        output [width - 1 : 0] rd_addr,
        output reg [width - 1 : 0] sum);

    localparam START = 2'b00, STATE0 = 2'b01, STATE1 = 2'b10, END = 2'b11;
  
    reg [1 : 0] state, next_state;
    reg [width - 1 : 0] next_sum;
    reg [log2(size) - 1 : 0] counter, next_counter;
  
    always @(posedge clk)
    begin
        if (!rst)
        begin 
            state <= START;
            sum <= 0;
	          counter <= 0;
        end
        else
        begin 
            state <= next_state;
            sum <= next_sum;
	          counter <= next_counter;
        end
    end
  
    assign rd_addr = counter;

    always @(state, start_in, counter)
    begin 
        case (state)
		/*Initialize parameters*/	
	      START:
	      begin
            done_out <= 0;
       	    next_sum <= sum;
       	    next_counter <= 0;
       	    rd_en <= 0;
            if (start_in)
                next_state <= STATE0;
            else
                next_state <= START;		    
        end
        STATE0:
        begin 
            next_counter <= counter + 1;
            rd_en <= 1;
            next_sum <= data;
            next_state <= STATE1;
        end
        STATE1:
        begin 
            next_counter <= counter + 1;
            rd_en <= 1;
            next_sum <= sum + data;
            if (counter == (length))
                next_state <= END;
            else
                next_state <= STATE1;
        end
        END:
        begin 
            done_out <= 1;
            next_counter <= 0;
            rd_en <= 0;
            next_sum <= sum;	    
            next_state <= START;
        end
        endcase
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
  
