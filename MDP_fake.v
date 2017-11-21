`timescale 1ns / 1ps
module MDP_fake(start, MDP_done, cur_util, policy);
	
output reg[511:0] cur_util; 
output reg[63:0] policy;
output reg MDP_done; 
input start; 

initial
begin 
	MDP_done = 0; 
end 
always@(start)
begin 
    cur_util = {16'b0011101110011001, 16'b0000000000000000,16'b0011101110011001, 16'b0000000000000000, 16'b0011010110011001, 16'b0011001001100110, 16'b0010111001100110,16'b0011101110011001, 16'b0000000000000000, 16'b0011010110011001, 16'b0011001001100110, 16'b0010111001100110,16'b0011101110011001, 16'b0000000000000000, 16'b0011010110011001, 16'b0011001001100110, 16'b0010111001100110,16'b0011101110011001, 16'b0000000000000000, 16'b0011010110011001, 16'b0011001001100110, 16'b0010111001100110,16'b0011101110011001, 16'b0000000000000000, 16'b0011010110011001, 16'b0011001001100110, 16'b0010111001100110, 16'b0011101110011001, 16'b0000000000000000, 16'b0011010110011001, 16'b0011001001100110, 16'b0010111001100110};
	policy = 0;//{1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b1,1'b1,1'b0,1'b1,1'b1,1'b1,1'b0,1'b0,1'b1,1'b1,1'b0,1'b0,1'b1,1'b1,1'b0,1'b0,1'b1,1'b0,1'b1,1'b0,1'b1,1'b0};
	MDP_done = 1; 
end 
	
endmodule 