`timescale 1ns/1ps

//------------------------------------------------------------------------------
// 3-to-1 multiplexer (32-bit), used for the forwarding paths
//   sel = 00 -> d0 | 01 -> d1 | 10 -> d2
//------------------------------------------------------------------------------
module mux3 (
    input  [31:0] d0, d1, d2,
    input  [1:0]  sel,
    output [31:0] y
);
    assign y = (sel == 2'b00) ? d0 :
               (sel == 2'b01) ? d1 :
               (sel == 2'b10) ? d2 : 32'h0000_0000;
endmodule
