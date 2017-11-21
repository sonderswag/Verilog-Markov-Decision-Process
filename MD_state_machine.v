`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Christian Wagner, Neil Mehta 
// 
// Create Date:    11/30/16
// Design Name: 
// Module Name:    MD_state_machine 
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
/* Efficiency upgrades 
1) upgrade double adder zero handeling
2) don't need double multiplier, since noise*discount and inv_noise*discount is 
	always the same. Therefore can just feed it the multiplication of the two. _/ 
3) may have to do short form of floating point precision in order to cut down on the number of registers

Other notes: 
1) Looks like we can use % as long as we or moddy by a power of 2 
2) loc_type is an outout from the memory containing the gridworld 
3) need to change done state, so that we don't reset. We should be able to say more iterations
4) using blocking assignment for inputs to multiplication modules. since the are inputed into clocked registers. 
	I want to save clocks and registers by not saving the values in another registers before they get stored in the 
	module registers.
	
*/ 
//////////////////////////////////////////////////////////////////////////////////

module MD_state_machine(clk, Reset, start, iteration_in, MDP_done, ack, 
	in_noise, in_inv_noise, in_discount, cur_util, policy, state, 
	in_world, in_width, in_depth, cont
    );
// -------------- input ---------------
input clk, start, Reset, ack, cont; 
input [7:0] iteration_in;  
input [15:0] in_inv_noise, in_noise, in_discount;
input [7:0] in_width, in_depth;
input [63:0] in_world; // up to 32 locations 
reg [65:0] world; 
integer width, depth; 
integer num_locations; 
// -------------- output ----------------
output reg MDP_done; 
// in order to store the maximum utility of each state, we need a register 
// to store the 16 bit vlaue of the floating point. 
output reg [511:0] cur_util; 

// up == 11 = 3; 
// down == 00 = 0; 
// right == 10 = 2; 
// left == 01 = 1; 
output reg [63:0] policy; // store the policy 


// --------- variables for floating point operations ------------- 
reg start_multi; 
reg start_add; 
reg mult_ack, add_ack; 
wire m1_done, m2_done, m3_done, a_done; 
reg [15:0] in_1a, in_1b, in_2a, in_2b, in_3a, in_3b;
wire [15:0] out_1, out_2, out_3; 
reg [15:0] add_in1, add_in2, add_in3;
wire [15:0] add_out; 
reg first_multi_flag; // this is say that it is the first time through multiplication 

// --------- variables for girdworld & MDP ----------------


reg [2:0] next_action; //this will tell what action state multi should go to 
// 000 = 0 == down 
// 001 = 1 == left
// 010 = 2 == right 
// 011 = 3 == update
// 100 = 4 == check_type 
reg [1:0] cur_action; // this is used to store the policy 
// 00 = 0 == down 
// 01 = 1 == left
// 10 = 2 == right 
// 11 = 3 == up 

reg [7:0] iteration; // tells how many iterations of value iteration should be preformed 
integer location; 


reg [15:0]new_max[31:0]; // the new max value that will be stored at the end of the iteration 

output reg[12:0] state; 

localparam
Init       = 13'b0000000000001,
Up         = 13'b0000000000010, 
Down       = 13'b0000000000100,
Left       = 13'b0000000001000, 
Right      = 13'b0000000010000,
Update     = 13'b0000000100000,
Done       = 13'b0000001000000,
Check_type = 13'b0000010000000,
First_multi= 13'b0000100000000,
Multi      = 13'b0001000000000,
Add        = 13'b0010000000000,
Continue   = 13'b0100000000000,
World_builder = 13'b1000000000000,
one = 16'b0011110000000000,
zero =16'b0000000000000000,
neg_one = 16'b1011110000000000;



// -------------- module instantiation -------------------------
fp_single_multiplier Multi_1(
	.start(start_multi), 
	.reset(Reset), 
	.input_a(in_1a), 
	.input_b(in_1b), 
	.output_z(out_1), 
	.clk(clk), 
	.done(m1_done),
	.ack(mult_ack)
	);

fp_single_multiplier Multi_2(
	.start(start_multi), 
	.reset(Reset), 
	.input_a(in_2a), 
	.input_b(in_2b), 
	.output_z(out_2), 
	.clk(clk), 
	.done(m2_done),
	.ack(mult_ack)
	);

fp_single_multiplier Multi_3(
	.start(start_multi), 
	.reset(Reset), 
	.input_a(in_3a), 
	.input_b(in_3b), 
	.output_z(out_3), 
	.clk(clk), 
	.done(m3_done),
	.ack(mult_ack)
	);

fp_double_adder Adder(
	.start(start_add), 
	.reset(Reset), 
	.input_a(out_1), 
	.input_b(out_2), 
	.input_c(out_3), 
	.output_z(add_out), 
	.clk(clk), 
	.done(a_done),
	.ack(add_ack)
	);
// ---------------- defining the girdworld -------------------------
// 00 == empty 
// 11 == wall 
// 01 == positive exit 
// 10 == negative exit 
//This is constructing the world. For a given type_address the type is stored into local adress 

/*
assign type_add = location; 
always @(type_add) 
begin 
	case(type_add) 
		4'b 0000: loc_type = 2'b00; //0
		4'b 0001: loc_type = 2'b00; //1
		4'b 0010: loc_type = 2'b00; //2
		4'b 0011: loc_type = 2'b01; //3 positive 
		4'b 0100: loc_type = 2'b00; //4
		4'b 0101: loc_type = 2'b11; //5
		4'b 0110: loc_type = 2'b00; //6 
		4'b 0111: loc_type = 2'b10; //7 negative 
		4'b 1000: loc_type = 2'b00; //8
		4'b 1001: loc_type = 2'b00; //9
		4'b 1010: loc_type = 2'b00; //10
		4'b 1011: loc_type = 2'b00; //11
	endcase 
end 
*/ 
// ------------------ main state machine ------------------------------ 

always@(posedge clk, posedge Reset) 
begin : main_state_machine
	integer u_lower, p_lower, i, w_lower; 
	if (Reset)
		state <= Init; 
	else 
	begin 
	case(state) 
	
		Init:  
		begin 
		// state 
			if (start) 
				state <= World_builder; 
		//RTL 
			
			// first multiplication variabels 
			in_1a <= in_noise; 
			in_1b <= in_discount; 
			in_2a <= in_inv_noise; 
			in_2b <= in_discount; 
			in_3a <= 0; 
			in_3b <= 0; 
			first_multi_flag <= 0; 
			start_multi <= 1; // start the first multiplication 
			world <= in_world; // inputing the world 
			i = 0;

			// initalizing other variables 
			width <= 4; 
			depth <= 3; 
			num_locations <= 11; //(in_width*in_depth)-1; 
			iteration <= iteration_in ; 
			location <= 0; 
			start_multi <= 1; 
			start_add <= 0;
			MDP_done <= 0; 
			cur_util <= 0; 
			policy <= 0; 
			
		end 
		
		World_builder:
		begin
			if(i == num_locations+2)
				state <= First_multi;
			else
			begin
				state <= World_builder; 
				w_lower = i*2; 
				u_lower = i*16; 
				if (world[w_lower+:2] == 2'b01) // positive 1 					
					cur_util[u_lower+:16] <= one;
				else if (world[w_lower+:2] == 2'b10)
					cur_util[u_lower+:16] <= neg_one;
				else
					cur_util[u_lower+:16] <= zero; 
				i = i + 1;
			end
		end
		
		
		First_multi: 
		begin 
		start_multi <= 0;
		
		
			
			if (m1_done && m2_done && m3_done) 
				begin 
					state <= Check_type; 
					in_1a <= out_1; // this is the product of noise*discount 
					in_2a <= out_2; // this is the product of [(1-noise)/2]*discount  
					in_3a <= out_2; 
					mult_ack <= 1; 
				end 
			else 
				state <= First_multi; 
			
		end 
		
		Continue: 
		begin 
			if (start) 
				state <= Check_type; 
			iteration <= iteration_in ; 
			location <= 0; 
			start_add <= 0;
		end 
		
		Check_type:
		begin 		
		//state 
			mult_ack <= 0; 
			add_ack <= 0; 
			new_max[location] <= 0; 
			w_lower = location*2; 
			if(world[w_lower+:2] == 2'b00) 
				if(location <= (width-1)) 
					state <= Down ; 
				else 
					state <= Up; 
			else 
				begin 
					location <= location + 1; 
					if (world[w_lower+:2] == 2'b01)// positive exit 
						new_max[location] <= one; 
					else if (world[w_lower+:2] == 2'b10)
						new_max[location] <= neg_one;
					else if (world[w_lower+:2] == 2'b11)
						new_max[location] <= zero ; 
				
				end
			
	
			
		end 
		
		Multi: 
		begin 
			start_multi <= 0; // 
			if (m1_done && m2_done && m3_done) 
			begin 
				// state 
				state <= Add; 
				// RTL 
				start_add <= 1;
				// the inputs to the add module are directly tied to output of multiply 
				mult_ack <= 1; 
			end 
		end 
		
		Add: 
		begin 
			
			start_add <= 0; 
			if (a_done)  
			begin 
			// state 
				add_ack <= 1; 
				if (next_action == 3'b000) // down 
					state <= Down; 
				else if (next_action == 3'b001) // left 
					state <= Left; 
				else if (next_action == 3'b010) // right 
					state <= Right; 
				else if (next_action == 3'b011) // update
					begin 
						state <= Update;
						i = 0; 
					end 
				else if (next_action == 3'b100) // check type  
					begin 
						state <= Check_type;
						location <= location+1;
					end 
			//RTL These are floating point. need to compare flooting points 
			// want if (add_out > new_max) new_max <= add_out; policy <= cur_action 
				
				p_lower = location*2; 
				if (new_max[location] == 0 && add_out[15] == 0) // inital case 
					begin 
						new_max[location] <= add_out; 
						policy[p_lower+:2] <= cur_action; 
					end 
				
				
				if (add_out[15] == 0) // checking sign bit to see if it is positive
					begin 
					if(add_out[14:10] > new_max[location][14:10]) // checking exponent 
						begin 
							new_max[location] <= add_out; 
							policy[p_lower+:2] <= cur_action; 
						end
					else if ( add_out[14:10] == new_max[location][14:10]) // checking mantisa 
						if (add_out[9:0] > new_max[location][9:0]) 
							begin 
								new_max[location] <= add_out; 
								policy[p_lower+:2] <= cur_action; 
							end
					end 		
				
				
			end 
		end 
		
		Up: 
		begin 
		//state 
		mult_ack <= 0; 
		state <= Multi; 
		
		// RTL 
		
		start_multi <= 1; 
		cur_action <= 2'b11; //up 
		if (location == width*(depth-1)) 
			next_action <= 3'b010; //right
		else if (location > width*(depth-1)) 
			next_action <= 3'b001 ; //left ; 
		else 
			next_action <= 3'b000 ; //down;
		
		u_lower = (location-width)*16;
		in_1b <= cur_util[u_lower+:16];
		
		w_lower = (location-1)*2; 
		if (location % width != 0 && world[w_lower+:2] !=  2'b11 ) 
			begin 
				u_lower = (location-1)*16;	
			end 
		else 
			begin 
				u_lower = location*16; 
			end  
		
		in_2b <= cur_util[u_lower+:16]; 
		
		w_lower = (location+1)*2; 
		if ((location+1)%width != 0 && world[w_lower+:2] !=  2'b11)
			begin 
				u_lower = (location+1)*16;
			end 
		else 
			begin 
				u_lower = location*16;
			end 
		
		in_3b <= cur_util[u_lower+:16]; 
		
		end 	
		
	
		Down: 
		begin 
		//state
			mult_ack <= 0; 
			state <= Multi;
			
			start_multi <= 1 ;
			cur_action <= 2'b00; // down 
			if (location % width != 0) 
				next_action <= 3'b001; //left ; 
			else 
				next_action <= 3'b010; //right 
		// RTL 	
			
			u_lower = (location+width)*16;
			in_1b <= cur_util[u_lower+:16]; 
			
			w_lower = (location-1)*2;
			if (location % width != 0 && world[w_lower+:2] !=  2'b11) // left
				begin 
					u_lower = (location-1)*16;
				end 
			else 
				begin 
					u_lower = location*16; 
				end 	
			in_2b <= cur_util[u_lower+:16]; 
			
			w_lower = (location +1)*2; 
			if ((location+1)%width != 0&& world[w_lower+:2] !=  2'b11) // right 
				begin 
					u_lower = (location+1)*16;
				end 
			else 
				begin 
				u_lower = location*16; 
				end 
			in_3b <= cur_util[u_lower+:16];
		end 
			 
		
		Left:
		begin 		
		//state 
			mult_ack <= 0; 
			state <= Multi; 
			
			start_multi <= 1; 
			cur_action <= 3'b001; // left 
			if ((location+1)%width != 0) 
				next_action <= 3'b010; // right; 
			else if (location == num_locations)
				next_action <= 3'b011; //update;
			else 
				next_action <= 3'b100; //check_type 
				
		//RTL 
			u_lower = (location-1)*16;
			in_1b <= cur_util[u_lower+:16];
		
			w_lower = (location -width)*2; 
			if ((location-width) >= 0 && world[w_lower+:2] !=  2'b11) // up
				begin 
					u_lower = (location-width)*16;
				end 
			else 
				begin 
					u_lower = location*16;  
				end 
				
			in_2b <= cur_util[u_lower+:16];
			w_lower = (location+width)*2; 
			if ((location+width)  <= num_locations && world[w_lower+:2] !=  2'b11 ) // down
				begin 
					u_lower = (location+width)*16;
				end 
			else 
				begin 
					u_lower = location*16; 
				end 
				
			in_3b <= cur_util[u_lower+:16];
			
		end 

		
		Right: 
		begin 
		//state 
			mult_ack <= 0; 
			state <= Multi; 
			cur_action <= 2'b10; // right 
			next_action <= 3'b100; // check_type 
		//RTL 
			start_multi <= 1; 
			u_lower = (location+1)*16;
			in_1b <= cur_util[u_lower+:16];
			
			w_lower = (location-width)*2; 
			if ((location-width) >= 0 && world[w_lower+:2] !=  2'b11) // up
				begin 
					u_lower = (location-width)*16;
				end 
			else 
				begin 
					u_lower = location*16; 
				end 				
			in_2b <= cur_util[u_lower+:16];
			
			w_lower = (location+width)*2; 
			if ((location+4)  <= num_locations && world[w_lower+:2] !=  2'b11) // down
				begin 
					u_lower = (location+width)*16;
				end 
			else 
				begin 
					u_lower = location*16; 
				end 
			in_3b <= cur_util[u_lower+:16];
		end 
		
		Update: 
		begin 
		//state 
			add_ack <= 0 ; 
			mult_ack <= 0;  
			location <= 0; 
			if(iteration == 1 && i == num_locations) 
			begin
				state <= Done; 
			end
			else if (i == num_locations)
			begin
				iteration <= iteration - 1; 
				state <= Check_type; 
			end 	
				
		// RTL
			// updating the cur_utilities 
				u_lower = i*16;
				cur_util[u_lower+:16] <= new_max[i]; 
				i = i + 1;
		end 
		Done: 
		begin 
		MDP_done <= 1; 
		if (ack == 1) 
			state <= Init; 
		//if (cont == 1)
			//state <= Continue; 
		end 
		
		default: 
		begin 
			state <= Done; 
		end 
		
	endcase 
	end 
end 

endmodule
