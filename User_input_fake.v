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

module user_input_fake (clk, Reset, Left, Up, Down, Right, Num_in,
	Converted_1, Policy, Done, world, width, depth, Converted_2, state
	); 

input clk,Reset,Left,Up,Down,Right;
input [7:0] Num_in; 

output [47:0] Converted_1, Converted_2;
reg [127:0] Converted_Utilities_1, Converted_Utilities_2; 

assign Converted_1 = Converted_Utilities_1[47:0];
assign Converted_2 = Converted_Utilities_2[47:0];

output reg [7:0] width, depth; 

output [63:0] Policy ; 
output reg Done;  
wire MDP_completed;

reg [7:0] iterations, loc_pos; 
output reg [65:0] world;  // this is the world that will be fed to the MDP 
wire [511:0] Current_Utilities; 

reg [15:0] noise     = 16'b0011101001100110;
reg [15:0] inv_noise = 16'b0010111001100110; 
reg [15:0] discount  = 16'b0011101100110011; 

reg [7:0] num_loc; 

reg [15:0] d1_in ; 
reg d1_start, d1_ack; 
wire d1_done;
wire [3:0] d1_decode_1, d1_decode_2;  

decode_fp decode_1(
	.Reset(Reset), 
	.Clk(clk), 
	.Start(d1_start), 
	.Ack(d1_ack), 
	.Fp_in(d1_in), 
	.Done(d1_done), 
	.Decode_1(d1_decode_1),
	.Decode_2(d1_decode_2)
	); 

MDP_fake MDP_SM(
	.start(Left), 
	.MDP_done(MDP_completed), 
	.cur_util(Current_Utilities), 
	.policy(Policy)
    );
	

initial
begin 
		Converted_Utilities_1 <= 0; 
		Converted_Utilities_2 <= 0; 
		iterations <= 0; 
		d1_in <= 0; 
		 
	//if (Reset)
		world[1:0]   <= 2'b00; // 0
		world[3:2]   <= 2'b00; // 1
		world[5:4]   <= 2'b00; // 2 
		world[7:6]   <= 2'b01; // 3 //positive
		world[9:8]   <= 2'b00; // 4 
		world[11:10] <= 2'b11; // 5 // wall
		world[13:12] <= 2'b00; // 6 
		world[15:14] <= 2'b10; // 7 // negative 
		world[17:16] <= 2'b00; // 8
		world[19:18] <= 2'b00; // 9
		world[21:20] <= 2'b00; // 10
		world[23:22] <= 2'b00; // 11
		world[25:24] <= 2'b00; // 12
		world[27:26] <= 2'b00; // 13
		world[29:28] <= 2'b00; // 14
		world[31:30] <= 2'b00; // 15 
		world[33:32] <= 2'b00; // 16 
		world[35:34] <= 2'b00; // 17 
		world[37:36] <= 2'b00; // 18 
		world[39:38] <= 2'b00; // 19  
		world[41:40] <= 2'b00; // 20
		world[43:42] <= 2'b00; // 21
		world[45:44] <= 2'b00; // 22
		world[47:46] <= 2'b00; // 23
		world[49:48] <= 2'b00; // 24
		world[51:50] <= 2'b00; // 25
		world[53:52] <= 2'b00; // 26
		world[55:54] <= 2'b00; // 27
		world[57:56] <= 2'b00; // 28 
		world[59:58] <= 2'b00; // 29 
		world[61:60] <= 2'b00; // 30 
		world[63:62] <= 2'b00; // 31 
end 

output reg[9:0] state; 
localparam
Init        = 10'b0000000001,  
Num_iter    = 10'b0000000010,
Get_width   = 10'b0000000100,
Get_depth   = 10'b0000001000,
Location    = 10'b0000010000,
Type        = 10'b0000100000,
MDP         = 10'b0001000000,
MDP_finish  = 10'b0010000000,
Unpack      = 10'b0100000000,
Done_state  = 10'b1000000000; 

