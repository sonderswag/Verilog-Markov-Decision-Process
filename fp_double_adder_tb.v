`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:39:52 11/18/2016 
// Design Name: 
// Module Name:    fp_double_adder_tb 
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
module fp_double_adder_tb(
    );


//Inputs
reg sys_clk_tb;
reg Reset_tb;
reg start_tb; 
wire done_tb; 
reg [15:0] a_input; 
reg [15:0] b_input;
reg [15:0] c_input;

//Outputs 
wire [15:0] z_out; 
wire Z_ack_out;

 fp_double_adder UUT(
	.start(start_tb),
	.reset(Reset_tb),
	.input_a(a_input), 
	.input_b(b_input),
	.input_c(c_input),
	.output_z(z_out),
	.clk(sys_clk_tb),
	.ack(Z_ack_out),
	.done(done_tb)
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
a_input = 16'b1011000111000010; //.18
//a_input = 32'b10111111000000000000000000000000; //-.5
//b_input = 32'b10111111000000000000000000000000; //-.5
//c_input = 32'b00111111100000000000000000000000; //1
//a_input = 32'b00000000000000000000000000000000;
b_input = 16'b1011001001100110; //.2
c_input = 16'b1011100000000000; //-.5 
start_tb = 1; 
@(posedge sys_clk_tb) 
@(posedge sys_clk_tb)
start_tb = 0 ;

 end 
endmodule
