`timescale 1ns / 1ps

module SS_ARM(
    input CLK,
    input [63:0] register_data_1,   // Register Data 1
    input [63:0] register_data_2,   // Register Data 2
    input [63:0] memory_data,       // Data Memory
    input [31:0] instruction_word,  // Instruction
    
    output reg Reg2Loc_control,
    output reg RegWrite_control,    
    output reg MemRead_control,   
    output reg MemWrite_control,   
    output reg Branch_control,  
    output [63:0] ALU_result,
    output [63:0] Write_register_data,
    output reg [63:0] PC,
    output reg [4:0] Read_register_1,
    output [4:0] Read_register_2,
    output reg [4:0] Write_register
    );
    
    reg [4:0] tempRegNum1;
    reg [4:0] tempRegNum2;
    reg [10:0] tempInstruction;
  
    reg Mem2Reg_control;
    reg ALUSrc_control;
    reg Uncondbranch_control;
    reg [1:0] ALUOp_control;
  
    wire tempALUZero;
    wire[3:0] tempALUControl;
    wire[63:0] tempALUInput2;
    wire[63:0] tempImmediate;
    wire [63:0] tempShiftImmediate;
  
    wire [63:0] nextnextPC;
    reg Jump_control;
    wire [63:0] nextPC;
    wire nextPCZero;
    wire [63:0] shiftPC;
    wire shiftPCZero;
    reg tempBranchZero;
    
    /* Multiplexer for the Program Counter */
    Mux_PC mux1(nextPC, shiftPC, Jump_control, nextnextPC);
  
    /* Multiplexer before the Register */
    Mux_REG mux2(tempRegNum1, tempRegNum2, Reg2Loc_control, Read_register_2);
  
    /* Multiplexer before the ALU */
    Mux_ALU mux3(register_data_2, tempImmediate, ALUSrc_control, tempALUInput2);
  
    /* Multiplexer after the Data memory */
    Mux_Data_Memory mux4(memory_data, ALU_result, Mem2Reg_control, Write_register_data);
    
    /* Sign Extention Module */
    Sign_Extend mod1(instruction_word, tempImmediate);
    
    /* Shift left by two module */
    Shift_LEFT2 mod2(tempImmediate, tempShiftImmediate);
    
    /* ALU Control for the ALU */
    Control_ALU mod3(ALUOp_control, tempInstruction, tempALUControl);
    
    /* ALU Result between the Registers and the Data Memory */
    ALU aluResult(register_data_1, tempALUInput2, tempALUControl, ALU_result, tempALUZero);
  
    /* An ALU module to calulcate the next sequential PC */
    ALU adderNextPC(PC, 64'h00000004, 4'b0010, nextPC, nextPCZero);
  
    /* An ALU module to calulcate a shifted PC */
    ALU adderShiftPC(PC, tempShiftImmediate, 4'b0010, shiftPC, shiftPCZero);
  
  
    /* Initialize when the CPU is first run */
    initial begin
      PC = 0;
      Reg2Loc_control = 1'bz;
      Mem2Reg_control = 1'bz;
      RegWrite_control = 1'bz;
      MemRead_control = 1'bz;
      MemWrite_control = 1'bz;
      ALUSrc_control = 1'bz;
      Branch_control = 1'b0;
      Uncondbranch_control = 1'b0;
      tempBranchZero = tempALUZero & Branch_control;
      Jump_control = Uncondbranch_control | tempBranchZero;
    end
  
    /* Parse and set the CPU's Control bits */
    always @(posedge CLK or instruction_word) begin
  
      // Set the PC to the jumped value
      if (Jump_control == 1'b1) begin
        PC = #1 nextnextPC - 4;
      end
  
      // Parse the incoming instruction for a given PC
      tempInstruction = instruction_word[31:21];
      tempRegNum1 = instruction_word[20:16];
      tempRegNum2 = instruction_word[4:0];
      Read_register_1 = instruction_word[9:5];
      Write_register = instruction_word[4:0];
  
      if (instruction_word[31:26] == 6'b000101) begin // Control bits for B
        Reg2Loc_control = 1'b0;
        Mem2Reg_control = 1'b0;
        RegWrite_control = 1'b0;
        MemRead_control = 1'b0;
        MemWrite_control = 1'b0;
        ALUSrc_control = 1'b0;
        ALUOp_control = 2'b01;
        Branch_control = 1'b0;
        Uncondbranch_control = 1'b1;
  
      end else if (instruction_word[31:24] == 8'b10110100) begin // Control bits for CBZ
        Reg2Loc_control = 1'b0;
        Mem2Reg_control = 1'b0;
        RegWrite_control = 1'b0;
        MemRead_control = 1'b0;
        MemWrite_control = 1'b0;
        ALUSrc_control = 1'b0;
        ALUOp_control = 2'b01;
        Branch_control = 1'b1;
        Uncondbranch_control = 1'b0;
  
      end else begin // R-Type Control Bits
  
        Branch_control = 1'b0;
        Uncondbranch_control = 1'b0;
  
        case (tempInstruction)
          11'b11111000010 : begin // Control bits for LDUR
            Reg2Loc_control = 1'bx;
            Mem2Reg_control = 1'b1;
            RegWrite_control = 1'b1;
            MemRead_control = 1'b1;
            MemWrite_control = 1'b0;
            ALUSrc_control = 1'b1;
            ALUOp_control = 2'b00;
          end
  
          11'b11111000000 : begin //Control bits for STUR
            // Control Bits
            Reg2Loc_control = 1'b1;
            Mem2Reg_control = 1'bx;
            RegWrite_control = 1'b0;
            MemRead_control = 1'b0;
            MemWrite_control = 1'b1;
            ALUSrc_control = 1'b1;
            ALUOp_control = 2'b00;
          end
  
          11'b10001011000 : begin //Control bits for ADD
            Reg2Loc_control = 1'b0;
            Mem2Reg_control = 1'b0;
            RegWrite_control = 1'b1;
            MemRead_control = 1'b0;
            MemWrite_control = 1'b0;
            ALUSrc_control = 1'b0;
            ALUOp_control = 2'b10;
          end
  
          11'b11001011000 : begin //Control bits for SUB
            Reg2Loc_control = 1'b0;
            Mem2Reg_control = 1'b0;
            RegWrite_control = 1'b1;
            MemRead_control = 1'b0;
            MemWrite_control = 1'b0;
            ALUSrc_control = 1'b0;
            ALUOp_control = 2'b10;
          end
  
          11'b10001010000 : begin //Control bits for AND
            Reg2Loc_control = 1'b0;
            Mem2Reg_control = 1'b0;
            RegWrite_control = 1'b1;
            MemRead_control = 1'b0;
            MemWrite_control = 1'b0;
            ALUSrc_control = 1'b0;
            ALUOp_control = 2'b10;
          end
  
          11'b10101010000 : begin //Control bits for ORR
            Reg2Loc_control = 1'b0;
            Mem2Reg_control = 1'b0;
            RegWrite_control = 1'b1;
            MemRead_control = 1'b0;
            MemWrite_control = 1'b0;
            ALUSrc_control = 1'b0;
            ALUOp_control = 2'b10;
          end
        endcase
      end
  
      //Determine whether to branch
      tempBranchZero = tempALUZero & Branch_control;
      Jump_control = Uncondbranch_control | tempBranchZero;
  
      // For non-branch code, set the next sequential PC value
      if (Jump_control == 1'b0) begin
          PC <= #1 nextnextPC;
      end
  end
endmodule

module Mux_PC(
    input [63:0] PC_in,
    input [63:0] Shift_in,
    input Jump_control,
    
    output reg [63:0] PC_out
    );
    
    always @(PC_in, Shift_in, Jump_control, PC_out) begin
        if (Jump_control == 0) begin
            PC_out = PC_in;
        end else begin
            PC_out = Shift_in;
        end
    end
endmodule

module Mux_REG(
    input [4:0] in_1,
    input [4:0] in_2,
    input Reg2Loc_control,
    
    output reg [4:0] Mux_out
    );
    
    always @(in_1, in_2, Reg2Loc_control) begin
   
        if (Reg2Loc_control == 0) begin
            Mux_out = in_1;
        end else begin
            Mux_out = in_2;
        end
   end
endmodule

module Mux_ALU(
    input [63:0] in_1,
    input [63:0] in_2,
    input ALUSrc_control,
    
    output reg [63:0] Mux_out
    );
    
    always @(in_1, in_2, ALUSrc_control, Mux_out) begin
        if (ALUSrc_control == 0) begin
            Mux_out = in_1;
        end else begin
            Mux_out = in_2;
        end
    end
endmodule

module Mux_Data_Memory(
    input [63:0] Data_read,
    input [63:0] ALU_out,
    input Mem2Reg_control,
    
    output reg [63:0] Mux_out
    );
    
    always @(Data_read, ALU_out, Mem2Reg_control, Mux_out) begin
        if (Mem2Reg_control == 0) begin
            Mux_out = ALU_out;
        end else begin
            Mux_out = Data_read;
        end
    end
endmodule

module Sign_Extend(
    input [31:0] instruction_in,
    
    output reg [63:0] immediate_out
    );
    
    always @(instruction_in) begin
    
        if (instruction_in[31:26] == 6'b000101) begin // B
            immediate_out[25:0] = instruction_in[25:0];
            immediate_out[63:26] = {64{immediate_out[25]}};
    
        end else if (instruction_in[31:24] == 8'b10110100) begin // CBZ
            immediate_out[19:0] = instruction_in[23:5];
            immediate_out[63:20] = {64{immediate_out[19]}};
    
        end else begin // D Type
            immediate_out[9:0] = instruction_in[20:12];
            immediate_out[63:10] = {64{immediate_out[9]}};
        end
    end
endmodule

module Shift_LEFT2(
    input [63:0] Data_in,
    
    output reg [63:0] Data_out
    );
    
    always @(Data_in) begin
        Data_out = Data_in << 2;
    end
endmodule

module Control_ALU(
    input [1:0] ALUOp,
    input [10:0] ALU_instruction,
    
    output reg [3:0] ALU_Out
    );
    
    always @(ALUOp or ALU_instruction) begin
  
        case (ALUOp)
            2'b00 : ALU_Out = 4'b0010;
            2'b01 : ALU_Out = 4'b0111;
            2'b10 : begin
  
            case (ALU_instruction)
                11'b10001011000 : ALU_Out = 4'b0010; // ADD Instruction
                11'b11001011000 : ALU_Out = 4'b0110; // SUB Instruction
                11'b10001010000 : ALU_Out = 4'b0000; // AND Instruction
                11'b10101010000 : ALU_Out = 4'b0001; // ORR Instruction
            endcase
            end
        endcase
    end
endmodule

module ALU(
    input [63:0] A,B,
    input [3:0] SELECT,
    output reg [63:0] OUT,
    output reg ZEROFLAG
    );
    
    always @(A or B or SELECT) begin
        case (SELECT)
            4'b0000 : OUT = A & B;
            4'b0001 : OUT = A | B;
            4'b0010 : OUT = A + B;
            4'b0110 : OUT = A - B;
            4'b0111 : OUT = B;
            4'b1100 : OUT = ~(A | B);
        endcase
        if (OUT == 0) begin
            ZEROFLAG = 1'b1;
        end else begin
            ZEROFLAG = 1'b0;
        end
    end
endmodule

module Instruction_Memory(
    input [63:0] PC,
    
    output reg [31:0] CPU_Instruction
    );
    
    reg [8:0] Data[63:0];
    
    initial begin
        // LDUR x2, [x10]
        Data[0] = 8'hF8;
        Data[1] = 8'h40;
        Data[2] = 8'h01;
        Data[3] = 8'h42;
    
        // LDUR x3, [x10, #1]
        Data[4] = 8'hF8;
        Data[5] = 8'h40;
        Data[6] = 8'h11;
        Data[7] = 8'h43;
    
        // SUB x4, x3, x2
        Data[8] = 8'hCB;
        Data[9] = 8'h02;
        Data[10] = 8'h00;
        Data[11] = 8'h64;
    
        // ADD x5, x3, x2
        Data[12] = 8'h8B;
        Data[13] = 8'h02;
        Data[14] = 8'h00;
        Data[15] = 8'h65;
    
        // CBZ x1, #2
        Data[16] = 8'hB4;
        Data[17] = 8'h00;
        Data[18] = 8'h00;
        Data[19] = 8'h41;
    
        // CBZ x0, #2
        Data[20] = 8'hB4;
        Data[21] = 8'h00;
        Data[22] = 8'h00;
        Data[23] = 8'h40;
    
        // LDUR x2 [x10]
        Data[24] = 8'hF8;
        Data[25] = 8'h40;
        Data[26] = 8'h01;
        Data[27] = 8'h42;
    
        // ORR x6, x2, x3
        Data[28] = 8'hAA;
        Data[29] = 8'h03;
        Data[30] = 8'h00;
        Data[31] = 8'h46;
    
        // AND x7, x2, x3
        Data[32] = 8'h8A;
        Data[33] = 8'h03;
        Data[34] = 8'h00;
        Data[35] = 8'h47;
    
        // STUR x4, [x7, #1]
        Data[36] = 8'hF8;
        Data[37] = 8'h00;
        Data[38] = 8'h10;
        Data[39] = 8'hE4;
    
        // B #2
        Data[40] = 8'h14;
        Data[41] = 8'h00;
        Data[42] = 8'h00;
        Data[43] = 8'h03;
    
        // LDUR x3, [x10, #1]
        Data[44] = 8'hF8;
        Data[45] = 8'h40;
        Data[46] = 8'h11;
        Data[47] = 8'h43;
    
        // ADD x8, x0, x1
        Data[48] = 8'h8B;
        Data[49] = 8'h01;
        Data[50] = 8'h00;
        Data[51] = 8'h08;
    end
    
    always @(PC) begin
        CPU_Instruction[8:0] = Data[PC+3];
        CPU_Instruction[16:8] = Data[PC+2];
        CPU_Instruction[24:16] = Data[PC+1];
        CPU_Instruction[31:24] = Data[PC];
    end
endmodule

module Registers(
    input [4:0] read_1,
    input [4:0] read_2,
    input [4:0] Reg_write,
    input [63:0] Data_write,
    input RegWrite_control,
    
    output reg [63:0] data_1,
    output reg [63:0] data_2
    );
    
    reg [63:0] Data[31:0];
   
    integer initCount;
   
    initial begin
   
        for (initCount = 0; initCount < 31; initCount = initCount + 1) begin
            Data[initCount] = initCount;
        end
   
        Data[31] = 64'h00000000;
    end
   
    always @(read_1, read_2, Reg_write, Data_write, RegWrite_control) begin
   
        data_1 = Data[read_1];
        data_2 = Data[read_2];
   
        if (RegWrite_control == 1) begin
            Data[Reg_write] = Data_write;
        end
    end
endmodule

module Data_Memory(
    input [63:0] address_in,
    input [63:0] data_in,
    input MemRead_control,
    input MemWrite_control,
    output reg [63:0] Data_out
    );
    
    reg [63:0] Data[31:0];
  
    integer initCount;
  
    initial begin
        for (initCount = 0; initCount < 32; initCount = initCount + 1) begin
            Data[initCount] = initCount * 100;
        end
  
        Data[10] = 1540;
        Data[11] = 2117;
    end
  
    always @(address_in, data_in, MemRead_control, MemWrite_control) begin
        if (MemWrite_control == 1) begin
            Data[address_in] = data_in;
        end
  
        if (MemRead_control == 1) begin
            Data_out = Data[address_in];
        end
    end
endmodule