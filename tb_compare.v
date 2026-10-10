//==============================================================================
//  tb_compare.v
//  Runs the SAME program on the single-cycle core and the pipelined core,
//  checks that both give the correct architectural result, and prints a
//  performance comparison (cycles, CPI, stalls, flushes, execution time).
//
//  Edit the three T_* parameters below to match your own synthesis results
//  (e.g. Fmax from Vivado / Quartus / Yosys). The defaults are the textbook
//  (Harris & Harris) stage delays and are only an ASSUMPTION.
//==============================================================================
`timescale 1ns/1ps

module tb_compare;

    // ------------------------------------------------ timing model (in ps)
    parameter integer T_IMEM   = 200;  // instruction memory read
    parameter integer T_RFREAD = 150;  // register file read
    parameter integer T_ALU    = 120;  // ALU
    parameter integer T_DMEM   = 200;  // data memory read/write
    parameter integer T_RFWR   = 100;  // register file setup (write-back)
    parameter integer T_REG    = 50;   // pipeline-register overhead (clk->Q + setup)

    parameter integer MAX_CYCLES = 2000;

    // ------------------------------------------------------------ clock/reset
    reg clk   = 1'b0;
    reg rst_n = 1'b0;
    always #5 clk = ~clk;                      // 10 ns simulation clock for both cores

    riscv_single_cycle sc (.clk(clk), .rst_n(rst_n));
    riscv_pipeline     pl (.clk(clk), .rst_n(rst_n));

    // -------------------------------------------------------- performance counters
    integer sc_cycles = 0,  pl_cycles = 0;
    integer pl_stalls = 0,  pl_flushes = 0;
    reg     sc_done = 0,    pl_done = 0;

    // "done" = the final "sw x5,4(x0)" writes memory (address 4)
    always @(posedge clk) if (rst_n && !sc_done) begin
        sc_cycles = sc_cycles + 1;
        if (sc.mem_write && sc.alu_result == 32'd4) sc_done = 1;
    end

    always @(posedge clk) if (rst_n && !pl_done) begin
        pl_cycles = pl_cycles + 1;
        if (pl.mem_write_M && pl.alu_result_M == 32'd4)
            pl_done = 1;                                            // final store completes
        else begin
            if (pl.Hazard.stall_F) pl_stalls  = pl_stalls  + 1;     // load-use bubbles
            if (pl.pc_src_E)       pl_flushes = pl_flushes + 1;     // taken branches
        end
    end

    // ------------------------------------------------------------ test control
    integer errors = 0;
    integer instr_count;
    real    t_sc, t_pl, exec_sc, exec_pl, cpi_sc, cpi_pl;
    integer max_stage;

    task check(input [255:0] name, input [31:0] got, input [31:0] exp);
        begin
            if (got !== exp) begin
                errors = errors + 1;
                $display("  [FAIL] %0s : got %0d, expected %0d", name, got, exp);
            end
        end
    endtask

    task check_core_state;      // compares both cores with the expected results
        begin
            check("SC x1 (sum)",  sc.u_rf.regs[1],  55);
            check("PL x1 (sum)",  pl.Decode.u_rf.regs[1],  55);
            check("SC x4",        sc.u_rf.regs[4],  55);
            check("PL x4",        pl.Decode.u_rf.regs[4],  55);
            check("SC x5",        sc.u_rf.regs[5],  110);
            check("PL x5",        pl.Decode.u_rf.regs[5],  110);
            check("SC x7",        sc.u_rf.regs[7],  8);
            check("PL x7",        pl.Decode.u_rf.regs[7],  8);
            check("SC x8",        sc.u_rf.regs[8],  15);
            check("PL x8",        pl.Decode.u_rf.regs[8],  15);
            check("SC x9",        sc.u_rf.regs[9],  8);
            check("PL x9",        pl.Decode.u_rf.regs[9],  8);
            check("SC x10",       sc.u_rf.regs[10], 8);
            check("PL x10",       pl.Decode.u_rf.regs[10], 8);
            check("SC x11",       sc.u_rf.regs[11], 15);
            check("PL x11",       pl.Decode.u_rf.regs[11], 15);
            check("SC x12",       sc.u_rf.regs[12], 1);
            check("PL x12",       pl.Decode.u_rf.regs[12], 1);
            check("SC mem[0]",    sc.u_dmem.mem[0], 55);
            check("PL mem[0]",    pl.Memory.u_dmem.mem[0], 55);
            check("SC mem[1]",    sc.u_dmem.mem[1], 110);
            check("PL mem[1]",    pl.Memory.u_dmem.mem[1], 110);
            check("SC mem[2]",    sc.u_dmem.mem[2], 8);
            check("PL mem[2]",    pl.Memory.u_dmem.mem[2], 8);
        end
    endtask

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_compare);

        #22 rst_n = 1'b1;                                   // release reset
        wait ((sc_done && pl_done) || (sc_cycles > MAX_CYCLES) || (pl_cycles > MAX_CYCLES));
        @(posedge clk); #1;                                 // let last write land
        @(posedge clk); #1;                                 // let WB of final instr finish

        if (!(sc_done && pl_done)) begin
            $display("TIMEOUT: a core did not finish (sc_done=%0d pl_done=%0d)", sc_done, pl_done);
            errors = errors + 1;
        end

        check_core_state;

        // ---------------------------------------------------- derived metrics
        instr_count = sc_cycles;                            // CPI = 1 -> cycles = instructions
        cpi_sc = 1.0 * sc_cycles / instr_count;
        cpi_pl = 1.0 * pl_cycles / instr_count;

        // clock period = sum of all stage delays (single-cycle)
        t_sc = T_IMEM + T_RFREAD + T_ALU + T_DMEM + T_RFWR;
        // clock period = slowest stage + pipeline-register overhead (pipeline)
        max_stage = T_IMEM;
        if (T_RFREAD > max_stage) max_stage = T_RFREAD;
        if (T_ALU    > max_stage) max_stage = T_ALU;
        if (T_DMEM   > max_stage) max_stage = T_DMEM;
        if (T_RFWR   > max_stage) max_stage = T_RFWR;
        t_pl = max_stage + T_REG;

        exec_sc = sc_cycles * t_sc / 1000.0;                // ns
        exec_pl = pl_cycles * t_pl / 1000.0;                // ns

        $display("");
        $display("==================================================================");
        $display("   RISC-V  SINGLE-CYCLE  vs  5-STAGE PIPELINE  -  RESULTS");
        $display("==================================================================");
        $display(" Functional check            : %s", (errors == 0) ? "PASS (both cores correct)" : "FAIL");
        $display(" Instructions executed       : %0d", instr_count);
        $display("------------------------------------------------------------------");
        $display("                               Single-cycle      Pipeline");
        $display(" Clock cycles                : %10d      %10d", sc_cycles, pl_cycles);
        $display(" CPI                         : %10.3f      %10.3f", cpi_sc, cpi_pl);
        $display(" Load-use stall cycles       : %10s      %10d", "-", pl_stalls);
        $display(" Taken-branch flushes        : %10s      %10d  (x2 cycles each)", "-", pl_flushes);
        $display(" Assumed clock period (ps)   : %10.0f      %10.0f", t_sc, t_pl);
        $display(" Assumed Fmax (MHz)          : %10.1f      %10.1f", 1.0e6/t_sc, 1.0e6/t_pl);
        $display(" Execution time (ns)         : %10.2f      %10.2f", exec_sc, exec_pl);
        $display("------------------------------------------------------------------");
        $display(" Speed-up of pipeline        : %0.2f x", exec_sc / exec_pl);
        $display(" Cycle overhead of pipeline  : %0d extra cycles (%0d fill + %0d stall + %0d flush)",
                  pl_cycles - sc_cycles, pl_cycles - sc_cycles - pl_stalls - 2*pl_flushes,
                  pl_stalls, 2*pl_flushes);
        $display("==================================================================");
        $display("");
        $finish;
    end
endmodule
