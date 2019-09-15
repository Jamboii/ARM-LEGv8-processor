`timescale 1ns / 1ps

module SS_ARM_tb;
    /* Clock Signal */
    reg CLK;

    /* Wires to connect instruction memory to CPU */
    wire [63:0] PC_instruction;
    wire [31:0] Out_instruction;

    /* Wires to connect registers to CPU */
    wire [4:0] Read_register_1;
    wire [4:0] Read_register_2;
    wire [4:0] Write_register;
    wire [63:0] Write_data;
    wire [63:0] Data_out_1;
    wire [63:0] Data_out_2;

    /* Wires to connect Data Memory to CPU */
    wire [63:0] memory_data;
    wire [63:0] ALU_result;

    /* Wires to connect CPU Control Lines to Memories */
    wire Reg2Loc_control;
    wire RegWrite_control;
    wire MemRead_control;
    wire MemWrite_control;
    wire Branch_control;

    /* Instruction Memory Module */
    Instruction_Memory mem1(
        PC_instruction,
        Out_instruction
    );

    /* Registers Module */
    Registers mem2(
        Read_register_1,
        Read_register_2,
        Write_register,
        Write_data,
        RegWrite_control,
        Data_out_1,
        Data_out_2
    );

    /* Data Memory Module */
    Data_Memory mem3(
        ALU_result,
        Data_out_2,
        MemRead_control,
        MemWrite_control,
        memory_data
    );

    /* CPU Module */
    SS_ARM core(
        .CLK(CLK),
        .instruction_word(Out_instruction),
        .PC(PC_instruction),
        .Reg2Loc_control(Reg2Loc_control),
        .RegWrite_control(RegWrite_control),
        .MemRead_control(MemRead_control),
        .MemWrite_control(MemWrite_control),
        .Branch_control(Branch_control),
        .Read_register_1(Read_register_1),
        .Read_register_2(Read_register_2),
        .Write_register(Write_register),
        .register_data_1(Data_out_1),
        .register_data_2(Data_out_2),
        .ALU_result(ALU_result),
        .memory_data(memory_data),
        .Write_register_data(Write_data)
    );

    /* Setup the clock */
    initial begin
        CLK = 1'b0;
        #30 $finish;
    end

    /* Toggle the clock */
    always begin
        #1 CLK = ~CLK;
    end
endmodule
