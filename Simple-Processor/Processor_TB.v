`timescale 1ns / 1ps

module Processor_TB;

	// INPUT
	reg CLK;
	reg RESET;
	
	// OUTPUT
	wire [2:0] OPCODE;
	wire [4:0] STATE;
	wire [11:0] PC, A, MA;
	wire [15:0] IR, AC, MD; //memory_mon, memory_mon_2;
	
	// MEMORY Register
	reg [15:0] MEMORY [0:4095];
	
	// ZERO Instruction
    parameter ZERO = 16'b0000000000000000;

	// Unit Under Test
	Processor uut1 (
		.CLK(CLK), 
		.RESET(RESET),
		.STATE(STATE),
		.OPCODE(OPCODE),
		.IR(IR),
		.PC(PC),
		.A(A),
		.AC(AC),
		.MD(MD),
		.MA(MA),
		//.memory_mon(memory_mon),
		//.memory_mon_2(memory_mon_2)
	);
	
	initial begin
		// Reads memory from memory file
		$readmemb("Memory.mem", MEMORY);
		// Initialize clock and reset to start processor
		CLK = 1;
		RESET = 1; #1000
		RESET = 0;
	end
	
	// Start clock
	always @(CLK)#500 CLK <= ~CLK;
endmodule
