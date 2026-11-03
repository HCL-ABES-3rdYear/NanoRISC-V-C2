// ============================================================================
// File: instruction_memory_tb.v
// Project: NanoRISC-V-C2 (2-Stage RV32I Core)
// Description: Dedicated testbench for Instruction Memory module.
//              Tests word-aligned fetching, arbitrary address reading, and
//              out-of-bounds protection.
// ============================================================================

`timescale 1ns / 1ps

module instruction_memory_tb;

    reg  [31:0] addr;
    wire [31:0] instruction;

    integer test_errors = 0;

    // Instantiate UUT with small depth for quick testing
    instruction_memory #(
        .MEM_DEPTH(16)
    ) uut (
        .addr(addr),
        .instruction(instruction)
    );

    initial begin
        $dumpfile("instruction_memory.vcd");
        $dumpvars(0, instruction_memory_tb);

        $display("--------------------------------------------------");
        $display("   TESTBENCH: instruction_memory_tb               ");
        $display("--------------------------------------------------");

        // Test 1: Fetch instruction at PC = 0x00 (ADDI x1, x0, 10)
        addr = 32'h0000_0000;
        #10;
        if (instruction !== 32'h00a00093) begin
            $display("[FAIL] Test 1: Expected 0x00a00093 at PC 0x0, got: 0x%08h", instruction);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Test 1: PC 0x00 fetched 0x%08h (addi x1, x0, 10)", instruction);
        end

        // Test 2: Fetch instruction at PC = 0x04 (ADDI x2, x0, 20)
        addr = 32'h0000_0004;
        #10;
        if (instruction !== 32'h01400113) begin
            $display("[FAIL] Test 2: Expected 0x01400113 at PC 0x4, got: 0x%08h", instruction);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Test 2: PC 0x04 fetched 0x%08h (addi x2, x0, 20)", instruction);
        end

        // Test 3: Fetch instruction at PC = 0x08 (ADD x3, x1, x2)
        addr = 32'h0000_0008;
        #10;
        if (instruction !== 32'h002081b3) begin
            $display("[FAIL] Test 3: Expected 0x002081b3 at PC 0x8, got: 0x%08h", instruction);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Test 3: PC 0x08 fetched 0x%08h (add x3, x1, x2)", instruction);
        end

        // Test 4: Fetch instruction at PC = 0x18 (BEQ x4, x2, 8)
        addr = 32'h0000_0018;
        #10;
        if (instruction !== 32'h00220463) begin
            $display("[FAIL] Test 4: Expected 0x00220463 at PC 0x18, got: 0x%08h", instruction);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Test 4: PC 0x18 fetched 0x%08h (beq x4, x2, 8)", instruction);
        end

        // Test 5: Out of bounds fetch (PC = 0x1000) -> Should return NOP (0x00000013)
        addr = 32'h0000_1000;
        #10;
        if (instruction !== 32'h0000_0013) begin
            $display("[FAIL] Test 5: Expected NOP 0x00000013 for out-of-bounds, got: 0x%08h", instruction);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Test 5: Out-of-bounds address safely returned NOP (0x%08h)", instruction);
        end

        // Test Summary
        $display("--------------------------------------------------");
        if (test_errors == 0) begin
            $display("   ALL INSTRUCTION MEMORY TESTS PASSED!           ");
        end else begin
            $display("   TESTS COMPLETED WITH %0d ERROR(S)              ", test_errors);
        end
        $display("--------------------------------------------------");

        #10;
        $finish;
    end

endmodule
