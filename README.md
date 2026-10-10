# RISC-V Single-Cycle vs 5-Stage Pipeline  (one module per file)

## EDA Playground
1. Add every .v file of this folder with the "+" button (keep the exact file
   names, because design.sv pulls them in with `include).
2. design.sv   -> design pane.   tb_compare.v -> testbench pane.
3. Top module: tb_compare.   Compile option: -g2012.
Local run: iverilog -g2012 design.sv tb_compare.v && vvp a.out

## Files
Shared      : mux2, mux3, adder32, pc_reg, instruction_memory, data_memory,
              register_file, sign_extend, alu, main_decoder, alu_decoder, control_unit
Single-cycle: riscv_single_cycle
Pipeline    : hazard_unit, fetch_stage, decode_stage, execute_stage,
              memory_stage, writeback_stage, riscv_pipeline
Test        : tb_compare (runs both cores, checks results, prints comparison)

Change the program in instruction_memory.v (mem[n] = ...).
