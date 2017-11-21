`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Final 
// Author: Christian Wagner, Neil Mehta 
// Date: 11/30/16
//////////////////////////////////////////////////////////////////////////////////
module vga_demo(ClkPort, vga_h_sync, vga_v_sync, vga_r_0, vga_g_0, vga_b_0, vga_r_1, vga_g_1, vga_b_1, vga_r_2, vga_g_2, Sw0, Sw1, Sw2, Sw3, Sw4, Sw5, Sw6, Sw7, btnU, btnD, btnL, btnR, btnC,
	St_ce_bar, St_rp_bar, Mt_ce_bar, Mt_St_oe_bar, Mt_St_we_bar,
	An0, An1, An2, An3, Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp,
	LD0, LD1, LD2, LD3, LD4, LD5, LD6, LD7, input_rows, input_cols);
	input ClkPort, Sw0, btnU, btnD, btnR, btnL, btnC, Sw0, Sw1, Sw2, Sw3, Sw4, Sw5, Sw6, Sw7, input_rows, input_cols;
	output St_ce_bar, St_rp_bar, Mt_ce_bar, Mt_St_oe_bar, Mt_St_we_bar;
	output vga_h_sync, vga_v_sync, vga_r_0, vga_g_0, vga_b_0, vga_r_1, vga_g_1, vga_b_1, vga_r_2, vga_g_2;
	output An0, An1, An2, An3, Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp;
	output LD0, LD1, LD2, LD3, LD4, LD5, LD6, LD7;
	reg vga_r_0, vga_g_0, vga_b_0, vga_r_1, vga_g_1, vga_b_1, vga_r_2, vga_g_2;
	
	//////////////////////////////////////////////////////////////////////////////////////////
	
	/*  LOCAL SIGNALS */
	wire	reset, start, ClkPort, board_clk, clk, button_clk, grid_clk, reg_clk;
	
	`define Initial_state 10'b0000000001  
	
