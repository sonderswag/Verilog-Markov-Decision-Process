`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:19:17 11/17/2016 
// Design Name: 
// Module Name:    fp_double_multiplier_tb 
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
module fp_double_multiplier_tb();

//Inputs
reg sys_clk_tb;
reg Reset_tb;
reg start_tb; 
reg [31:0] a_input; 
reg [31:0] b_input;
reg [31:0] c_input;

//Outputs 
wire [31:0] z_out; 
wire Z_ack_out;

 fp_double_multiplier UUT(
	.start(start_tb),
	.reset(Reset_tb),
	.input_a(a_input), 
	.input_b(b_input),
	.input_c(c_input),
	.output_z(z_out),
	.clk(sys_clk_tb),
	.z_ack(Z_ack_out)
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
a_input = 32'b10111111000000000000000000000000; //-.5
b_input = 32'b01000000001000000000000000000000; //2.5
c_input = 32'b10111111100000000000000000000000; //-1
start_tb = 1; 
@(posedge sys_clk_tb) 
@(posedge sys_clk_tb)
start_tb = 0 ;

 end 
endmodule
