`timescale 1ns/1ps

//==============================================================================
// EX stage  (forwarding muxes, ALU, branch target + EX/MEM register)
//==============================================================================
module execute_stage (
    input         clk, rst_n,
    input         reg_write_E, alu_src_E, mem_write_E, result_src_E, branch_E,
    input  [2:0]  alu_control_E,
    input  [31:0] rd1_E, rd2_E, imm_ext_E, pc_E,
    input  [4:0]  rd_E,
    // forwarding
    input  [1:0]  forward_A_E, forward_B_E,
    input  [31:0] result_W,
    // branch outputs (back to IF)
    output        pc_src_E,
    output [31:0] pc_target_E,
    // outputs to MEM
    output        reg_write_M, mem_write_M, result_src_M,
    output [4:0]  rd_M,
    output [31:0] write_data_M, alu_result_M
);
    wire [31:0] src_a_E, src_b_fwd_E, src_b_E, alu_result_E;
    wire        zero_E;

    // operand A : register / WB result / MEM result
    mux3 u_fwd_a (.d0(rd1_E), .d1(result_W), .d2(alu_result_M), .sel(forward_A_E), .y(src_a_E));
    // operand B : same, then choose between register value and immediate
    mux3 u_fwd_b (.d0(rd2_E), .d1(result_W), .d2(alu_result_M), .sel(forward_B_E), .y(src_b_fwd_E));
    mux2 u_srcb  (.d0(src_b_fwd_E), .d1(imm_ext_E), .sel(alu_src_E), .y(src_b_E));

    alu  u_alu (.a(src_a_E), .b(src_b_E), .alu_control(alu_control_E),
                .result(alu_result_E), .zero(zero_E));

    adder32 u_br_add (.a(pc_E), .b(imm_ext_E), .y(pc_target_E));

    assign pc_src_E = branch_E & zero_E;

    // ---- EX/MEM pipeline register ----
    reg        reg_write_r, mem_write_r, result_src_r;
    reg [4:0]  rd_r;
    reg [31:0] write_data_r, alu_result_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_write_r <= 1'b0;  mem_write_r <= 1'b0;  result_src_r <= 1'b0;
            rd_r <= 5'd0;  write_data_r <= 32'h0;  alu_result_r <= 32'h0;
        end else begin
            reg_write_r <= reg_write_E;  mem_write_r <= mem_write_E;
            result_src_r <= result_src_E;
            rd_r <= rd_E;
            write_data_r <= src_b_fwd_E;      // store data (after forwarding!)
            alu_result_r <= alu_result_E;
        end
    end

    assign reg_write_M  = reg_write_r;   assign mem_write_M  = mem_write_r;
    assign result_src_M = result_src_r;  assign rd_M         = rd_r;
    assign write_data_M = write_data_r;  assign alu_result_M = alu_result_r;
endmodule
