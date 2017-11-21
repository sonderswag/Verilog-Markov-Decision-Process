`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:43:18 11/09/2016 
// Design Name: 
// Module Name:    user_input 
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

module decode_fp(Reset, Clk, Start, Ack, Fp_in, Done, Decode_1, Decode_2); 
input Reset, Start, Clk, Ack; 
input [15:0] Fp_in; 
output reg [3:0] Decode_1, Decode_2; 
output reg Done; 

reg [4:0] fp_e; 
reg [15:0] fp_m;
reg [3:0] state; 
localparam
Init      = 4'b0001,   
Normalize = 4'b0010, 
Convert   = 4'b0100,
Done_con = 4'b1000,
zero     = 8'b00000000,
zero_f   = 16'b0000110011001100, 
one_z    = 16'b0001100110011001, 
one_f    = 16'b0010011001100110,  
two_z    = 16'b0011001100110011,  
two_f    = 16'b0100000000000000, 
three_z  = 16'b0100110011001100, 
three_f  = 16'b0101100110011001, 
four_z   = 16'b0110011001100110, 
four_f   = 16'b0111001100110011, 
five_z   = 16'b1000000000000000, 
five_f   = 16'b1000110011001100, 
six_z    = 16'b1001100110011001, 
six_f    = 16'b1010011001100110, 
seven_z  = 16'b1011001100110011,
seven_f  = 16'b1100000000000000, 
eight_z  = 16'b1100110011001100, 
eight_f  = 16'b1101100110011001, 
nine_z   = 16'b1110011001100110, 
nine_f   = 16'b1111001100110011; 
always@(posedge Clk, posedge Reset)
begin: state_machine 
	integer norm_const;
	reg [15:0] temp; 
	
	if (Reset == 1)
	begin 
		state <= Init; 
	end 
	
	else 
	begin 
	
	case(state)
	
	Init: 
	begin 
		if (Start)
			state <= Normalize; 
		fp_e <= Fp_in[14:10]; 
		fp_m <= {1'b1,Fp_in[9:0],5'b00000};
		Done <= 0; 
		Decode_1 <= 0;
		Decode_2 <= 0; 
	end 
		
	Normalize: 
	begin 
		// only works for less then 1 
		if (fp_e >= 4'b1111 || fp_e == 0)
			begin 
				state <= Done_con; 
				Decode_1 <= 15; 
				Decode_2 <= 15;  
			end 
		else 
		state <= Convert; 
		norm_const = 4'b1110 - fp_e ;
		fp_m <= fp_m >> norm_const; 
	end 
	
	Convert: 
	begin 
		state <= Done_con; 
		temp = fp_m; 
		if (temp >= nine_f)
		begin 
			Decode_1 <= 4'b1001; 
			Decode_2 <= 4'b0101;  
		end 
		else if (temp >= nine_z)
		begin 
			Decode_1 <= 4'b1001; 
			Decode_2 <= 4'b0000;
		end 
		else if (temp >= eight_f)
		begin 
			Decode_1 <= 4'b1000;
			Decode_2 <= 4'b0101;
		end 
		else if (temp >= eight_z)
		begin 	
			Decode_1 <= 4'b1000; 
			Decode_2 <= 0; 
		end 
		else if (temp >= seven_f)
		begin 	
			Decode_1 <= 4'b0111; 
			Decode_2 <= 4'b0101;
		end 
		else if (temp >= seven_z)
		begin	
			Decode_1 <= 4'b0111; 
			Decode_2 <= 0;
		end
		else if (temp >= six_f)
		begin	
			Decode_1 <= 4'b0110; 
			Decode_2 <= 4'b0101; 
		end 
		else if (temp >= six_z)
		begin	
			Decode_1 <= 4'b0110; 
			Decode_2 <= 0;
		end 
		else if (temp >= five_f)
		begin	
			Decode_1 <= 4'b0101; 
			Decode_2 <= 4'b0101;
		end 
		else if (temp >= five_z)
		begin	
			Decode_1 <= 4'b0101; 
			Decode_2 <= 0;
		end 
		else if (temp >= four_f)
		begin	
			Decode_1 <= 4'b0100; 
			Decode_2 <= 4'b0101;
		end
		else if (temp >= four_z)
		begin	
			Decode_1 <= 4'b0100; 
			Decode_2 <= 0; 
		end
		else if (temp >= three_f)
		begin	
			Decode_1 <= 4'b0011; 
			Decode_2 <= 4'b0101;
		end
		else if (temp >= three_z)
		begin	
			Decode_1 <= 4'b0011; 
			Decode_2 <= 0;
		end 
		else if (temp >= two_f)
		begin	
			Decode_1 <= 4'b0010; 
			Decode_2 <= 4'b0101;
		end
		else if (temp >= two_z)
		begin	
			Decode_1 <= 4'b0010; 
			Decode_2 <= 0;
		end 
		else if (temp >= one_f)
		begin	
			Decode_1 <= 4'b0001; 
			Decode_2 <= 4'b0101; 
		end 
		else if (temp >= one_z)
		begin	
			Decode_1 <= 4'b0001; 
			Decode_2 <= 0;
		end 
		else if (temp >= zero_f)
		begin	
			Decode_1 <= 0; 
			Decode_2 <= 4'b0101;
		end 
		else 
		begin	
			Decode_1 <= 0; 
			Decode_2 <= 0;
		end 
	end 
	
	Done_con: 
	begin 
		Done <= 1; 
		if (Ack == 1)
		begin 
			state <= Init;
			Done <= 0; 
		end 
		else 
			state <= Done_con; 
	end 
	default: 
	begin 
		state <= Done_con; 
	end
	endcase 
	end 
end 

endmodule 
