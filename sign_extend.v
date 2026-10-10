`timescale 1ns/1ps

//------------------------------------------------------------------------------
// Immediate generator
//   ImmSrc 00 : I-type (addi, lw)
//   ImmSrc 01 : S-type (sw)
//   ImmSrc 10 : B-type (beq)
//------------------------------------------------------------------------------
module sign_extend (
    input  [31:0] instr,
    input  [1:0]  imm_src,
    output reg [31:0] imm_ext
);
    always @(*) begin
        case (imm_src)
            2'b00:   imm_ext = {{20{instr[31]}}, instr[31:20]};
            2'b01:   imm_ext = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            2'b10:   imm_ext = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
            default: imm_ext = 32'h0000_0000;
        endcase
    end
endmodule
