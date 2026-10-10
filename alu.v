`timescale 1ns/1ps

//------------------------------------------------------------------------------
// ALU
//   000 ADD | 001 SUB | 010 AND | 011 OR | 101 SLT (signed)
//------------------------------------------------------------------------------
module alu (
    input  [31:0] a, b,
    input  [2:0]  alu_control,
    output reg [31:0] result,
    output        zero
);
    always @(*) begin
        case (alu_control)
            3'b000:  result = a + b;
            3'b001:  result = a - b;
            3'b010:  result = a & b;
            3'b011:  result = a | b;
            3'b101:  result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            default: result = 32'h0000_0000;
        endcase
    end

    assign zero = (result == 32'h0000_0000);
endmodule
