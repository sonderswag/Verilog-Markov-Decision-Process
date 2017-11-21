`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:13:50 11/16/2016 
// Design Name: 
// Module Name:    fp_double_multiplier 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
 module fp_double_multiplier(start, reset, input_a, input_b, input_c, output_z, clk, z_ack);

input clk;
//sign bit == [31]
//epxponet == [30:23] 8bit midpoint is 127 
//matis = [22:0] 
input [31:0] input_a; 
input [31:0] input_b; 
input [31:0] input_c;
input start; 
input wire reset; 
output reg [31:0] output_z; 
output reg z_ack;

reg [7:0] state;
// states 
parameter
Init     = 8'b00000001,
Unpack   = 8'b00000010,
Multiply = 8'b00000100,
Normalize= 8'b10000000,
Add_e    = 8'b00001000,
Trunc_m  = 8'b00010000,
Pack     = 8'b00100000,
Done     = 8'b01000000,
zero     = 8'b00000000, 
zero_m   = 23'b00000000000000000000000;

reg [31:0] a, b, c, z;
reg [22:0] a_m, b_m, c_m;
reg [7:0] a_e, b_e, c_e;
reg a_s, b_s, c_s, z_s;
reg [71:0] product;
reg [8:0] sum_e;
reg [11:0] norm_const; 

always@(posedge clk, posedge reset) //asynchronoud posedge RESET 

	begin
	
	if (reset) 
		state <= Init; 
	else 
	begin 
	case(state)
	
		Init:
		begin
			if (start == 1) 
				state <= Unpack;
			
			z_ack <= 0;
			norm_const = 71; 
			a <= input_a;
			b <= input_b;
			c <= input_c;
		end
		
		Unpack:
		begin
			state <= Multiply;
			
			a_e <= a[30:23];
			a_m <= a[22:0];
			a_s <= a[31];
			
			b_e <= b[30:23];
			b_m <= b[22:0];
			b_s <= b[31];
			
			c_e <= c[30:23];
			c_m <= c[22:0];
			c_s <= c[31];
		end
		
		Multiply:
		begin
			if( (a_m == zero_m && a_e == zero) || (b_m == zero_m && b_e == zero) || (c_m == zero_m && c_e == zero) )
				state <= Pack;
			else
				begin
					state <= Normalize;
					//have to express the hidden 1 
					product <= {1'b1,a_m} * {1'b1,b_m} * {1'b1,c_m};
					if ((a_s + b_s + c_s) % 2 != 0)
						z_s <= 1; //checking sign 
					else
						z_s <= 0;
				end
		end
		
		Normalize: 
		begin 
			if (product[norm_const] == 1 || norm_const == 0) 
				begin 
					state <= Add_e;
					norm_const <= norm_const-69;
				end 
			else 
				begin 
					state <= Normalize; 
					norm_const <= norm_const-1 ; 
				end 
			
		end 
		
		Add_e:
		begin
			state <= Trunc_m;
			sum_e <= norm_const+a_e + b_e + c_e - 8'b11111110; 

		end
		
		Trunc_m:
		begin
			if (product[71] == 1)
				state <= Pack;
			else
				product <= product << 1;
		end
		
		Pack:
		begin
			if ( (a_m == zero_m && a_e == zero) || (b_m == zero_m && b_e == zero) || (c_m == zero_m && c_e == zero) )
				begin
					state <= Done;
					z[31] <= 1'b0;
					z[30:23] <= zero;
					z[22:0] <= zero_m;
				end
			else
				begin
					state <= Done;
					z[31] <= z_s;
					z[30:23] <= sum_e[7:0];
					z[22:0] <= product[70:48];
				end
		end
		
		Done:
		begin
			state <= Init;
			z_ack <= 1;
			output_z <= z;
		end
	endcase
	end 
	end

endmodule
