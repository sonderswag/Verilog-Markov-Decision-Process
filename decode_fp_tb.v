`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:01:54 11/24/2016 
// Design Name: 
// Module Name:    fp_single_multiplier_tb 
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
module decode_fp_tb(
    );

//Inputs
reg sys_clk_tb;
reg Reset_tb;
reg start_tb; 
reg [15:0] fp_in_tb; 
reg Ack_tb; 
//Outputs 
wire [3:0] Decode_1_tb, Decode_2_tb; 
wire done_tb;

decode_fp UUT(
	.Reset(Reset_tb), 
	.Clk(sys_clk_tb), 
	.Start(start_tb), 
	.Ack(Ack_tb), 
	.Fp_in(fp_in_tb), 
	.Done(done_tb), 
	.Decode_1(Decode_1_tb),
	.Decode_2(Decode_2_tb)
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
fp_in_tb = 16'b0011100100100000; //.2
@(posedge sys_clk_tb) 
@(posedge sys_clk_tb)
@(posedge sys_clk_tb) 
@(posedge sys_clk_tb)
@(posedge sys_clk_tb) 
@(posedge sys_clk_tb)
start_tb = 1; 
Ack_tb <= 0;
@(posedge sys_clk_tb) 
@(posedge sys_clk_tb)
start_tb = 0 ;

 end 
endmodule

