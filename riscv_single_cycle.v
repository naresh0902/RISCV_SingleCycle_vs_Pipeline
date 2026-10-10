`timescale 1ns/1ps

module riscv_single_cycle (
    input clk,
    input rst_n
);

    // ---------------------------------------------------------------- wires
    wire [31:0] pc, pc_next, pc_plus4, pc_target;
    wire [31:0] instr;
    wire [31:0] rd1, rd2, imm_ext, src_b;
    wire [31:0] alu_result, read_data, result;
    wire        zero, pc_src;

    // control signals
    wire        reg_write, alu_src, mem_write, result_src, branch;
    wire [1:0]  imm_src;
    wire [2:0]  alu_control;

    // ------------------------------------------------------------- fetch
    pc_reg      u_pc      (.clk(clk), .rst_n(rst_n), .en(1'b1), .pc_next(pc_next), .pc(pc));
    adder32     u_pc4     (.a(pc), .b(32'd4), .y(pc_plus4));
    adder32     u_pctgt   (.a(pc), .b(imm_ext), .y(pc_target));
    mux2        u_pcmux   (.d0(pc_plus4), .d1(pc_target), .sel(pc_src), .y(pc_next));
    instruction_memory u_imem (.addr(pc), .instr(instr));

    // ------------------------------------------------------------ decode
    control_unit u_ctrl (
        .op(instr[6:0]), .funct3(instr[14:12]), .funct7_5(instr[30]),
        .reg_write(reg_write), .alu_src(alu_src), .mem_write(mem_write),
        .result_src(result_src), .branch(branch),
        .imm_src(imm_src), .alu_control(alu_control)
    );

    register_file u_rf (
        .clk(clk), .we(reg_write),
        .ra1(instr[19:15]), .ra2(instr[24:20]), .wa(instr[11:7]),
        .wd(result), .rd1(rd1), .rd2(rd2)
    );

    sign_extend u_ext (.instr(instr), .imm_src(imm_src), .imm_ext(imm_ext));

    // ----------------------------------------------------------- execute
    mux2 u_srcb (.d0(rd2), .d1(imm_ext), .sel(alu_src), .y(src_b));

    alu  u_alu  (.a(rd1), .b(src_b), .alu_control(alu_control),
                 .result(alu_result), .zero(zero));

    assign pc_src = branch & zero;

    // ------------------------------------------------- memory / writeback
    data_memory u_dmem (.clk(clk), .we(mem_write), .addr(alu_result),
                        .wdata(rd2), .rdata(read_data));

    mux2 u_resmux (.d0(alu_result), .d1(read_data), .sel(result_src), .y(result));

endmodule
