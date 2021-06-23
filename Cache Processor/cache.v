`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/04/2020 02:48:59 AM
// Design Name: 
// Module Name: cache
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


module cache();

parameter numBlocks = 256;
parameter blocksPerSet = 16;
parameter numSets = 16;
parameter bitsPerBlock = 64;

parameter lenAddress = 24;
parameter lenOffset = 3; // 3 extra 0 bits at the end
parameter lenIndex = 4; // For the 16 blocks
parameter lenTag = lenAddress - lenOffset - lenIndex;

reg [bitsPerBlock-1:0] cache [numSets-1:0][blocksPerSet-1:0];   // Holds all blocks for cache data
reg [lenTag-1:0] tag_array [numSets-1:0][blocksPerSet-1:0];     // Holds all tags in cache
reg valid_array [numSets-1:0][blocksPerSet-1:0];                // Holds all valid bits: 0 = empty, 1 = filled
reg [3:0] count_array [numSets-1:0];                            // hold counts of each of the blocks in each set 
reg [31:0] age_array [numSets-1:0][blocksPerSet-1:0];           // hold ages of each of the blocks in each set

initial begin: initialization
    integer i, j;
    for (i=0;i<numSets;i=i+1) begin
        for (j=0;j<blocksPerSet;j=j+1) begin
            cache[i][j] = 0;
            valid_array[i][j] = 1'b0;
            tag_array[i][j] = 17'b00000000000000000;
            age_array[i][j] = 0;
        end
        count_array[i] = 1'b0;
    end
end

endmodule
