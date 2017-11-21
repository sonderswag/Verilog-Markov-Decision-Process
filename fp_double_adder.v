`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:06:52 11/16/2016 
// Design Name: 
// Module Name:    fp_double_adder 
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
module fp_double_adder(start, reset, input_a, input_b, input_c, output_z, clk, ack, done);

input clk;

input start; 
input reset;
output reg done;  
input [15:0] input_a; 
input [15:0] input_b; 
input [15:0] input_c;
output reg [15:0] output_z; 
input ack;

reg [10:0] state;
parameter
Init      = 11'b00000000001,
Unpack    = 11'b00000000010,
comp      = 11'b00000000100,
Shift_a   = 11'b00000001000,
Shift_b   = 11'b00000010000,
Shift_c   = 11'b00000100000,
Add       = 11'b00001000000,
Add_2     = 11'b00010000000,
Normalize = 11'b00100000000,
Pack      = 11'b01000000000,
Done      = 11'b10000000000,
zero      = 16'b0000000000000000,
zero_e    = 5'b00000,
zero_m    = 10'b0000000000;

reg [15:0] a, b, c, z;
reg [10:0] a_m, b_m, c_m;
reg [4:0] a_e, b_e, c_e, l_e;
reg a_s, b_s, c_s, final_s, l_s;
reg [1:0] largest; //a == 00 , b == 01, c == 10; 
reg [11:0] sum_temp;
reg [12:0] sum_total; 
reg [7:0] norm_const;
reg a_zero_flag, b_zero_flag, c_zero_flag; 

always@(posedge clk, posedge reset)
	begin: add 
	reg [1:0] temp; 
	if (reset) 
	begin 
		state <= Init; 
	end 
	
	else 
	begin 
	case(state)

		Init:
		begin
			if (start) 
				state <= Unpack;
			done <= 0; 
			a <= input_a;
			b <= input_b;
			c <= input_c;
			l_e <= 0; 
			l_s <= 0; 
			largest <= 0; 
			sum_total <= 0; 
			sum_temp <= 0; 
			norm_const <= 12; 
			a_zero_flag <= 0;
			b_zero_flag <= 0;
			c_zero_flag <= 0;
		end
		
		Unpack: //why can't we just unpack, then check if zero if it just re_assign. we don't need to assign for each possible state 
		begin
			state <= comp;
			
			a_e <= a[14:10];
			a_m <= {1'b1,a[9:0]};
			a_s <= a[15];
			
			b_e <= b[14:10];
			b_m <= {1'b1,b[9:0]};
			b_s <= b[15];
			
			c_e <= c[14:10];
			c_m <= {1'b1,c[9:0]};
			c_s <= c[15];
			
			if ( a == zero)
			begin 
				a_zero_flag <= 1;
				a_e <= zero_e;
				a_m <= zero_m;
				a_s <= 1'b0;
			end 
			
			if ( b == zero )
			begin 
				b_zero_flag <= 1;
				b_e <= zero_e;
				b_m <= zero_m;
				b_s <= 1'b0;
			end 
			
			if (c == zero)
			begin 
				c_zero_flag <= 1;
				c_e <= zero_e;
				c_m <= zero_m;
				c_s <= 1'b0;
			end 
						
		end
		
		comp: 
		begin 
			
			if (a_zero_flag == 1 && b_zero_flag == 1 && c_zero_flag == 1)
				state <= Done;
			else 
				begin
					state <= Shift_a; 
			
					if (a_e > b_e && a_e > c_e) 
						temp = 0;// a 
					else if (b_e > a_e && b_e > c_e) 
						temp = 1;// b 
					else if (c_e > a_e && c_e > b_e) 
						temp = 2;// c 
					else if (a_e == b_e && a_e == c_e) 
						if (a_m > b_m && a_m > c_m) 
							temp = 0;// a
						else if (b_m > a_m && b_m > c_m) 
							temp = 1;// b 
						else if (c_m > b_m && c_m > c_m)
							temp = 2;// c
						else if (a_m == b_m) 
							if (a_m > c_m) 
								temp = 0;// a
							else 
								temp = 2;// c 
						else if (a_m == c_m) 
							if (a_m > b_m) 
								temp = 0;// a 
							else 
								temp = 1;// b 
						else if (b_m == c_m) 
							if (b_m > a_m) 
								temp = 1;// b
							else 
								temp = 0;// a 
						else 
							temp = 0;// all equal 
				
					else if (a_e == b_e) 
						if (a_e > c_e) 
							if (a_m > b_m) 
								temp = 0;// a 
							else 
								temp = 1;// b 
						else 
							temp = 2;// c
			
					else if (a_e == c_e)
						if (a_e > b_e) 
							if (a_m > c_m) 
								temp = 0; // a 
							else 
								temp = 2;// c 
						else 
							temp = 1; // b
			
					else if (b_e == c_e) 
						if (b_e > a_e) 
							if (b_m > c_m) 
								temp = 1; // b 
							else 
								temp = 2;// c 
						else 
							temp = 0;// a
			
					if (temp == 0) //a 
						begin 
							largest <= 2'b00;  
							l_e <= a_e; 
							l_s <= a_s; 
						end 
					else if (temp == 1) //b 
						begin 
							largest <= 2'b01;  
							l_e <= b_e; 
							l_s <= b_s; 
						end 
					else // c 
						begin 
							largest <= 2'b10;  
							l_e <= c_e; 
							l_s <= c_s; 
						end
				end
		end 
 
		Shift_a:
		begin
			if (l_e == a_e) 
				state <= Shift_b; 
			else 
				begin 
					if (a_zero_flag == 1)
						state <= Shift_b;
					else
						begin
							state <= Shift_a; 
							a_e <= a_e+1'b1; 
							a_m <= {1'b0,a_m[10:1]};
						end
				end 
		end
		
		Shift_b:
		begin
			if (l_e == b_e) 
				state <= Shift_c; 
			else 
				begin 
					if (b_zero_flag == 1)
						state <= Shift_c;
					else
						begin
							b_e <= b_e+1'b1; 
							b_m <= {1'b0,b_m[10:1]};
						end
				end 
		end
		
		Shift_c:
		begin
			if (l_e == c_e) 
				state <= Add; 
			else 
				begin 
					if (c_zero_flag == 1)
						state <= Add;
					else
						begin
							c_e <= c_e+1'b1; 
							c_m <= {1'b0,c_m[10:1]};
						end
				end 
		end
		
		Add:
		begin
			if (largest == 2'b00) // a
				if (a_s != b_s && a_s != c_s) // chance of changing signs 
					begin 	
						state <= Add_2; 
						sum_temp <= b_m + c_m; 
					end
				else // sign will be the largest sign 
					begin 	
						final_s <= a_s; 
						state <= Normalize; 
						if (a_s != b_s) 
							sum_total <= a_m - b_m + c_m;
						else if (a_s != c_s) 
							sum_total <= a_m + b_m - c_m; 
						else 
							sum_total <= a_m + b_m + c_m; 	
					end 
			//--------------------------------------------
			else if (largest == 2'b01) // b
				if (b_s != a_s && b_s != c_s) 
				begin 	
						state <= Add_2; 
						sum_temp <= a_m + c_m; 
					end
				else 
					begin 	
						final_s <= b_s; 
						state <= Normalize; 
						if (b_s != a_s) 
							sum_total <= b_m - a_m + c_m;
						else if (b_s != c_s) 
							sum_total <= a_m + b_m - c_m; 
						else 
							sum_total <= a_m + b_m + c_m; 	
					end 
			//--------------------------------------------
			else if (largest == 2'b10) // c 
				if (c_s != a_s && c_s != b_s) 
				begin 	
						state <= Add_2; 
						sum_temp <= b_m + a_m; 
					end
				else 
					begin 	
						final_s <= c_s; 
						state <= Normalize; 
						if (c_s != a_s) 
							sum_total <= c_m - a_m + b_m;
						else if (c_s != b_s) 
							sum_total <= c_m - b_m + a_m; 
						else 
							sum_total <= a_m + b_m + c_m; 	
					end 
		end
		
		Add_2: // chance for sign change orn zero 
		begin 
			state <= Normalize; 
			if (largest == 2'b00) // a
				if (a_m < sum_temp) // sign change 
					begin 
						final_s <= ~a_s; 
						sum_total <= sum_temp - a_m; 
					end 
				else if (a_m == sum_temp) // zero 
					begin 
						final_s <= a_s; 
						sum_total <= 0; 
						l_e <= 0; 
					end
				else // a > then the other put togeather 
					begin 
						final_s <= a_s ; 
						sum_total <= a_m - sum_temp; 
					end
			//--------------------------------------------
			else if (largest == 2'b01) // b
				if (b_m < sum_temp) 
					begin 
						final_s <= ~b_s; 
						sum_total <= sum_temp - b_m; 
					end 
				else if (b_m == sum_temp)
					begin 
						final_s <= b_s; 
						sum_total <= 0; 
						l_e <= 0; 
					end 
				else 
					begin 
						final_s <= b_s ; 
						sum_total <= b_m - sum_temp; 
					end
			//--------------------------------------------		
			else if (largest == 2'b10) // c
				if (c_m < sum_temp) 
					begin 
						final_s <= ~c_s; 
						sum_total <= sum_temp - c_m; 
					end 
				else if (c_m == sum_temp) 
					begin 
						final_s <= c_s; 
						sum_total <= 0; 
						l_e <= 0; 
					end 
				else 
					begin 
						final_s <= c_s ; 
						sum_total <= c_m - sum_temp; 
					end
		end 
		
		Normalize: 
		begin 
			if (sum_total[12] == 1 || norm_const == 0 || sum_total == 0) 
				begin 
					norm_const <= norm_const - 10; 
					if (sum_total == 0) 
						norm_const <= 0 ; 
					state <= Pack; 
				end
			else 
				begin 
					sum_total <= {sum_total[11:0],1'b0};
					norm_const <= norm_const - 1'b1; 
				end
		
		end 

		
		Pack:
		begin
			state <= Done;
			z[15] <= final_s;
			z[14:10] <= l_e + norm_const;
			z[9:0] <= sum_total[12:2];
		end
		
		Done:
		begin
			done <= 1; 
			if (ack == 1)
				state <= Init; 
			if (a_zero_flag == 1 && b_zero_flag == 1 && c_zero_flag == 1) //do we need a flag, we already have a,b,c which are zero?? 
				begin
					output_z <= zero;
				end
			else
				begin
					output_z <= z; 
				end
		end
		
		default: 
		begin 
			z <= zero; 
		end 
	endcase
	end
	end 

endmodule
