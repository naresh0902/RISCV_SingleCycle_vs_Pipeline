`timescale 1ns/1ps

//------------------------------------------------------------------------------
// Register file: 32 x 32-bit, two read ports, one write port.
//  * x0 is hard-wired to zero.
//  * WRITE_THROUGH = 1 (pipeline): if the register being written is read in
//    the same cycle, the NEW value is returned. This removes the "distance-3"
//    data hazard between the WB stage and the ID stage.
//  * WRITE_THROUGH = 0 (single-cycle): must be off, otherwise the bypass would
//    create a combinational loop (regfile -> ALU -> result -> regfile).
//------------------------------------------------------------------------------
module register_file #(
    parameter WRITE_THROUGH = 0
)(
    input         clk, we,
    input  [4:0]  ra1, ra2, wa,
    input  [31:0] wd,
    output [31:0] rd1, rd2
);
    reg [31:0] regs [0:31];
    integer i;

    initial begin
        for (i = 0; i < 32; i = i + 1) regs[i] = 32'h0000_0000;
    end

    always @(posedge clk)
        if (we && (wa != 5'd0)) regs[wa] <= wd;

    wire bypass1 = (WRITE_THROUGH != 0) && we && (wa == ra1);
    wire bypass2 = (WRITE_THROUGH != 0) && we && (wa == ra2);

    assign rd1 = (ra1 == 5'd0) ? 32'h0 : bypass1 ? wd : regs[ra1];
    assign rd2 = (ra2 == 5'd0) ? 32'h0 : bypass2 ? wd : regs[ra2];
endmodule
