`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Christian Wagner, Neil Mehta 
// 
// Create Date:    11/30/16
// Design Name: 
// Module Name:    fP_singl_multiplier 
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
module fp_single_multiplier(start, reset, input_a, input_b, output_z, clk, done, ack);


input clk;
//sign bit == [31]
//epxponet == [30:23] 8bit midpoint is 127 
//matis = [22:0] 
input [15:0] input_a; 
input [15:0] input_b; 
input start; 
input ack; 
input wire reset; 
output reg [15:0] output_z; 
output reg done;

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
zero_m   = 16'b0000000000000000;

reg [15:0] a, b, z;
reg [9:0] a_m, b_m;
reg [4:0] a_e, b_e;
reg a_s, b_s, z_s;
reg [22:0] product;
reg [4:0] sum_e;
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
			
			done <= 0; 
			norm_const <= 22; 
			a <= input_a;
			b <= input_b;
		end
		
		Unpack:
		begin
			state <= Multiply;
			
			a_e <= a[14:10];
			a_m <= a[9:0];
			a_s <= a[15];
			b_e <= b[14:10];
			b_m <= b[9:0];
			b_s <= b[15];
			
		end
		
		Multiply:
		begin
			if( (a_m == zero_m && a_e == zero) || (b_m == zero_m && b_e == zero))
				state <= Pack;
			else
				begin
					state <= Normalize;
					//have to express the hidden 1 
					product <= {1'b1,a_m} * {1'b1,b_m};
					if ((a_s + b_s) % 2 != 0)
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
					norm_const <= norm_const-20;
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
			sum_e <= norm_const+a_e + b_e - 5'b01111; 

		end
		
		Trunc_m:
		begin
			if (product[22] == 1)
				state <= Pack;
			else
				product <= product << 1;
		end
		
		Pack:
		begin
			if ( (a_m == zero_m && a_e == zero) || (b_m == zero_m && b_e == zero))
				begin
					state <= Done;
					z[15] <= 1'b0;
					z[14:10] <= zero;
					z[9:0] <= zero_m;
				end
			else
				begin
					state <= Done;
					z[15] <= z_s;
					z[14:10] <= sum_e[4:0];
					z[9:0] <= product[22:12];
				end
		end
		
		Done:
		begin
			if (ack == 1)
				state <= Init;
			done <= 1;
			output_z <= z;
		end
		
		default: 
		begin 
			state <= Done; 
		end 
	endcase
	end 
end

endmodule
