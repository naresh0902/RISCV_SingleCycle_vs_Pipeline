`timescale 1ns/1ps

//==============================================================================
// Top level of the pipelined core
//==============================================================================
module riscv_pipeline (
    input clk,
    input rst_n
);
    // ----- inter-stage wires --------------------------------------------------
    // IF -> ID
    wire [31:0] instr_D, pc_D, pc_plus4_D;
    // ID -> EX
    wire        reg_write_E, alu_src_E, mem_write_E, result_src_E, branch_E;
    wire [2:0]  alu_control_E;
    wire [31:0] rd1_E, rd2_E, imm_ext_E, pc_E, pc_plus4_E;
    wire [4:0]  rs1_E, rs2_E, rd_E;
    // EX -> IF / MEM
    wire        pc_src_E;
    wire [31:0] pc_target_E;
    wire        reg_write_M, mem_write_M, result_src_M;
    wire [4:0]  rd_M;
    wire [31:0] write_data_M, alu_result_M;
    // MEM -> WB
    wire        reg_write_W, result_src_W;
    wire [4:0]  rd_W;
    wire [31:0] alu_result_W, read_data_W, result_W;
    // hazard unit
    wire [1:0]  forward_A_E, forward_B_E;
    wire        stall_F, stall_D, flush_D, flush_E;

    // does the instruction in ID really read rs2? (R-type, S-type, B-type)
    wire rs2_used_D = (instr_D[6:0] == 7'b0110011) |
                      (instr_D[6:0] == 7'b0100011) |
                      (instr_D[6:0] == 7'b1100011);

    fetch_stage Fetch (
        .clk(clk), .rst_n(rst_n),
        .stall_F(stall_F), .stall_D(stall_D), .flush_D(flush_D),
        .pc_src_E(pc_src_E), .pc_target_E(pc_target_E),
        .instr_D(instr_D), .pc_D(pc_D), .pc_plus4_D(pc_plus4_D)
    );

    decode_stage Decode (
        .clk(clk), .rst_n(rst_n), .flush_E(flush_E),
        .instr_D(instr_D), .pc_D(pc_D), .pc_plus4_D(pc_plus4_D),
        .reg_write_W(reg_write_W), .rd_W(rd_W), .result_W(result_W),
        .reg_write_E(reg_write_E), .alu_src_E(alu_src_E), .mem_write_E(mem_write_E),
        .result_src_E(result_src_E), .branch_E(branch_E), .alu_control_E(alu_control_E),
        .rd1_E(rd1_E), .rd2_E(rd2_E), .imm_ext_E(imm_ext_E),
        .pc_E(pc_E), .pc_plus4_E(pc_plus4_E),
        .rs1_E(rs1_E), .rs2_E(rs2_E), .rd_E(rd_E)
    );

    execute_stage Execute (
        .clk(clk), .rst_n(rst_n),
        .reg_write_E(reg_write_E), .alu_src_E(alu_src_E), .mem_write_E(mem_write_E),
        .result_src_E(result_src_E), .branch_E(branch_E), .alu_control_E(alu_control_E),
        .rd1_E(rd1_E), .rd2_E(rd2_E), .imm_ext_E(imm_ext_E), .pc_E(pc_E), .rd_E(rd_E),
        .forward_A_E(forward_A_E), .forward_B_E(forward_B_E), .result_W(result_W),
        .pc_src_E(pc_src_E), .pc_target_E(pc_target_E),
        .reg_write_M(reg_write_M), .mem_write_M(mem_write_M), .result_src_M(result_src_M),
        .rd_M(rd_M), .write_data_M(write_data_M), .alu_result_M(alu_result_M)
    );

    memory_stage Memory (
        .clk(clk), .rst_n(rst_n),
        .reg_write_M(reg_write_M), .mem_write_M(mem_write_M), .result_src_M(result_src_M),
        .rd_M(rd_M), .write_data_M(write_data_M), .alu_result_M(alu_result_M),
        .reg_write_W(reg_write_W), .result_src_W(result_src_W), .rd_W(rd_W),
        .alu_result_W(alu_result_W), .read_data_W(read_data_W)
    );

    writeback_stage WriteBack (
        .result_src_W(result_src_W), .alu_result_W(alu_result_W),
        .read_data_W(read_data_W), .result_W(result_W)
    );

    hazard_unit Hazard (
        .rs1_E(rs1_E), .rs2_E(rs2_E),
        .rs1_D(instr_D[19:15]), .rs2_D(instr_D[24:20]), .rs2_used_D(rs2_used_D),
        .rd_E(rd_E), .rd_M(rd_M), .rd_W(rd_W),
        .reg_write_M(reg_write_M), .reg_write_W(reg_write_W),
        .load_E(result_src_E), .pc_src_E(pc_src_E),
        .forward_A_E(forward_A_E), .forward_B_E(forward_B_E),
        .stall_F(stall_F), .stall_D(stall_D), .flush_D(flush_D), .flush_E(flush_E)
    );
endmodule
