`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:35:59 11/24/2016 
// Design Name: 
// Module Name:    MD_state_machine_tb 
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
module MD_state_machine_tb(
    );

reg sys_clk_tb;
reg Reset_tb;
reg start_tb;
reg cont_tb; 
reg[7:0] iteration_tb = 10; 
reg [7:0] depth = 3; 
reg [7:0] width = 4; 
reg ack_tb; 
reg [15:0] noise_tb     = 16'b0011101001100110;
reg [15:0] inv_noise_tb = 16'b0010111001100110; 
reg [15:0] discount_tb  = 16'b0011101100110011; 

wire update_tb; 
wire [511:0] cur_util_tb; 
wire [63:0] policy_tb; 
reg [1:0] policy_upacked[31:0]; 
reg [15:0]cur_util_upacked[31:0]; 
reg [63:0] world;  
/*
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
	
*/ 
initial 
begin 
	world[1:0]   = 2'b00; // 0
	world[3:2]   = 2'b00; // 1
	world[5:4]   = 2'b00; // 2 
	world[7:6]   = 2'b01; // 3 //positive
	world[9:8]   = 2'b00; // 4 
	world[11:10] = 2'b11; // 5 // wall
	world[13:12] = 2'b00; // 6 
	world[15:14] = 2'b10; // 7 // negative 
	world[17:16] = 2'b10; // 8
	world[19:18] = 2'b00; // 9
	world[21:20] = 2'b00; // 10
	world[23:22] = 2'b00; // 11
	world[25:24] = 2'b00; // 12
		
end 


always@(cur_util_tb)
begin: upack
integer i,j; 
for (i=0; i<(width*depth); i=i+1) 
	for (j=0; j < 16; j=j+1) 
		 cur_util_upacked[i][j] = cur_util_tb[j+i*16]; 

end 

always@(policy_tb)
begin: upack_p 
	integer i,j; 
	for (i=0; i<(width*depth); i=i+1)
		for (j=0; j<2; j=j+1)
			policy_upacked[i][j] = policy_tb[j+i*2]; 
end 

wire [12:0] state_tb; 

 MD_state_machine UUT(
	.clk(sys_clk_tb), 
	.Reset(Reset_tb), 
	.start(start_tb), 
	.iteration_in(iteration_tb), 
	.MDP_done(update_tb), 
	.ack(ack_tb), 
	.in_noise(noise_tb), 
	.in_inv_noise(inv_noise_tb), 
	.in_discount(discount_tb), 
	.cur_util(cur_util_tb), 
	.policy(policy_tb),
	.state(state_tb),
	.in_world(world),
	.in_depth(depth),
	.in_width(width),
	.cont(cont_tb)
    );
integer  Clk_cnt;
`define CLK_PERIOD 20
//CLK_GENERATOR
initial
  begin  : CLK_GENERATOR
    sys_clk_tb = 1;
    forever
       begin
	      #(`CLK_PERIOD /2) sys_clk_tb = ~sys_clk_tb;
       end 
  end

//RESET_GENERATOR
initial
  begin  : RESET_GENERATOR
    Reset_tb = 1'b1;
    #(`CLK_PERIOD * 5.1) Reset_tb = 1'b0;
  end
 

//CLK_COUNTER
initial
  begin  : CLK_COUNTER
    Clk_cnt = 0;
    forever
       begin
	      @(posedge sys_clk_tb) Clk_cnt = Clk_cnt + 1;
		 end 
  end 
 
//apply stimulous 
initial begin 

start_tb = 1; 
@(posedge sys_clk_tb) 
@(posedge sys_clk_tb)
@(posedge sys_clk_tb) 
@(posedge sys_clk_tb)
@(posedge sys_clk_tb) 
@(posedge sys_clk_tb)
start_tb = 0 ;

wait(update_tb);
ack_tb = 1; 
world[1:0]   = 2'b00; // 0
	world[3:2]   = 2'b00; // 1
	world[5:4]   = 2'b00; // 2 
	world[7:6]   = 2'b01; // 3 //positive
	world[9:8]   = 2'b00; // 4 
	world[11:10] = 2'b11; // 5 // wall
	world[13:12] = 2'b00; // 6 
	world[15:14] = 2'b11; // 7 // negative 
	world[17:16] = 2'b00; // 8
	world[19:18] = 2'b00; // 9
	world[21:20] = 2'b00; // 10
	world[23:22] = 2'b00; // 11
	world[25:24] = 2'b00; // 12
@(posedge sys_clk_tb) 
@(posedge sys_clk_tb)
@(posedge sys_clk_tb) 
@(posedge sys_clk_tb)
@(posedge sys_clk_tb) 
@(posedge sys_clk_tb)
start_tb = 1; 
@(posedge sys_clk_tb) 
@(posedge sys_clk_tb)
@(posedge sys_clk_tb) 
@(posedge sys_clk_tb)
@(posedge sys_clk_tb) 
@(posedge sys_clk_tb)
start_tb = 0 ;


 end 
 
 
reg [12*8:0] state_string; // 6-character string for symbolic display of state
always @(*)
		begin
			case ({state_tb})    // Note the concatenation operator {}
				13'b0000000000001 : state_string = "Init";
				13'b0000000000010 : state_string = "Up" ;
				13'b0000000000100 : state_string = "Down";
				13'b0000000001000 : state_string = "Left" ;
				13'b0000000010000 : state_string = "Right"; 
				13'b0000000100000 : state_string = "Update";
				13'b0000001000000 : state_string = "Done"; 
				13'b0000010000000 : state_string = "Check";
				13'b0000100000000 : state_string = "first_M";
				13'b0001000000000 : state_string = "Multi";
				13'b0010000000000 : state_string = "Add";
				13'b0100000000000 : state_string = "Continue";
				13'b1000000000000 : state_string = "world_builder";
				endcase
		end
		
/*
// Task to read the result from UUT and write it out to the output file, output_results.txt
	task read_C_Matrix;
		begin
			fileC = $fopen("output_results.txt", "w");
			$display("\n Result of C = A x B is\n");
			$fdisplay(fileC, "\n Result of C = A x B is\n");
			for (ind_m=0; ind_m<M_VALUE; ind_m=ind_m+1) // for all the rows in the matrix
				begin // for each row (there are p items in a row)
					string = "\n";
					for (ind_p=0; ind_p<P_VALUE; ind_p=ind_p+1)
						begin
							num_C[ind_m][ind_p] = UUT.C[ind_m][ind_p];
							$sformat(string, "%s\t%d", string, num_C[ind_m][ind_p]);
						end	
					$display("%s", string);
					$fwrite(fileC, "%s\n\n", string);
				end	
			$display ("\n Clocks_taken = %d . \n", Clocks_taken);
			$fdisplay (fileC, "\n Clocks_taken = %d . \n", Clocks_taken);
			$fclose(fileC);
		end
	endtask

*/		
		
endmodule
