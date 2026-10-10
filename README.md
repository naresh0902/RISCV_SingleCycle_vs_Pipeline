# RISC-V RV32I: Single-Cycle vs 5-Stage Pipelined Core

Verilog implementations of two RV32I processor cores that run the **same program**, together with a self-checking testbench that compares them on cycle count, CPI, hazard cost and (modelled) execution time.

- **Single-cycle core**: every instruction completes in one clock cycle (CPI = 1, long clock period).
- **5-stage pipelined core**: IF → ID → EX → MEM → WB, with data forwarding, load-use stalling and branch flushing (short clock period, CPI > 1).

Both cores share the same building blocks (ALU, register file, decoders, memories), so the only difference between them is the micro-architecture.

---

## Features

| | Single-cycle | Pipeline |
|---|---|---|
| Instructions | add, sub, and, or, slt, addi, lw, sw, beq | same |
| Data hazards | n/a | Forwarding MEM→EX and WB→EX |
| Load-use hazard | n/a | 1-cycle stall + bubble |
| Control hazard | n/a | Branch resolved in EX, flush 2 instructions when taken (predict not taken) |
| Register file | Plain | Write-through (fixes the WB→ID hazard) |
| Reset | Active-low asynchronous `rst_n` | same |

## Architecture


Signal names carry a stage suffix (`_F`, `_D`, `_E`, `_M`, `_W`). Each stage module contains its own pipeline register at its output.

### Hazard handling

| Hazard | Detection | Action |
|---|---|---|
| RAW, producer in MEM | `RegWriteM && rd_M != 0 && rd_M == rs_E` | Forward `ALU_ResultM` to EX |
| RAW, producer in WB | `RegWriteW && rd_W != 0 && rd_W == rs_E` | Forward `ResultW` to EX |
| RAW, producer 3 instructions back | write-through register file | Read returns the value being written |
| Load-use | load in EX and `rd_E` matches `rs1_D`/`rs2_D` | Stall PC and IF/ID, flush ID/EX (1 bubble) |
| Taken branch | `Branch_E & Zero_E` | Flush IF/ID and ID/EX (2-cycle penalty) |

`rs2` is only compared for R-, S- and B-type instructions, so I-type immediates do not cause false stalls.

## Repository structure (one module per file)

```
.
├── design.sv               # top-level file that `include`s every module
├── tb_compare.v            # comparison testbench
│
├── mux2.v  mux3.v  adder32.v  pc_reg.v
├── instruction_memory.v    # benchmark program is hard-coded here
├── data_memory.v
├── register_file.v         # parameter WRITE_THROUGH (0 = single-cycle, 1 = pipeline)
├── sign_extend.v           # I / S / B immediates
├── alu.v  alu_decoder.v  main_decoder.v  control_unit.v
│
├── riscv_single_cycle.v    # single-cycle top
│
├── hazard_unit.v           # forwarding + stall + flush
├── fetch_stage.v  decode_stage.v  execute_stage.v
├── memory_stage.v  writeback_stage.v
└── riscv_pipeline.v        # pipeline top
```

## Running the simulation

**Icarus Verilog (local)**

```bash
iverilog -g2012 -o sim design.sv tb_compare.v
vvp sim
```

**EDA Playground**

1. Add every `.v` file with the "+" button (keep the exact file names, `design.sv` includes them by name).
2. Put `design.sv` in the design pane and `tb_compare.v` in the testbench pane.
3. Simulator: Icarus Verilog 12, compile option `-g2012`, top module `tb_compare`.

The testbench dumps `dump.vcd` for waveform viewing (EPWave / GTKWave).

## Benchmark program

The program is assembled into `instruction_memory.v` (no `.hex` file needed). It exercises every feature of the pipeline:

| Part | Purpose |
|---|---|
| Loop summing 1 to 10 | branches (11 taken), forwarding on `add`/`addi` chains |
| `sw` then `lw` then dependent `add` | load-use hazard |
| `addi` → `addi` → `add` → `sub` | forwarding from MEM and WB |
| `and`, `or`, `slt` | ALU operations |
| Final `sw x5, 4(x0)` | "done" marker watched by the testbench |

