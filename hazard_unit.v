`timescale 1ns/1ps

//==============================================================================
// Hazard unit : forwarding + stall + flush
//==============================================================================
module hazard_unit (
    // operands needed in EX
    input  [4:0] rs1_E, rs2_E,
    // operands needed in ID (for load-use detection)
    input  [4:0] rs1_D, rs2_D,
    input        rs2_used_D,         // 0 for I-type: instr[24:20] is immediate bits
    // destination registers in later stages
    input  [4:0] rd_E, rd_M, rd_W,
    input        reg_write_M, reg_write_W,
    input        load_E,             // instruction in EX is a load
    input        pc_src_E,           // branch taken
    // outputs
    output [1:0] forward_A_E, forward_B_E,
    output       stall_F, stall_D,
    output       flush_D, flush_E
);

    // ---- forwarding (priority: MEM result is newer than WB result) ----------
    assign forward_A_E = (reg_write_M && (rd_M != 5'd0) && (rd_M == rs1_E)) ? 2'b10 :
                         (reg_write_W && (rd_W != 5'd0) && (rd_W == rs1_E)) ? 2'b01 : 2'b00;

    assign forward_B_E = (reg_write_M && (rd_M != 5'd0) && (rd_M == rs2_E)) ? 2'b10 :
                         (reg_write_W && (rd_W != 5'd0) && (rd_W == rs2_E)) ? 2'b01 : 2'b00;

    // ---- load-use hazard : a load in EX, its result needed by the instr in ID
    wire load_use = load_E && (rd_E != 5'd0) &&
                    ((rd_E == rs1_D) || (rs2_used_D && (rd_E == rs2_D)));

    assign stall_F = load_use;
    assign stall_D = load_use;

    // ---- control hazard / bubble insertion ---------------------------------
    assign flush_D = pc_src_E;               // kill the instruction in ID
    assign flush_E = pc_src_E | load_use;    // kill EX (branch) or insert bubble (stall)
endmodule