always@(posedge clk, posedge Reset)
begin: state_machine 
	integer w_lower, counter; 
	if (Reset)
	begin 
		state <= Init;  
		iterations <= 10; 
		width <= 4; 
		depth <= 3; 
		Done <= 0; 
		Converted_Utilities_1 <= 0; 
		Converted_Utilities_2 <= 0; 
		
		world[1:0]   <= 2'b00; // 0
		world[3:2]   <= 2'b00; // 1
		world[5:4]   <= 2'b00; // 2 
		world[7:6]   <= 2'b01; // 3 //positive
		world[9:8]   <= 2'b00; // 4 
		world[11:10] <= 2'b11; // 5 // wall
		world[13:12] <= 2'b00; // 6 
		world[15:14] <= 2'b10; // 7 // negative 
		world[17:16] <= 2'b00; // 8
		world[19:18] <= 2'b00; // 9
		world[21:20] <= 2'b00; // 10
		world[23:22] <= 2'b00; // 11
		world[25:24] <= 2'b00; // 12
	end 
	
	else 
	begin 
	case(state)
	
		Init: 
		begin 
		// state
			if(Left)
				state <= MDP;
			else if(Up)
				state <= Num_iter; 
			else if (Down)
				state <= Get_width; 
			else if (Right)
				state <= Location; 
		// RTL
			num_loc <= (width*depth);
			counter <= 0; 
			loc_pos <= 0;
			d1_in <= 0; 
			Done <= 0;
			
		end 
		
		Num_iter: 
		begin 
			if(Up)
				state <= Init; 
		
			iterations <= Num_in; 
		end 
		
		Get_width: 
		begin 
			if (width % 2 == 0 && width <= 8)
				if (Down)
					begin 
					state <= Get_depth;
					end 
			
			//width <= Num_in; 
			
		end 
		
		Get_depth: 
		begin 
			if (Down)
				state <= Init; 
			
			//depth <= Num_in; 
		end
		
		Location: 
		begin 
			if(Right)
				state <= Type; 
			else if (Down && loc_pos <= num_loc  ) //note this is how you exit the edit location sequnecy 
				state <= Init; 
			
			loc_pos <= Num_in; 
		end 
		
		Type: 
		begin 
			if (Right)
				state <= Location; 
			
			w_lower = loc_pos*2 ; 
			world[w_lower+:2] <= Num_in[1:0]; 
		end 
		
		MDP: 
		begin 
			Converted_Utilities_1 <= 0; 
			Converted_Utilities_2 <= 0; 
			if (MDP_completed)
				state <= MDP_finish; 
		end 
		
		MDP_finish: 
		begin 
			if (d1_done)
				begin 
					state <= Unpack; 
					//Converted_Utilities_1[(counter*4)+:4] <= d1_decode_1; 
					//Converted_Utilities_2[(counter*4)+:4] <= d1_decode_2;
					 Converted_Utilities_1 <= {4'd5,4'd5,4'd5,4'd5,4'd5,4'd5,4'd5,4'd5,4'd5,4'd5,4'd5,4'd5,4'd5,4'd5,4'd9,4'd8,4'd7,4'd6,4'd5,4'd4,4'd3,4'd2,4'd1,4'd9,4'd8,4'd7,4'd6,4'd5,4'd4,4'd3,4'd2,4'd1};
					 Converted_Utilities_2 <= {4'd5,4'd5,4'd5,4'd5,4'd5,4'd5,4'd5,4'd5,4'd5,4'd5,4'd5,4'd5,4'd5,4'd5,4'd5,4'd5,4'd0,4'd0,4'd5,4'd0,4'd0,4'd0,4'd5,4'd0,4'd5,4'd0,4'd5,4'd0,4'd5,4'd0,4'd5,4'd0};
				end 
			d1_start <= 1; 
			d1_ack <= 0; 
			d1_in <= Current_Utilities[(counter*16)+:16]; 
			
		end 
		
		Unpack: 
		begin 
			if (counter >= num_loc-1)
				begin 
				state <= Done_state; 
				Done <= 1; 
				end 
			else if (d1_decode_1 == 0)
				begin 
					state <= MDP_finish; 
					counter <= counter+1; 
				end 
			d1_start <= 0; 
			d1_ack <= 1;

			
		end 
		
		Done_state:
		begin 
			Done <= 0; 
			if (Left)
			begin 
				state <= Init; 
				
			end 
			
		end 
		
		default: 
		begin 
			state <= Done_state; 
		end 
	endcase 
	end 
end 

endmodule 
