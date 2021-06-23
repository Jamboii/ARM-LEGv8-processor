`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/04/2020 04:34:51 AM
// Design Name: 
// Module Name: cache_test
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module cache_test;

reg [23:0] address, data;
reg mode, clk;
wire [23:0] out;
wire status;
wire addBlock;

processor tb (
    .address(address),
    .data(data),
    .mode(mode),
    .clk(clk),
    .out(out),
    .status(status),
    .addBlock(addBlock)
);

// integer data_file;
// integer scan_file;
integer fd;
integer temp;
// integer code, dummy;
integer idx = 0;
integer missCount = 0;
integer hitCount = 0;
reg [31:0] missRate;
real result;

reg [23:0] traceData[59999:0];
reg [23:0] parsedAddress;
reg [23:0] flippedAddress;
reg [7:0] byte1, byte2, byte3;
reg [23:0] dataMem = 0;


initial begin
    clk = 1'b1;

    // $readmemb("TRACE1.DAT",mem);
    fd = $fopen("TRACE1.DAT","rb");
    temp = $fread(traceData, fd);
    $fclose(fd);
    
    // $display("THIS IS THE DATA = %x",traceData[1][7:0]);
    
    /*
    address = traceData[idx];
    // from left to right: byte1+byte2+byte3
    byte1 = address[7:0];
    byte2 = address[15:8];
    byte3 = address[23:16];
    
    flippedAddress = {byte1,byte2,byte3};
    */
    
    // $display("address = %x, flipped = %x",address,flippedAddress);
    
end // initial begin


always @(posedge clk) begin
    parsedAddress = traceData[idx];
    // from left to right: byte1+byte2+byte3
    byte1 = parsedAddress[7:0];
    byte2 = parsedAddress[15:8];
    byte3 = parsedAddress[23:16];
    
    flippedAddress = {byte1,byte2,byte3};
    // $display("address = %x, flipped = %x",parsedAddress,flippedAddress);
    
    #50
    // serve up flipped address to cache
    address = flippedAddress;
    data = idx;
    mode = 1'b1;
    
    #50
    // serve up flipped address to cache
    address = flippedAddress;
    data = idx;
    mode = 1'b0;
    
    // increment index
    idx = idx + 1;
    
    if (idx == 57961) begin
        $display("TRACE FILE FINSHED PARSING");
        missRate = $itor(missCount) / $itor(idx);
        result = $itor(missCount) / $itor(idx);
        $display("misses = %d, miss rate = %f",missCount,result);
        $finish;
    end
    
    #50
    
    if (status == 0) begin
        missCount = missCount + 1;
    end
end

    
/*
initial begin
	clk = 1'b1;
	
	// writing
	
    address = 24'habcdef; // 1 "110 1" 111
	data = 24'h123456;
	mode = 1'b1;
	
	// #200
	#50
	address = 24'h654321; // 0 "010 0" 001
	data = 24'hfedcba;
	mode = 1'b1;
	
	// #200
	#50
	address = 24'h567890; // 0000
	data = 24'h987654;
	mode = 1'b1;
	
	#50
	address = 24'h123490;
	data = 24'h133769;
	mode = 1'b1;
	
	#50
	address = 24'h468090;
	data = 24'h420337;
	mode = 1'b1;
	
	#50
	address = 24'h783490;
	data = 24'h420009;
	mode = 1'b1;
	
	
	// reading
	
	// #200
	#50
	address = 24'habcdef;  // 1 "110 1" 111
	data = 24'h123456;     // 0 "101 0" 110
	mode = 1'b0;
	
	// #200
	#50
	address = 24'h654321; // 0 "010 0" 001
	data = 24'hfedcba;    // 1 "011 1" 010
	mode = 1'b0;
	
	// #200
	#50
	address = 24'h567890; // 1 "001 0" 000
	data = 24'h987654;
	mode = 1'b0;
	
    #50
	address = 24'h123490;
	data = 24'h133769;
	mode = 1'b0;
	
	#50
	address = 24'h468090;
	data = 24'h420337;
	mode = 1'b0;
	
    #50
	address = 24'h783490;
	data = 24'h420009;
	mode = 1'b0;
	
	#50
	address = 24'h468090;
	data = 24'h420337;
	mode = 1'b0;
	
	#50
	if (status == 1'b1)
	   hitCount = hitCount + 1;
	
	
	address = 24'habcdef;  // 1 "110 1" 111
	data = 24'h123456;     // 0 "101 0" 110
	mode = 1'b0;
	
	#50
	if (status == 1'b1)
	   hitCount = hitCount + 1;
	   
	$display("HITS = %d",hitCount);
	
end
*/

initial $monitor("address = %d data = %x mode = %d out = %x\n", address, data, mode, out);

always #25 clk = ~clk;

endmodule
