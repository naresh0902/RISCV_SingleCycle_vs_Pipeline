`timescale 1ns/1ps

//------------------------------------------------------------------------------
// Main decoder : opcode -> control signals
//------------------------------------------------------------------------------
module main_decoder (
    input  [6:0] op,
    output       reg_write, alu_src, mem_write, result_src, branch,
    output [1:0] imm_src, alu_op
);
    localparam OP_LW     = 7'b0000011;
    localparam OP_ADDI   = 7'b0010011;
    localparam OP_SW     = 7'b0100011;
    localparam OP_RTYPE  = 7'b0110011;
    localparam OP_BEQ    = 7'b1100011;

    assign reg_write  = (op == OP_LW) | (op == OP_RTYPE) | (op == OP_ADDI);
    assign alu_src    = (op == OP_LW) | (op == OP_SW)    | (op == OP_ADDI);
    assign mem_write  = (op == OP_SW);
    assign result_src = (op == OP_LW);
    assign branch     = (op == OP_BEQ);

    assign imm_src    = (op == OP_SW)  ? 2'b01 :
                        (op == OP_BEQ) ? 2'b10 : 2'b00;

    // ALUOp: 00 = add (lw/sw) | 01 = subtract (beq) | 10 = use funct3/funct7
    assign alu_op     = ((op == OP_RTYPE) | (op == OP_ADDI)) ? 2'b10 :
                        (op == OP_BEQ)                       ? 2'b01 : 2'b00;
endmodule
