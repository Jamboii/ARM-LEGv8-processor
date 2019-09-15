`timescale 1ns / 1ps

module Processor(   

    // INPUT
    input CLK, RESET,
   
    // OUTPUT
    output reg [2:0] OPCODE,
    output [4:0] STATE,
    output reg [11:0] PC, A, MA,
    output reg [15:0] IR, AC, MD,
    //output [15:0] memory_mon, memory_mon_2,
   
    reg IR_Enable, MD_Enable, AC_Enable, MA_Enable, PC_Enable, MA_Control, A_Control, MEM_Control, AM,
    reg [2:0] ALU_Control,
    reg [1:0] PC_Control,
    reg C,
    reg [4:0] PRState, NXState,
    reg [16:0] TEMP // TEMP register
    );
    
    // MEMORY Register
    reg [15:0] MEMORY [0:4095];
    
    // ZERO Instruction
    parameter ZERO = 16'b0000000000000000;

    // STATE Params
    parameter S00 = 5'h00;
    parameter S01 = 5'h01; 
    parameter S02 = 5'h02; 
    parameter S03 = 5'h03;
    parameter S04 = 5'h04; 
    parameter S05 = 5'h05; 
    parameter S06 = 5'h06; 
    parameter S07 = 5'h07; 
    parameter S08 = 5'h08;
    parameter S09 = 5'h09; 
    parameter S10 = 5'h0A; 
    parameter S11 = 5'h0B; 
    parameter S12 = 5'h0C; 
    parameter S13 = 5'h0D;
    parameter S14 = 5'h0E;
    parameter S15 = 5'h0F; 
    parameter S16 = 5'h10;
              
    // OPCODE Instructions
    parameter NOT = 3'b000; 
    parameter ADC = 3'b001;
    parameter JPA = 3'b010;
    parameter INCA = 3'b011; 
    parameter STA = 3'b100; 
    parameter LDA = 3'b101;
   
    //Fills memory register with program from memory file
    initial begin
        $readmemb("Memory.mem", MEMORY);
    end

    // Data
    always @ (posedge CLK) begin
        // Reset to STATE 0
        if(RESET == 1'b1) begin
            MD = 16'b0011000000000000;
            IR = 16'b0000000000000010;
            AC = 16'b0000000000000000;
            MA = 12'b000000000010;
            PC = 12'b000000000110;
            TEMP = 16'b0011000000000000;
            A = 12'b000000000010;
        end else begin // Otherise begin Datapath
            if(MD_Enable == 1'b1) begin // Memory Data set to A
                 MD = MEMORY[A];
            end
            
            if(IR_Enable == 1'b1) begin // Instruction Register set to A
                IR = MEMORY[A];
            end

            if(AC_Enable == 1'b1) begin // Accumulator set to ALU_C (OPCODE)
                case(ALU_Control)
                    3'b000 : TEMP = ~AC;            // NOT
                    3'b001 : TEMP = AC + MD + C;    // ADC
                    3'b010 : TEMP = AC + 1'b1;      // JPA
                    3'b011 : TEMP = ZERO;           // INCA
                    3'b100 : TEMP = MD;             // STA
                endcase
            end

            if(MA_Enable == 1'b1) begin // Memory Address set to Register
                case(MA_Control)
                    1'b0   : MA = IR;
                    1'b1   : MA = MD;
                endcase
            end

            if(PC_Enable == 1'b1) begin // Program Counter set to Register/Increment
                case(PC_Control)
                    2'b00  : PC = PC + 1'b1;
                    2'b01  : PC = IR;
                    2'b10  : PC = MD;
                endcase
            end

            case(A_Control) // Adress set to Register
                1'b0   : A = PC;
                1'b1   : A = MA;
            endcase
          
            case(MEM_Control) // Accumulator write to MEMORY
                1'b1   : MEMORY[A] = AC;
            endcase
        end
       
        AC = TEMP;
        C = TEMP[16];
        OPCODE = IR[15:13];
        AM = IR[12];
    end   
    
    //assign memory_mon = MEMORY[20];
    //assign memory_mon_2 = MEMORY[7];

    // Controller Design
    always @ (posedge CLK) begin
        if(RESET == 1'b1) begin
            PRState = S00;
        end
       
        else begin
            PRState = NXState;
        end
    end
   
    always @ (PRState) begin
        
        // Start at STATE 0, reset controls
        MD_Enable = 16'b0011000000000000;
        IR_Enable = 16'b0000000000000010;
        AC_Enable = 16'b0000000000000000;
        MA_Enable = 12'b000000000010;
        PC_Enable = 12'b000000000110;
        MA_Control = 12'b000000000010;
        A_Control = 16'b0000000000000000;
        PC_Control = 12'b000000000110;
        MEM_Control = ZERO;

            if(PRState == S00) begin // Reset State 
                MEM_Control = 1'b0;
                A_Control = 1'b0;
                IR_Enable = 1'b1;
                end

            if(PRState == S01) begin // New program counter
                IR_Enable = 1'b1;
                PC_Control = 2'b00;
                PC_Enable = 1'b1;
                end

            if(PRState == S02) begin // NOT = TRUE
                ALU_Control = 3'b000;
                AC_Enable = 1'b1;
                end

            if(PRState == S03) begin // INCA = TRUE
                ALU_Control = 3'b010;
                AC_Enable = 1'b1;
                end

            if(PRState == S04) begin // JPA = TRUE, GTZ = TRUE, AM = 1
                MA_Control = 1'b0;
                MA_Enable = 1'b1;
                A_Control = 1'b1;
                end

            if(PRState == S05) begin // Initiate immediately after STATE 4
                MEM_Control = 1'b0;
                A_Control = 1'b1;
                MD_Enable = 1'b1;
                end

            if(PRState == S06) begin // Initiate immediately after STATE 5
                PC_Control = 2'b10;
                PC_Enable = 1'b1;
                end

            if(PRState == S07) begin // JPA = TRUE, GTZ = TRUE, AM = 0
                PC_Control = 2'b01;
                PC_Enable = 1'b1;
                end

            if(PRState == S08) begin // NOT = FALSE, INCA = FALSE, JPA = FALSE
                MA_Control = 1'b0;
                MA_Enable = 1'b1;
                A_Control = 1'b1;
            end

            if(PRState == S09) begin // STA = TRUE, AM = 1
                MEM_Control = 1'b0;
                MD_Enable = 1'b1;
                end

            if(PRState == S10) begin // Initiate immediately after STATE 9
                MA_Control = 2'b1;
                MA_Enable = 1'b1;
            end

            if(PRState == S11) begin // Initiate immediately after STATE 10
                MEM_Control = 1'b1;
                ALU_Control = 3'b011;
                AC_Enable = 1'b1;
                A_Control = 1'b1;
                end

            if(PRState == S12) begin // STA = FALSE
                MEM_Control = 1'b0;
                A_Control = 1'b1;
                MD_Enable = 1'b1;
                end

            if(PRState == S13) begin // STA = FALSE, AM = TRUE
                MA_Control = 1'b1;
                MA_Enable = 1'b1;
                A_Control = 1'b1;
                end

            if(PRState == S14) begin // Initiate immediately after STATE 14
                MEM_Control = 1'b0;
                A_Control = 1'b1;
                MD_Enable = 1'b1;
                end

            if(PRState == S15) begin // ADC = TRUE
                ALU_Control = 3'b001;
                AC_Enable = 1'b1;
                end

            if(PRState == S16) begin // ADC = FALSE
                ALU_Control = 3'b100;
                AC_Enable = 1'b1;
                end

    end

    // Assign next state based on the current state and its data
    always @ (posedge CLK) begin

        case(PRState)
            S00 : NXState = S01;
            
            S01 : begin
            if(OPCODE == NOT) begin
                NXState = S02;
            end else if(OPCODE == INCA) begin
                NXState = S03;
            end else if(OPCODE != JPA) begin
                NXState = S08;
            end else if(AC < ZERO) begin
                NXState = S00;
            end else if(AM == 1'b1) begin
                NXState = S04;
            end
            else if(AM == 1'b0) begin
                NXState = S07;
            end
            end
       
            S02 : NXState = S00;
            
            S03 : NXState = S00;
            
            S04 : NXState = S05;
            
            S05 : NXState = S06;
            
            S06 : NXState = S00;
            
            S07 : NXState = S00;
            
            S08 : begin
            if(OPCODE != STA) begin
                NXState = S12;
            end else if(AM == 1'b1) begin
                NXState = S09;
            end else NXState = S11;
            end

            S09 : NXState = S10;
            
            S10 : NXState = S11;
            
            S11 : NXState = S00;
            
            S12 : begin
            if(AM == 1'b1) begin
                NXState = S13;
            end else if(OPCODE == ADC) begin
                NXState = S15;
            end else NXState = S16;
            end
            
            S13 : NXState = S14;
            
            S14 : begin
            if(OPCODE == ADC) begin
                NXState = S15;
            end else NXState = S16;
            end
           
            S15 : NXState = S00;
            
            S16 : NXState = S00;
        endcase
    end
    
    // STATE output
    assign STATE = PRState;
endmodule