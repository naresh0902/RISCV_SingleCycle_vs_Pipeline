`timescale 1ns/1ps

//==============================================================================
// ID stage  (control unit, register file, immediate gen + ID/EX register)
//==============================================================================
module decode_stage (
    input         clk, rst_n,
    input         flush_E,
    input  [31:0] instr_D, pc_D, pc_plus4_D,
    // write-back port of the register file
    input         reg_write_W,
    input  [4:0]  rd_W,
    input  [31:0] result_W,
    // outputs to EX
    output        reg_write_E, alu_src_E, mem_write_E, result_src_E, branch_E,
    output [2:0]  alu_control_E,
    output [31:0] rd1_E, rd2_E, imm_ext_E, pc_E, pc_plus4_E,
    output [4:0]  rs1_E, rs2_E, rd_E
);
    wire        reg_write_D, alu_src_D, mem_write_D, result_src_D, branch_D;
    wire [1:0]  imm_src_D;
    wire [2:0]  alu_control_D;
    wire [31:0] rd1_D, rd2_D, imm_ext_D;

    control_unit u_ctrl (
        .op(instr_D[6:0]), .funct3(instr_D[14:12]), .funct7_5(instr_D[30]),
        .reg_write(reg_write_D), .alu_src(alu_src_D), .mem_write(mem_write_D),
        .result_src(result_src_D), .branch(branch_D),
        .imm_src(imm_src_D), .alu_control(alu_control_D)
    );

    register_file #(.WRITE_THROUGH(1)) u_rf (
        .clk(clk), .we(reg_write_W),
        .ra1(instr_D[19:15]), .ra2(instr_D[24:20]), .wa(rd_W),
        .wd(result_W), .rd1(rd1_D), .rd2(rd2_D)
    );

    sign_extend u_ext (.instr(instr_D), .imm_src(imm_src_D), .imm_ext(imm_ext_D));

    // ---- ID/EX pipeline register ----
    reg        reg_write_r, alu_src_r, mem_write_r, result_src_r, branch_r;
    reg [2:0]  alu_control_r;
    reg [31:0] rd1_r, rd2_r, imm_ext_r, pc_r, pc_plus4_r;
    reg [4:0]  rs1_r, rs2_r, rd_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || flush_E) begin
            reg_write_r   <= 1'b0;   alu_src_r   <= 1'b0;
            mem_write_r   <= 1'b0;   result_src_r <= 1'b0;
            branch_r      <= 1'b0;   alu_control_r <= 3'b000;
            rd1_r <= 32'h0;  rd2_r <= 32'h0;  imm_ext_r <= 32'h0;
            pc_r  <= 32'h0;  pc_plus4_r <= 32'h0;
            rs1_r <= 5'd0;   rs2_r <= 5'd0;   rd_r <= 5'd0;
        end else begin
            reg_write_r   <= reg_write_D;   alu_src_r   <= alu_src_D;
            mem_write_r   <= mem_write_D;   result_src_r <= result_src_D;
            branch_r      <= branch_D;      alu_control_r <= alu_control_D;
            rd1_r <= rd1_D;  rd2_r <= rd2_D;  imm_ext_r <= imm_ext_D;
            pc_r  <= pc_D;   pc_plus4_r <= pc_plus4_D;
            rs1_r <= instr_D[19:15];
            rs2_r <= instr_D[24:20];
            rd_r  <= instr_D[11:7];
        end
    end

    assign reg_write_E   = reg_write_r;    assign alu_src_E    = alu_src_r;
    assign mem_write_E   = mem_write_r;    assign result_src_E = result_src_r;
    assign branch_E      = branch_r;       assign alu_control_E = alu_control_r;
    assign rd1_E = rd1_r;  assign rd2_E = rd2_r;  assign imm_ext_E = imm_ext_r;
    assign pc_E  = pc_r;   assign pc_plus4_E = pc_plus4_r;
    assign rs1_E = rs1_r;  assign rs2_E = rs2_r;  assign rd_E = rd_r;
endmodule