`define Num_iter     10'b0000000010  // 1 
`define Get_width    10'b0000000100  // 2
`define Get_depth    10'b0000001000  // 2 
`define Location     10'b0000010000  // 3
`define Type         10'b0000100000  // 4 
`define MDP          10'b0001000000  
`define MDP_finish   10'b0010000000
`define Unpack       10'b0100000000
`define Done_state   10'b1000000000  // 5 
	
	BUF BUF1 (board_clk, ClkPort); 	
	BUF BUF2 (reset, Sw0);
	
	reg [27:0]	DIV_CLK;
	always @ (posedge board_clk, posedge reset)  
	begin : CLOCK_DIVIDER
      if (reset)
			DIV_CLK <= 0;
      else
			DIV_CLK <= DIV_CLK + 1'b1;
	end	

	assign	button_clk = DIV_CLK[18];
	assign	clk = DIV_CLK[1];
	assign 	{St_ce_bar, St_rp_bar, Mt_ce_bar, Mt_St_oe_bar, Mt_St_we_bar} = {5'b11111};
	
	wire inDisplayArea;
	wire [9:0] CounterX;
	wire [9:0] CounterY;
	wire [9:0] state_user;
	wire [63:0] world;
	wire [47:0] conv_1;
	wire [47:0] conv_2;
	wire [63:0] policy;
	wire user_init; 
	reg [7:0] num;
	wire conversion_flag;
	wire [7:0] width, depth;
	

	always@(posedge clk)
		begin
			num = {1'b0,Sw7,Sw6,Sw5,Sw4,Sw3,Sw2,Sw1};
		end
		
	reg [11:0] negs     = 0; 
	reg [11:0] ones_1   = 0;
	reg [11:0] zeros_1  = 0;
	reg [11:0] zeros_4  = 0;
	reg [11:0] zeros_5  = 0;
	reg [11:0] ones_4   = 0; 
	reg [11:0] twos     = 0;
	reg [11:0] threes   = 0;
	reg [11:0] fours    = 0;
	reg [11:0] fives_4  = 0;
	reg [11:0] fives_5  = 0;
	reg [11:0] sixes    = 0;
	reg [11:0] sevens   = 0;
	reg [11:0] eights   = 0;
	reg [11:0] nines    = 0;
	reg [11:0] dots     = 0;
	reg [11:0] policy_up= 0;
	reg [11:0] policy_rt= 0;
	reg [11:0] policy_dn= 0;
	reg [11:0] policy_lt= 0;
	reg [11:0] wall     = 0;
	reg [11:0] pos_reward = 0;
	reg [11:0] neg_reward = 0;
	
//--------------------------------------------------------------------------------------------
//--------------------------------- instantionations -----------------------------------------
//--------------------------------------------------------------------------------------------	

	hvsync_generator syncgen(.clk(clk), .reset(reset),.vga_h_sync(vga_h_sync), .vga_v_sync(vga_v_sync), .inDisplayArea(inDisplayArea), .CounterX(CounterX), .CounterY(CounterY));
	
	ee201_debouncer #(.N_dc(25)) debounce_up 
        (.CLK(clk), .RESET(reset), .PB(btnU), .DPB( ), .SCEN(SCEN_U), .MCEN( ), .CCEN( ));
		  
   ee201_debouncer #(.N_dc(25)) debounce_dn 
        (.CLK(clk), .RESET(reset), .PB(btnD), .DPB( ), .SCEN(SCEN_D), .MCEN( ), .CCEN( ));
		 
	ee201_debouncer #(.N_dc(25)) debounce_rt
        (.CLK(clk), .RESET(reset), .PB(btnR), .DPB( ), .SCEN(SCEN_R), .MCEN( ), .CCEN( ));
		  
	ee201_debouncer #(.N_dc(25)) debounce_lt
        (.CLK(clk), .RESET(reset), .PB(btnL), .DPB( ), .SCEN(SCEN_L), .MCEN( ), .CCEN( ));
		  
	ee201_debouncer #(.N_dc(25)) debounce_cr
        (.CLK(clk), .RESET(reset), .PB(btnC), .DPB( ), .SCEN(SCEN_C), .MCEN( ), .CCEN( ));
	
	wire [511:0] raw_utilities; 
	user_input interface(.clk(clk), .Reset(Sw0), .Left(SCEN_L), .Right(SCEN_R), .Up(SCEN_U), 
	.Down(SCEN_D), .Num_in(num), .Converted_1(conv_1), .Converted_2(conv_2), 
	.Policy(policy), .Done(conversion_flag), .world(world), .state(state_user), .Current_Utilities(raw_utilities) );
	
	/////////////////////////////////////////////////////////////////
	///////////////		VGA control starts here		/////////////////
	/////////////////////////////////////////////////////////////////
	reg [9:0] position;
	
	always @(posedge DIV_CLK[21])
		begin
			if(reset)
				position<=240;
			else if(btnD && ~btnU)
				position<=position+2;
			else if(btnU && ~btnD)
				position<=position-2;	
		end

//--------------------------------------------------------------------------------------------
//--------------------------------- wire assignment  -----------------------------------------
//--------------------------------------------------------------------------------------------	

			
			wire R = neg_reward || wall || grid_value || negs || ones_1 || ones_4 || zeros_1 ||zeros_4 || zeros_5 || dots || twos || threes || fours || fives_4 || fives_5 || sixes || sevens || eights || nines ||policy_up || policy_rt || policy_lt || policy_dn ;
			wire G = pos_reward || wall || grid_value || negs || ones_1 || ones_4 || zeros_1 ||zeros_4 || zeros_5 || dots || twos || threes || fours || fives_4 || fives_5 || sixes || sevens || eights || nines ||policy_up || policy_rt || policy_lt || policy_dn ;
			wire B = wall || grid_value || negs || ones_1 || ones_4 || zeros_1 ||zeros_4 || zeros_5 || dots || twos || threes || fours || fives_4 || fives_5 || sixes || sevens || eights || nines ||policy_up || policy_rt || policy_lt || policy_dn ;
		
 

		
		reg [31:0] orig_x_val [4:0];
		reg [31:0] orig_y_val [2:0];
		reg R_value;
		reg G_value;
		reg B_value;
		wire [2:0] cols = 4;
		wire [2:0] rows = 3;
		reg [59:0] loc_val;
		
			
		
//--------------------------------------------------------------------------------------------
//--------------------------------- digit_location assignment --------------------------------
//--------------------------------------------------------------------------------------------	
			initial
			begin
				orig_x_val[0] = 42;
				orig_x_val[1] = 62;
				orig_x_val[2] = 79;
				orig_x_val[3] = 83;
				orig_x_val[4] = 103;
				orig_y_val[0] = 67;
				orig_y_val[1] = 227;
				orig_y_val[2] = 387;
			end
			
			reg [32:0] digit_loc_x [59:0];
			reg [32:0] digit_loc_y [59:0];
			reg [32:0] policy_loc_x [47:0];
			reg [32:0] policy_loc_y [47:0];
			reg [32:0] corner_loc_x [11:0];
			reg [32:0] corner_loc_y [11:0];
			
			integer k, h, g, j;
			
			initial
			begin: definitions
				
					for ( k = 0 ; k <= 2; k = k + 1)
						begin
							for ( h = 0; h <= 3; h = h + 1)
								begin
									digit_loc_x[(k*20)+(h*5)]   	= 42+h*160-k*5 ;
									digit_loc_x[(k*20)+1+(h*5)] 	= 62+h*160-k*5 ;
									digit_loc_x[(k*20)+2+(h*5)] 	= 79+h*160-k*5 ;
									digit_loc_x[(k*20)+3+(h*5)] 	= 83+h*160-k*5 ;
									digit_loc_x[(k*20)+4+(h*5)] 	= 113+h*160-k*5 ;
									policy_loc_x[(k*16)+(h*4)]  	= 80+h*160 ;
									policy_loc_x[(k*16)+1+(h*4)]  = 140+h*160 ;
									policy_loc_x[(k*16)+2+(h*4)]  = 80+h*160 ;
									policy_loc_x[(k*16)+3+(h*4)]  = 20+h*160 ;
									corner_loc_x[(4*k)+h]         = 0+h*160;
								end
							for ( g = 0; g <= 19; g = g + 1)
								begin
									digit_loc_y[(k*20)+g] = 67 + k*160 ;
								end
							for ( j = 0; j <= 3; j = j + 1)
								begin
									policy_loc_y[(k*16)+(j*4)]  	= 10+k*160 ;
									policy_loc_y[(k*16)+1+(j*4)]  = 70+k*160 ;
									policy_loc_y[(k*16)+2+(j*4)]  = 120+k*160 ;
									policy_loc_y[(k*16)+3+(j*4)]  = 70+k*160 ;
								end
									corner_loc_y[(k*4)]         = k*160;
									corner_loc_y[(k*4)+1]       = k*160;
									corner_loc_y[(k*4)+2]       = k*160;
									corner_loc_y[(k*4)+3]       = k*160;
						end
			end

//--------------------------------------------------------------------------------------------
//--------------------------------- grdi drawing ---------------------------------------------
//--------------------------------------------------------------------------------------------	
		reg [4:0] grid_val;
		reg grid_value;
		initial
			begin: grid_draw
				grid_value = 0;
				grid_val[0] = CounterX>=155 && CounterX<=165;
				grid_val[1] = CounterX>=315 && CounterX<=325;
				grid_val[2] = CounterX>=475 && CounterX<=485;
				grid_val[3] = CounterY>=155 && CounterY<=165;
				grid_val[4] = CounterY>=315 && CounterY<=325;
			end
		always @(*) //draws the gird 
			begin
				grid_value = grid_val[0] || grid_val[1] || grid_val[2] || grid_val[3] || grid_val[4];
			end
			
//--------------------------------------------------------------------------------------------
//--------------------------------- digit_location logic assignment --------------------------
//--------------------------------------------------------------------------------------------
	
		integer i;	
		always@(CounterX, CounterY) // draws the numbers 
			begin: building_wire
				reg [32:0] draw_point [1:0]; 
				for (i = 0; i <= 11; i = i + 1)
					begin
					
					 // Wall
					 
						if(world[(i*2)+:2] == 2'b11)
							begin
								draw_point[1] = corner_loc_x[i];
								draw_point[0] = corner_loc_y[i];
								wall[i]       = CounterX>=draw_point[1] && CounterX<=draw_point[1]+160 && CounterY>=draw_point[0] && CounterY<=draw_point[0]+160;
							end
						else 
								wall[i] = 0;
						
					 // One 
						draw_point[1] = digit_loc_x[(i*5)];
						draw_point[0] = digit_loc_y[(i*5)];
						if (world[(i*2)+:2] == 2'b10)
						begin 
							negs[i]   =(CounterX>=draw_point[1] && CounterX<=draw_point[1]+15 && CounterY>=draw_point[0]+10 && CounterY<=draw_point[0]+15);
						end 
						else 
							negs[i] = 0;
							
					// 2 
						draw_point[1] = digit_loc_x[(i*5+1)];
						draw_point[0] = digit_loc_y[(i*5+1)];
						if(world[(i*2)+:2] == 2'b10 || world[i*2+:2] == 2'b01)
						begin 		
								ones_1[i] =  (CounterX>=draw_point[1] && CounterX<=draw_point[1]+5 && CounterY>=draw_point[0] && CounterY<=draw_point[0]+25);
								zeros_1[i] = 0; 
						end 
						else 
						begin 
								zeros_1[i] = (CounterX>=draw_point[1] && CounterX<=draw_point[1]+5 && CounterY>=draw_point[0] && CounterY<=draw_point[0]+25) || (CounterX>=draw_point[1]+10 && CounterX<=draw_point[1]+15 && CounterY>=draw_point[0] && CounterY<=draw_point[0]+25) || (CounterX>=draw_point[1] && CounterX<=draw_point[1]+15 && CounterY>=draw_point[0] && CounterY<=draw_point[0]+5) || (CounterX>=draw_point[1] && CounterX<=draw_point[1]+15 && CounterY>=draw_point[0]+20 && CounterY<=draw_point[0]+25);
								ones_1[i] = 0; 
						end 
						
						if(world[(i*2)+:2] == 2'b10)
							begin
								draw_point[1] = corner_loc_x[i];
								draw_point[0] = corner_loc_y[i];
								neg_reward[i] = CounterX>=draw_point[1] && CounterX<=draw_point[1]+160 && CounterY>=draw_point[0] && CounterY<=draw_point[0]+160;
							end
						if(world[(i*2)+:2] == 2'b01)
							begin
								draw_point[1] = corner_loc_x[i];
								draw_point[0] = corner_loc_y[i];
								pos_reward[i] = CounterX>=draw_point[1] && CounterX<=draw_point[1]+160 && CounterY>=draw_point[0] && CounterY<=draw_point[0]+160;
							end
					// 3
						 draw_point[1] = digit_loc_x[(i*5+2)];
						 draw_point[0] = digit_loc_y[(i*5+2)];
						 dots[i] = (CounterX>=draw_point[1] && CounterX<=draw_point[1]+2 && CounterY>=draw_point[0]+23 && CounterY<=draw_point[0]+25);
					
					// Four 
						 
						
					if (state_user != `Done_state)
						begin 
		
								zeros_4[i] = 0;
								ones_4[i]  = 0;
								twos[i]    = 0;
								threes[i]  = 0;
								fours[i]   = 0;
								fives_4[i] = 0;
								sixes[i]   = 0;
								sevens[i]  = 0;
								eights[i]  = 0;
								nines[i]   = 0;
								zeros_5[i] = 0;
								fives_5[i] = 0; 							
						end 
				
				 
					else 
					begin 
						
						draw_point[1] = digit_loc_x[(i*5+3)];
						draw_point[0] = digit_loc_y[(i*5+3)];
						if (conv_1[(i*4)+:4] == 4'b0000)
							begin
								 zeros_4[i] =  (CounterX>=draw_point[1] && CounterX<=draw_point[1]+5 && CounterY>=draw_point[0] && CounterY<=draw_point[0]+25) || (CounterX>=draw_point[1]+10 && CounterX<=draw_point[1]+15 && CounterY>=draw_point[0] && CounterY<=draw_point[0]+25) || (CounterX>=draw_point[1] && CounterX<=draw_point[1]+15 && CounterY>=draw_point[0] && CounterY<=draw_point[0]+5) || (CounterX>=draw_point[1] && CounterX<=draw_point[1]+15 && CounterY>=draw_point[0]+20 && CounterY<=draw_point[0]+25);
		
							end
						
						else if (conv_1[(i*4)+:4] == 4'b0001)
							begin
								ones_4[i] =  (CounterX>=draw_point[1] && CounterX<=draw_point[1]+5 && CounterY>=draw_point[0] && CounterY<=draw_point[0]+25);
							end
						
						else if (conv_1[(i*4)+:4] == 4'b0010)
							begin
								 twos[i] = ((CounterX>=draw_point[1] && CounterX<=draw_point[1]+10 && CounterY>=draw_point[0] && CounterY<=draw_point[0]+5) || (CounterX>=draw_point[1] && CounterX<=draw_point[1]+10 && CounterY>=draw_point[0]+10 && CounterY<=draw_point[0]+15) || (CounterX>=draw_point[1] && CounterX<=draw_point[1]+10 && CounterY>=draw_point[0]+20 && CounterY<=draw_point[0]+25) || (CounterX>=draw_point[1]+5 && CounterX<=draw_point[1]+10 && CounterY>=draw_point[0]+5 && CounterY<=draw_point[0]+10) || (CounterX>=draw_point[1] && CounterX<=draw_point[1]+5 && CounterY>=draw_point[0]+15 && CounterY<=draw_point[0]+20));
							end
						
						else if (conv_1[(i*4)+:4] == 4'b0011)
							begin
								 threes[i] = (CounterX>=draw_point[1]+5 && CounterX<=draw_point[1]+10 && CounterY>=draw_point[0] && CounterY<=draw_point[0]+25) || (CounterX>=draw_point[1] && CounterX<=draw_point[1]+10 && CounterY>=draw_point[0] && CounterY<=draw_point[0]+5) || (CounterX>=draw_point[1] && CounterX<=draw_point[1]+10 && CounterY>=draw_point[0]+10 && CounterY<=draw_point[0]+15) || (CounterX>=draw_point[1] && CounterX<=draw_point[1]+10 && CounterY>=draw_point[0]+20 && CounterY<=draw_point[0]+25);
							end
						
						else if (conv_1[(i*4)+:4] == 4'b0100)
							begin
								 fours[i] =(CounterX>=draw_point[1]+15 && CounterX<=draw_point[1]+20 && CounterY>=draw_point[0] && CounterY<=draw_point[0]+25) || (CounterX>=draw_point[1] && CounterX<=draw_point[1]+15 && CounterY>=draw_point[0]+10 && CounterY<=draw_point[0]+15) || (CounterX>=draw_point[1] && CounterX<=draw_point[1]+5 && CounterY>=draw_point[0] && CounterY<=draw_point[0]+15);
							end
						
						else if (conv_1[(i*4)+:4] == 4'b0101)
							begin
								 fives_4[i] = (CounterX>=draw_point[1] && CounterX<=draw_point[1]+10 && CounterY>=draw_point[0] && CounterY<=draw_point[0]+5) || (CounterX>=draw_point[1] && CounterX<=draw_point[1]+10 && CounterY>=draw_point[0]+10 && CounterY<=draw_point[0]+15) || (CounterX>=draw_point[1] && CounterX<=draw_point[1]+10 && CounterY>=draw_point[0]+20 && CounterY<=draw_point[0]+25) || (CounterX>=draw_point[1]+5 && CounterX<=draw_point[1]+10 && CounterY>=draw_point[0]+15 && CounterY<=draw_point[0]+20) || (CounterX>=draw_point[1] && CounterX<=draw_point[1]+5 && CounterY>=draw_point[0]+5 && CounterY<=draw_point[0]+10);
		
							end	
						
						else if (conv_1[(i*4)+:4] == 4'b0110)
							begin
								 sixes[i] = (CounterX>=draw_point[1] && CounterX<=draw_point[1]+5 && CounterY>=draw_point[0] && CounterY<=draw_point[0]+25) || (CounterX>=draw_point[1] && CounterX<=draw_point[1]+15 && CounterY>=draw_point[0]+20 && CounterY<=draw_point[0]+25) || (CounterX>=draw_point[1] && CounterX<=draw_point[1]+15 && CounterY>=draw_point[0]+10 && CounterY<=draw_point[0]+15) || (CounterX>=draw_point[1]+10 && CounterX<=draw_point[1]+15 && CounterY>=draw_point[0]+10 && CounterY<=draw_point[0]+25);
		
							end
						
						else if (conv_1[(i*4)+:4] == 4'b0111)
							begin
								 sevens[i] =  (CounterX>=draw_point[1]+10 && CounterX<=draw_point[1]+15 && CounterY>=draw_point[0] && CounterY<=draw_point[0]+25) || (CounterX>=draw_point[1] && CounterX<=draw_point[1]+15 && CounterY>=draw_point[0] && CounterY<=draw_point[0]+5); 
		
							end
						
						else if (conv_1[(i*4)+:4] == 4'b1000)
							begin
								 eights[i] = (CounterX>=draw_point[1] && CounterX<=draw_point[1]+5 && CounterY>=draw_point[0] && CounterY<=draw_point[0]+25) || (CounterX>=draw_point[1]+10 && CounterX<=draw_point[1]+15 && CounterY>=draw_point[0] && CounterY<=draw_point[0]+25) || (CounterX>=draw_point[1] && CounterX<=draw_point[1]+15 && CounterY>=draw_point[0] && CounterY<=draw_point[0]+5) || (CounterX>=draw_point[1] && CounterX<=draw_point[1]+15 && CounterY>=draw_point[0]+10 && CounterY<=draw_point[0]+15) || (CounterX>=draw_point[1] && CounterX<=draw_point[1]+15 && CounterY>=draw_point[0]+20 && CounterY<=draw_point[0]+25);
							end
							
						else if (conv_1[(i*4)+:4] == 4'b1001)
							begin
								 nines[i] = (CounterX>=draw_point[1]+15 && CounterX<=draw_point[1]+20 && CounterY>=draw_point[0] && CounterY<=draw_point[0]+25) || (CounterX>=draw_point[1] && CounterX<=draw_point[1]+15 && CounterY>=draw_point[0]+10 && CounterY<=draw_point[0]+15) || (CounterX>=draw_point[1] && CounterX<=draw_point[1]+5 && CounterY>=draw_point[0] && CounterY<=draw_point[0]+15) || (CounterX>=draw_point[1] && CounterX<=draw_point[1]+15 && CounterY>=draw_point[0] && CounterY<=draw_point[0]+5);
		
							end
					 
					
					// Five 
						 
						if (conv_2[(i*4)+:4] == 4'b0000)
							begin
									draw_point[1] = digit_loc_x[(i*5+4)];
									draw_point[0] = digit_loc_y[(i*5+4)];
								 zeros_5[i] =  (CounterX>=draw_point[1] && CounterX<=draw_point[1]+5 && CounterY>=draw_point[0] && CounterY<=draw_point[0]+25) || (CounterX>=draw_point[1]+10 && CounterX<=draw_point[1]+15 && CounterY>=draw_point[0] && CounterY<=draw_point[0]+25) || (CounterX>=draw_point[1] && CounterX<=draw_point[1]+15 && CounterY>=draw_point[0] && CounterY<=draw_point[0]+5) || (CounterX>=draw_point[1] && CounterX<=draw_point[1]+15 && CounterY>=draw_point[0]+20 && CounterY<=draw_point[0]+25);
		
							end
						
						else if (conv_2[(i*4)+:4] == 4'b0101)
							begin
									draw_point[1] = digit_loc_x[(i*5+4)];
									draw_point[0] = digit_loc_y[(i*5+4)];
								 fives_5[i] = (CounterX>=draw_point[1] && CounterX<=draw_point[1]+10 && CounterY>=draw_point[0] && CounterY<=draw_point[0]+5) || (CounterX>=draw_point[1] && CounterX<=draw_point[1]+10 && CounterY>=draw_point[0]+10 && CounterY<=draw_point[0]+15) || (CounterX>=draw_point[1] && CounterX<=draw_point[1]+10 && CounterY>=draw_point[0]+20 && CounterY<=draw_point[0]+25) || (CounterX>=draw_point[1]+5 && CounterX<=draw_point[1]+10 && CounterY>=draw_point[0]+15 && CounterY<=draw_point[0]+20) || (CounterX>=draw_point[1] && CounterX<=draw_point[1]+5 && CounterY>=draw_point[0]+5 && CounterY<=draw_point[0]+10);
		
							end	
	
					// UP 
						draw_point[1] = policy_loc_x[i*4];
						draw_point[0] = policy_loc_y[i*4];
						
						if (policy[(i*2)+:2] == 2'b11 && world[(i*2)+:2] != 2'b10 && world[(i*2)+:2] != 2'b01)
							policy_up[i]  =(CounterX>=draw_point[1] && CounterX<=draw_point[1]+5 && CounterY>=draw_point[0]+20 && CounterY<=draw_point[0]+25);
						
					// Right 
						draw_point[1] = policy_loc_x[i*4+1];
						draw_point[0] = policy_loc_y[i*4+1];
						if (policy[(i*2)+:2] == 2'b10 && world[(i*2)+:2] != 2'b10 && world[(i*2)+:2] != 2'b01)
						policy_rt[i]  = (CounterX>=draw_point[1] && CounterX<=draw_point[1]+5 && CounterY>=draw_point[0]+20 && CounterY<=draw_point[0]+25);
						
					// Down 	
						draw_point[1] = policy_loc_x[i*4+2];
						draw_point[0] = policy_loc_y[i*4+2];
						if (policy[(i*2)+:2] == 2'b00 && world[(i*2)+:2] != 2'b10 && world[(i*2)+:2] != 2'b01)
							policy_dn[i]  =(CounterX>=draw_point[1] && CounterX<=draw_point[1]+5 && CounterY>=draw_point[0]+20 && CounterY<=draw_point[0]+25);
						
					// LEFT 	
						draw_point[1] = policy_loc_x[i*4+3];
						draw_point[0] = policy_loc_y[i*4+3];
						if (policy[(i*2)+:2] == 2'b01 && world[(i*2)+:2] != 2'b10 && world[(i*2)+:2] != 2'b01)
							policy_lt[i]  = (CounterX>=draw_point[1] && CounterX<=draw_point[1]+5 && CounterY>=draw_point[0]+20 && CounterY<=draw_point[0]+25);
					end 
				end
			end

//--------------------------------------------------------------------------------------------
//--------------------------------- sensitive_to_user_input --------------------------------------------
//--------------------------------------------------------------------------------------------


	always @(posedge DIV_CLK[2])
	begin
		vga_r_0 <= R & inDisplayArea;
		vga_g_0 <= G & inDisplayArea;
		vga_b_0 <= B & inDisplayArea;
		vga_b_1 <= B & inDisplayArea;
		vga_g_1 <= G & inDisplayArea;
		vga_g_2 <= G & inDisplayArea;
		vga_r_1 <= R & inDisplayArea;
		vga_r_2 <= R & inDisplayArea;
	end
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  VGA control ends here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  LD control starts here 	 ///////////////////
	/////////////////////////////////////////////////////////////////

	wire LD0, LD1, LD2, LD3, LD4, LD5, LD6, LD7;
	
	assign LD0 = 0;
	assign LD1 = 0;
	
	assign LD2 = start;
	assign LD4 = conversion_flag;
	
	assign LD3 = 0;
	assign LD5 = (state_user == `Initial_state);	
	assign LD6 = (state_user == `MDP);
	assign LD7 = (state_user == `Done_state);
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  LD control ends here 	 	////////////////////
	/////////////////////////////////////////////////////////////////
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  SSD control starts here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
	reg 	[3:0]	SSD;
	wire 	[3:0]	SSD0, SSD1, SSD2, SSD3;
	wire 	[1:0] ssdscan_clk;
	
	
	assign SSD3 = (state_user == `Initial_state) ? 4'b0000 : (state_user == `Num_iter) ? 4'b0001 : 
	(state_user == `Get_width) || (state_user == `Get_depth) ? 4'b0010 : 
	(state_user == `Location) ? 4'b0011 : 
	(state_user == `Type) ? 4'b0100 : 
	(state_user == `Done_state) ? 4'b0101: 4'b1111 ; 
		
	assign SSD2 = (state_user == `Type) ? {1'b0,1'b0,Sw2,Sw1} : 4'b1111;//conv_1[(5*4)+:4];
	assign SSD1 = {21'b0,Sw7,Sw6,Sw5};
	assign SSD0 = {Sw4,Sw3,Sw2,Sw1}; 
	/*
	assign SSD0 =  raw_utilities[(16*2+4)+:4];
	assign SSD1 =  raw_utilities[(16*2+4)+:4]; 
	assign SSD2 =  raw_utilities[(16*2+8)+:4]; 
	assign SSD3 =  raw_utilities[(16*2+12)+:4]; */
		
	// need a scan clk for the seven segment display 
	// 191Hz (50MHz / 2^18) works well
	assign ssdscan_clk = DIV_CLK[19:18];	
	assign An0	= (state_user == `Type) || !(~(ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 00
	assign An1	= (state_user == `Type) || !(~(ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 01
	assign An2	= !( (ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 10
	assign An3	= !( (ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 11
	
	always @ (ssdscan_clk, SSD0, SSD1, SSD2, SSD3)
	begin : SSD_SCAN_OUT
		case (ssdscan_clk) 
			2'b00:
					SSD = SSD0;
			2'b01:
					SSD = SSD1;
			2'b10:
					SSD = SSD2;
			2'b11:
					SSD = SSD3;
		endcase 
	end	

	// and finally convert SSD_num to ssd
	reg [6:0]  SSD_CATHODES;
	assign {Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp} = {SSD_CATHODES, 1'b1};
	// Following is Hex-to-SSD conversion
	always @ (SSD) 
	begin : HEX_TO_SSD
		case (SSD)		
			4'b1111: SSD_CATHODES = 7'b1111111 ; //Nothing 
			4'b0000: SSD_CATHODES = 7'b0000001 ; //0
			4'b0001: SSD_CATHODES = 7'b1001111 ; //1
			4'b0010: SSD_CATHODES = 7'b0010010 ; //2
			4'b0011: SSD_CATHODES = 7'b0000110 ; //3
			4'b0100: SSD_CATHODES = 7'b1001100 ; //4
			4'b0101: SSD_CATHODES = 7'b0100100 ; //5
			4'b0110: SSD_CATHODES = 7'b0100000 ; //6
			4'b0111: SSD_CATHODES = 7'b0001111 ; //7
			4'b1000: SSD_CATHODES = 7'b0000000 ; //8
			4'b1001: SSD_CATHODES = 7'b0000100 ; //9
			4'b1010: SSD_CATHODES = 7'b0001000 ; //10 or A
			4'b1011: SSD_CATHODES = 7'b1100000; // B
			4'b1100: SSD_CATHODES = 7'b0110001; // C
			4'b1101: SSD_CATHODES = 7'b1000010; // D
			4'b1110: SSD_CATHODES = 7'b0110000; // E  
			default: SSD_CATHODES = 7'bXXXXXXX ; // default is not needed as we covered all cases
		endcase
	end
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  SSD control ends here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
endmodule
