`timescale 1ns/1ps

//------------------------------------------------------------------------------
// Control unit (main decoder + ALU decoder)
//------------------------------------------------------------------------------
module control_unit (
    input  [6:0] op,
    input  [2:0] funct3,
    input        funct7_5,
    output       reg_write, alu_src, mem_write, result_src, branch,
    output [1:0] imm_src,
    output [2:0] alu_control
);
    wire [1:0] alu_op;

    main_decoder u_main (
        .op(op), .reg_write(reg_write), .alu_src(alu_src), .mem_write(mem_write),
        .result_src(result_src), .branch(branch), .imm_src(imm_src), .alu_op(alu_op)
    );

    alu_decoder u_alu (
        .alu_op(alu_op), .funct3(funct3), .op5(op[5]), .funct7_5(funct7_5),
        .alu_control(alu_control)
    );
endmodule
