// design.sv : top-level file that pulls in every module (one module per file).
// Compile ORDER does not matter for Verilog modules, but the leaf blocks are
// listed first for readability.
`include "mux2.v"
`include "mux3.v"
`include "adder32.v"
`include "pc_reg.v"
`include "instruction_memory.v"
`include "data_memory.v"
`include "register_file.v"
`include "sign_extend.v"
`include "alu.v"
`include "main_decoder.v"
`include "alu_decoder.v"
`include "control_unit.v"

// ---- single-cycle core
`include "riscv_single_cycle.v"

// ---- pipelined core
`include "hazard_unit.v"
`include "fetch_stage.v"
`include "decode_stage.v"
`include "execute_stage.v"
`include "memory_stage.v"
`include "writeback_stage.v"
`include "riscv_pipeline.v"
