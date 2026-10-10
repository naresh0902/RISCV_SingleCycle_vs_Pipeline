`timescale 1ns/1ps

//------------------------------------------------------------------------------
// Data memory (synchronous write, combinational read, word aligned)
//------------------------------------------------------------------------------
module data_memory (
    input         clk, we,
    input  [31:0] addr, wdata,
    output [31:0] rdata
);
    reg [31:0] mem [0:255];
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1) mem[i] = 32'h0000_0000;
    end

    always @(posedge clk)
        if (we) mem[addr[9:2]] <= wdata;

    assign rdata = mem[addr[9:2]];
endmodule
