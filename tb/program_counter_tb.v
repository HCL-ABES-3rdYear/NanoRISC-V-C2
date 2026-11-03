// ============================================================================
// File: program_counter_tb.v
// Project: NanoRISC-V-C2 (2-Stage RV32I Core)
// Description: Dedicated testbench for the Program Counter module.
//              Tests reset, sequential increments, branch/jump jumps, and stalls.
// ============================================================================

`timescale 1ns / 1ps

module program_counter_tb;

    // Testbench signals
    reg         clk;
    reg         rst;
    reg         stall;
    reg  [31:0] pc_next;
    wire [31:0] pc;

    integer test_errors = 0;

    // Instantiate Unit Under Test (UUT)
    program_counter uut (
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .pc_next(pc_next),
        .pc(pc)
    );

    // Clock generation: 100MHz (10ns period)
    always #5 clk = ~clk;

    initial begin
        // Waveform generation setup
        $dumpfile("program_counter.vcd");
        $dumpvars(0, program_counter_tb);

        // Initialize signals
        clk     = 0;
        rst     = 1;
        stall   = 0;
        pc_next = 32'h0000_0000;

        $display("--------------------------------------------------");
        $display("   TESTBENCH: program_counter_tb                  ");
        $display("--------------------------------------------------");

        // Test 1: Reset behavior
        #12; // Wait across clock edge
        if (pc !== 32'h0000_0000) begin
            $display("[FAIL] Test 1: Reset did not initialize PC to 0. Got: 0x%08h", pc);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Test 1: Reset successfully set PC to 0x00000000");
        end

        // Deassert reset
        @(negedge clk);
        rst     = 0;
        pc_next = 32'h0000_0004;

        // Test 2: Sequential PC increment
        @(negedge clk);
        if (pc !== 32'h0000_0004) begin
            $display("[FAIL] Test 2: PC failed to update to 0x00000004. Got: 0x%08h", pc);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Test 2: Sequential PC update verified (PC = 0x%08h)", pc);
        end

        // Test 3: Branch / Jump arbitrary target loading
        pc_next = 32'h0000_0040;
        @(negedge clk);
        if (pc !== 32'h0000_0040) begin
            $display("[FAIL] Test 3: Jump target 0x00000040 failed. Got: 0x%08h", pc);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Test 3: Jump target loading verified (PC = 0x%08h)", pc);
        end

        // Test 4: Stall behavior (PC must hold its current value)
        stall   = 1;
        pc_next = 32'h0000_0044; // attempted next PC
        @(negedge clk);
        if (pc !== 32'h0000_0040) begin
            $display("[FAIL] Test 4: PC changed during stall! Got: 0x%08h, expected: 0x00000040", pc);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Test 4: Stall behavior verified (PC maintained 0x%08h)", pc);
        end

        // Test 5: Stall release
        stall   = 0;
        @(negedge clk);
        if (pc !== 32'h0000_0044) begin
            $display("[FAIL] Test 5: PC failed to resume after stall. Got: 0x%08h", pc);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Test 5: Stall release verified (PC = 0x%08h)", pc);
        end

        // Test Summary
        $display("--------------------------------------------------");
        if (test_errors == 0) begin
            $display("   ALL PROGRAM COUNTER TESTS PASSED!              ");
        end else begin
            $display("   TESTS COMPLETED WITH %0d ERROR(S)              ", test_errors);
        end
        $display("--------------------------------------------------");

        #20;
        $finish;
    end

endmodule
