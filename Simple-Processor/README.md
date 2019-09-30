# ARM LEGv8 Simple Processor

Design of a simple processor using the Xilinx design package for FPGAs.

## Tasks

This simple processor incorporates the Arithmetic Logic Unit (ALU). The processor has the following registers : `IR` (Instruction Register), `MD` (Memory Data), `AC` (Accumulator), `PC` (Program Counter), `MA` (Memory Address). 

The processor implements the following instructions: `NOT`, `ADC` (Add with carry), `JPA` (Jump if AC > 0), `INCA` (Increment AC), `STA` (Store and clear AC), `LDA` (Load AC). The clock for the design is set at 1 MHz.

## Waveforms

#### All register outputs and states

![Processor Waveform 1](/Simple-Processor/Waveforms/register-outputs.png)

#### Display of 20 memory values read in from external text file `memory.mem`

![Processor Waveform 2](/Simple-Processor/Waveforms/mem-values.png)

## License

[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/Jamboii/ARM-LEGv8-Processor/master/LICENSE.md)