Expected final state (checked automatically for **both** cores):

| Item | Value |
|---|---|
| x1 (sum) / x4 | 55 |
| x5 | 110 |
| x7, x8, x9, x10, x11, x12 | 8, 15, 8, 8, 15, 1 |
| mem[0], mem[1], mem[2] | 55, 110, 8 |

## Results

Simulation output:

```
==================================================================
   RISC-V  SINGLE-CYCLE  vs  5-STAGE PIPELINE  -  RESULTS
==================================================================
 Functional check            : PASS (both cores correct)
 Instructions executed       : 55
------------------------------------------------------------------
                               Single-cycle      Pipeline
 Clock cycles                :         55              81
 CPI                         :      1.000           1.473
 Load-use stall cycles       :          -               1
 Taken-branch flushes        :          -              11  (x2 cycles each)
 Assumed clock period (ps)   :        770             250
 Assumed Fmax (MHz)          :     1298.7          4000.0
 Execution time (ns)         :      42.35           20.25
------------------------------------------------------------------
 Speed-up of pipeline        : 2.09 x
 Cycle overhead of pipeline  : 26 extra cycles (3 fill + 1 stall + 22 flush)
==================================================================
```

| Metric | Single-cycle | Pipeline |
|---|---|---|
| Instructions executed | 55 | 55 |
| Clock cycles | 55 | 81 |
| CPI | 1.000 | 1.473 |
| Clock period (assumed) | 770 ps | 250 ps |
| Execution time | 42.35 ns | 20.25 ns |
| **Speed-up** | 1.00× | **2.09×** |

### Analysis

- **Cycle count (measured):** the pipeline needs 26 extra cycles: 3 to fill the pipeline, 1 for the load-use stall and 22 for the 11 taken branches (2 cycles each). Branches dominate the overhead because the benchmark is a tight loop.
- **Clock period (assumed):** the single-cycle clock must cover the whole path, `T_IMEM + T_RFREAD + T_ALU + T_DMEM + T_RFWR = 770 ps`. The pipeline clock is set by the slowest stage plus register overhead, `200 + 50 = 250 ps`, about 3.08× faster.
- **Net speed-up:** 3.08× (clock) ÷ 1.473 (CPI penalty) ≈ **2.09×**. The pipeline wins even with the hazard penalties, but it falls well short of the ideal 5× because of unequal stage delays, register overhead and the branch penalty.

### Timing model: important note

Cycle counts, CPI, stalls and flushes come **directly from simulation**. The clock periods do **not**: they use textbook stage delays (Harris & Harris), set by the `T_IMEM`, `T_RFREAD`, `T_ALU`, `T_DMEM`, `T_RFWR` and `T_REG` parameters at the top of `tb_compare.v`. For a rigorous comparison, synthesize each core (Vivado / Quartus / Yosys), take the real Fmax and area, and update those parameters.

## Notable design decisions and fixes

- **Write-through register file** in the pipeline removes the WB→ID hazard. It is disabled for the single-cycle core, where it would create a combinational loop (register file → ALU → result → register file).
- **B-type immediate** is decoded properly in `sign_extend.v`, and the branch target is computed in EX.
- **Signed SLT** uses a real signed comparison, not the sign bit of the subtraction (which fails on overflow).
- **Store data is forwarded** before it enters the EX/MEM register, so `sw` of a freshly computed value is correct.

## Limitations and future work

- Only 9 instructions are supported (no `jal`, `jalr`, `lui`, `auipc`, shifts, `xor`, branches other than `beq`, byte/halfword accesses).
- Branches always resolve in EX with a predict-not-taken policy; adding a branch predictor or resolving in ID would cut the dominant 22-cycle penalty.
- Single benchmark only; adding more workloads (branch-light, memory-heavy) would show how CPI varies.
- Replace the assumed timing with post-synthesis Fmax, LUT/area and power numbers on a target FPGA.
- Add a RISC-V compliance or random-instruction test against a reference model.

## License

MIT (or choose your own).
