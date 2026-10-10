`timescale 1ns/1ps

//------------------------------------------------------------------------------
// Instruction memory (read-only, combinational read, word aligned)
// The benchmark program is hard-coded so the design runs on EDA Playground
// without uploading any .hex file.
//------------------------------------------------------------------------------
module instruction_memory (
    input  [31:0] addr,
    output [31:0] instr
);
    reg [31:0] mem [0:255];
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1) mem[i] = 32'h0000_0000;   // NOP-like bubble
        mem[ 0] = 32'h00000093;  // addi x1,x0,0      // sum = 0
        mem[ 1] = 32'h00A00113;  // addi x2,x0,10     // counter = 10
        mem[ 2] = 32'h00010863;  // beq x2,x0,end     // exit loop when counter == 0 (branch)
        mem[ 3] = 32'h002080B3;  // add x1,x1,x2      // sum += counter (RAW with addi below)
        mem[ 4] = 32'hFFF10113;  // addi x2,x2,-1     // counter-- (forwarding)
        mem[ 5] = 32'hFE000AE3;  // beq x0,x0,loop    // unconditional jump back (always taken)
        mem[ 6] = 32'h00102023;  // sw x1,0(x0)       // mem[0] = 55
        mem[ 7] = 32'h00002203;  // lw x4,0(x0)       // x4 = mem[0]
        mem[ 8] = 32'h004202B3;  // add x5,x4,x4      // LOAD-USE hazard, x5 = 110
        mem[ 9] = 32'h00700313;  // addi x6,x0,7      // x6 = 7
        mem[10] = 32'h00130393;  // addi x7,x6,1      // forward from MEM, x7 = 8
        mem[11] = 32'h00638433;  // add x8,x7,x6      // forward MEM + WB, x8 = 15
        mem[12] = 32'h406404B3;  // sub x9,x8,x6      // x9 = 8
        mem[13] = 32'h00747533;  // and x10,x8,x7     // x10 = 8
        mem[14] = 32'h007465B3;  // or x11,x8,x7      // x11 = 15
        mem[15] = 32'h0083A633;  // slt x12,x7,x8     // x12 = 1
        mem[16] = 32'h00902423;  // sw x9,8(x0)       // mem[2] = 8
        mem[17] = 32'h00502223;  // sw x5,4(x0)       // mem[1] = 110  <-- DONE marker (testbench watches this)
        mem[18] = 32'h00000063;  // beq x0,x0,halt    // spin forever
    end

    assign instr = mem[addr[9:2]];
endmodule
