`timescale 1ns/1ps

//==============================================================================
// IF stage  (contains the IF/ID pipeline register)
//==============================================================================
module fetch_stage (
    input         clk, rst_n,
    input         stall_F, stall_D, flush_D,
    input         pc_src_E,
    input  [31:0] pc_target_E,
    output [31:0] instr_D, pc_D, pc_plus4_D
);
    wire [31:0] pc_F, pc_plus4_F, pc_next_F, instr_F;

    mux2   u_pcmux (.d0(pc_plus4_F), .d1(pc_target_E), .sel(pc_src_E), .y(pc_next_F));
    pc_reg u_pc    (.clk(clk), .rst_n(rst_n), .en(~stall_F), .pc_next(pc_next_F), .pc(pc_F));
    adder32 u_pc4  (.a(pc_F), .b(32'd4), .y(pc_plus4_F));
    instruction_memory u_imem (.addr(pc_F), .instr(instr_F));

    // ---- IF/ID pipeline register ----
    reg [31:0] instr_r, pc_r, pc_plus4_r;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || flush_D) begin
            instr_r    <= 32'h0000_0000;       // bubble
            pc_r       <= 32'h0000_0000;
            pc_plus4_r <= 32'h0000_0000;
        end else if (!stall_D) begin
            instr_r    <= instr_F;
            pc_r       <= pc_F;
            pc_plus4_r <= pc_plus4_F;
        end
    end

    assign instr_D    = instr_r;
    assign pc_D       = pc_r;
    assign pc_plus4_D = pc_plus4_r;
endmodule
