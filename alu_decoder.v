`timescale 1ns/1ps

//------------------------------------------------------------------------------
// ALU decoder : ALUOp + funct3/funct7 -> ALU control
//------------------------------------------------------------------------------
module alu_decoder (
    input  [1:0] alu_op,
    input  [2:0] funct3,
    input        op5, funct7_5,      // op[5]: 1 = R-type, 0 = I-type
    output reg [2:0] alu_control
);
    always @(*) begin
        case (alu_op)
            2'b00:   alu_control = 3'b000;                    // add
            2'b01:   alu_control = 3'b001;                    // sub
            default: begin
                case (funct3)
                    3'b000:  alu_control = (op5 & funct7_5) ? 3'b001 : 3'b000; // sub / add / addi
                    3'b010:  alu_control = 3'b101;            // slt
                    3'b110:  alu_control = 3'b011;            // or
                    3'b111:  alu_control = 3'b010;            // and
                    default: alu_control = 3'b000;
                endcase
            end
        endcase
    end
endmodule
