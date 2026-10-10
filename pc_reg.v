`timescale 1ns/1ps

//------------------------------------------------------------------------------
// Program counter with synchronous enable (enable is used for pipeline stalls)
//------------------------------------------------------------------------------
module pc_reg (
    input         clk, rst_n, en,
    input  [31:0] pc_next,
    output reg [31:0] pc
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)    pc <= 32'h0000_0000;
        else if (en)   pc <= pc_next;
    end
endmodule
