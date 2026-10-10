`timescale 1ns/1ps

//==============================================================================
// WB stage
//==============================================================================
module writeback_stage (
    input         result_src_W,
    input  [31:0] alu_result_W, read_data_W,
    output [31:0] result_W
);
    mux2 u_resmux (.d0(alu_result_W), .d1(read_data_W), .sel(result_src_W), .y(result_W));
endmodule
