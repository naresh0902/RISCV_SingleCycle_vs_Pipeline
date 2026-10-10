`timescale 1ns/1ps

//------------------------------------------------------------------------------
// 32-bit adder (PC+4 and branch-target adders)
//------------------------------------------------------------------------------
module adder32 (
    input  [31:0] a, b,
    output [31:0] y
);
    assign y = a + b;
endmodule
