`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/04/2020 04:12:25 AM
// Design Name: 
// Module Name: processor
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


module processor(input [23:0] address,
                input [23:0] data,
                input clk,
                input mode,
                input [31:0] miss_in,
                output [23:0] out,
                output status,
                output addBlock
);

// initialize ram and cache
ram ram();
cache cache();

// previous values
reg [23:0] prev_address, prev_data;
reg prev_mode;
reg [23:0] temp_out;
reg temp_status;
reg temp_add;

reg [cache.lenIndex - 1:0] setIndex;
reg [cache.lenTag - 1:0] tag;
reg [cache.blocksPerSet-1:0] blockIndex;

integer i,j;

integer maxIdx;
integer maxAge = 0;

initial begin
    setIndex = 0;
    tag = 0;
    blockIndex = 0;
    prev_address = 0;
    prev_data = 0;
    prev_mode = 0;
end

always @(address or data or mode) begin
    // check if new input is updated
    prev_address = address % ram.ramSize;
    prev_data = data;
    prev_mode = mode;
    
    tag = address >> (cache.lenIndex + cache.lenOffset);   // tag = first bits of the address except index/offset ones (17 here)
    // index = address % cache.numBlocks;                  // index = last n (n=size of cache) bits of address
    setIndex = address[6:3];                               // set as determined by index bits in address
    blockIndex = cache.count_array[setIndex];              // total number of valid blocks in set
    temp_status = 1'b0;
    temp_add = 1'b0;
      
    if (mode == 1) begin
        ram.ram[prev_address] = data;
        // write new data to relevant cache block if there is such one
        if (cache.valid_array[setIndex][blockIndex] == 1 && cache.tag_array[setIndex][blockIndex] == tag) begin
            cache.cache[setIndex][blockIndex] = data;
        end        
    end else if (mode == 0) begin: read
        // try and find cache block within set
        // loop through populated blocks in set
        // temp_status = 1'b0;
        for (i=0;i<blockIndex;i=i+1) begin
            // cache hit
            if (cache.tag_array[setIndex][i] == tag) begin
                $display("CACHE HIT");
                // Set hit status to TRUE
                temp_status = 1'b1;
                // Reset age of block
                cache.age_array[setIndex][i] = 0;
                $display("address = %x, index = %d, size = %d, age = %d", address, setIndex, cache.count_array[setIndex], 0);
            end
        end
        
        // check to see if temp_status is not met
        if (temp_status == 1'b0) begin
            // cache miss, check if we add block to set or replace block with LRU replacement policy
            $display("Block index = %d, blocks per set = %d", blockIndex, cache.blocksPerSet);
            // if valid bits are completely filled, then we need to replace a block
            if (cache.valid_array[setIndex][cache.blocksPerSet-1] == 1) begin: missReplace // replace block
                // go through all blocks in set, find the maximum age
                maxAge = 0;
                for (i=0;i<cache.blocksPerSet;i=i+1) begin
                    if (cache.age_array[setIndex][i] > maxAge) begin // new max age found
                        maxAge = cache.age_array[setIndex][i]; // update max age
                        maxIdx = i; // update max index
                    end
                end
                // replace block that has the largest age (the least recently used) with new tag
                cache.tag_array[setIndex][maxIdx] = tag;
                // update cache memory
                cache.cache[setIndex][maxIdx] = ram.ram[prev_address];
                // reset age of new block back to 0
                cache.age_array[setIndex][maxIdx] = 0;
                $display("Block at index = %d replaced", maxIdx);
                $display("address = %x, index = %d, size = %d, age = %d", address, setIndex, cache.count_array[setIndex], 0);
            end else begin: missAdd // spaces to fill, add the block to the set
                temp_add = 1'b1;
                cache.valid_array[setIndex][blockIndex] = 1;                // update valid bit
                cache.tag_array[setIndex][blockIndex] = tag;                // update tag in tag array
                cache.cache[setIndex][blockIndex] = ram.ram[prev_address];  // update cache memory
                $display("address = %x, index = %d, size = %d, age = %d", address, setIndex, cache.count_array[setIndex], cache.age_array[setIndex][blockIndex]);
                // add to count
                cache.count_array[setIndex] = cache.count_array[setIndex] + 1;               // increment block index
            end
        end
        
        // output is data allocated to block index in cache memory
        // temp_out = cache.cache[setIndex][blockIndex-1];
        temp_out = blockIndex-1;    
           
        // increment ages of active blocks
        for (i=0;i<cache.numSets;i=i+1) begin               // loop through each set
            for (j=0;j<cache.count_array[i];j=j+1) begin    // loop through each valid block in each set
                if (cache.valid_array[i][j] == 1)           // once again make sure we have a valid block
                    cache.age_array[i][j] = cache.age_array[i][j] + 1;
            end
        end
    end
end

assign addBlock = temp_add;
assign out = temp_out;
assign status = temp_status;

endmodule
