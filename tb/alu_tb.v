// ============================================================================
// File: alu_tb.v
// Project: NanoRISC-V-C2 (2-Stage RV32I Core)
// Description: Dedicated testbench for the Arithmetic Logic Unit (ALU).
//              Tests all 11 ALU operations, boundary conditions, signed/unsigned
//              comparisons, shift directions, and the zero flag.
// ============================================================================

`timescale 1ns / 1ps

module alu_tb;

    reg  [31:0] a;
    reg  [31:0] b;
    reg  [3:0]  alu_ctrl;
    wire [31:0] result;
    wire        zero;

    integer test_errors = 0;

    localparam ALU_ADD    = 4'b0000;
    localparam ALU_SUB    = 4'b0001;
    localparam ALU_SLL    = 4'b0010;
    localparam ALU_SLT    = 4'b0011;
    localparam ALU_SLTU   = 4'b0100;
    localparam ALU_XOR    = 4'b0101;
    localparam ALU_SRL    = 4'b0110;
    localparam ALU_SRA    = 4'b0111;
    localparam ALU_OR     = 4'b1000;
    localparam ALU_AND    = 4'b1001;
    localparam ALU_PASS_B = 4'b1010;

    alu uut (
        .a(a),
        .b(b),
        .alu_ctrl(alu_ctrl),
        .result(result),
        .zero(zero)
    );

    initial begin
        $dumpfile("alu.vcd");
        $dumpvars(0, alu_tb);

        $display("--------------------------------------------------");
        $display("   TESTBENCH: alu_tb                              ");
        $display("--------------------------------------------------");

        // Test 1: ADD (15 + 25 = 40)
        a = 32'd15; b = 32'd25; alu_ctrl = ALU_ADD;
        #10;
        if (result !== 32'd40 || zero !== 1'b0) begin
            $display("[FAIL] Test 1: ADD failed. Got: %d, zero: %b", result, zero);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Test 1: ADD (15 + 25 = %0d)", result);
        end

        // Test 2: SUB with Zero output (50 - 50 = 0, zero = 1)
        a = 32'd50; b = 32'd50; alu_ctrl = ALU_SUB;
        #10;
        if (result !== 32'd0 || zero !== 1'b1) begin
            $display("[FAIL] Test 2: SUB/Zero flag failed. Got: %d, zero: %b", result, zero);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Test 2: SUB & Zero flag verified (50 - 50 = 0, zero=1)");
        end

        // Test 3: SLL (Shift Left Logical: 1 << 4 = 16)
        a = 32'd1; b = 32'd4; alu_ctrl = ALU_SLL;
        #10;
        if (result !== 32'd16) begin
            $display("[FAIL] Test 3: SLL failed. Got: %d", result);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Test 3: SLL (1 << 4 = %0d)", result);
        end

        // Test 4: SLT Signed Comparison (-10 < 5 = 1)
        a = -32'd10; b = 32'd5; alu_ctrl = ALU_SLT;
        #10;
        if (result !== 32'd1) begin
            $display("[FAIL] Test 4: SLT failed. Got: %d", result);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Test 4: SLT signed (-10 < 5 = %0d)", result);
        end

        // Test 5: SLTU Unsigned Comparison (5 < -10(0xFFFFFFF6) = 1)
        a = 32'd5; b = -32'd10; alu_ctrl = ALU_SLTU;
        #10;
        if (result !== 32'd1) begin
            $display("[FAIL] Test 5: SLTU failed. Got: %d", result);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Test 5: SLTU unsigned (5 < 0xFFFFFFF6 = %0d)", result);
        end

        // Test 6: XOR (0xAA ^ 0x55 = 0xFF)
        a = 32'h0000_00AA; b = 32'h0000_0055; alu_ctrl = ALU_XOR;
        #10;
        if (result !== 32'h0000_00FF) begin
            $display("[FAIL] Test 6: XOR failed. Got: 0x%08h", result);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Test 6: XOR (0xAA ^ 0x55 = 0x%02h)", result);
        end

        // Test 7: SRL (Logical Shift Right: 0x80000000 >> 4 = 0x08000000)
        a = 32'h8000_0000; b = 32'd4; alu_ctrl = ALU_SRL;
        #10;
        if (result !== 32'h0800_0000) begin
            $display("[FAIL] Test 7: SRL failed. Got: 0x%08h", result);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Test 7: SRL (0x80000000 >> 4 = 0x%08h)", result);
        end

        // Test 8: SRA (Arithmetic Shift Right: 0x80000000 >>> 4 = 0xF8000000)
        a = 32'h8000_0000; b = 32'd4; alu_ctrl = ALU_SRA;
        #10;
        if (result !== 32'hF800_0000) begin
            $display("[FAIL] Test 8: SRA failed. Got: 0x%08h", result);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Test 8: SRA sign-extension (0x80000000 >>> 4 = 0x%08h)", result);
        end

        // Test 9: OR (0xF0 | 0x0F = 0xFF)
        a = 32'h0000_00F0; b = 32'h0000_000F; alu_ctrl = ALU_OR;
        #10;
        if (result !== 32'h0000_00FF) begin
            $display("[FAIL] Test 9: OR failed. Got: 0x%08h", result);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Test 9: OR (0xF0 | 0x0F = 0x%02h)", result);
        end

        // Test 10: AND (0xFF & 0x0F = 0x0F)
        a = 32'h0000_00FF; b = 32'h0000_000F; alu_ctrl = ALU_AND;
        #10;
        if (result !== 32'h0000_000F) begin
            $display("[FAIL] Test 10: AND failed. Got: 0x%08h", result);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Test 10: AND (0xFF & 0x0F = 0x%02h)", result);
        end

        // Test 11: PASS_B (result = b)
        a = 32'h1234_5678; b = 32'hCAFE_BABE; alu_ctrl = ALU_PASS_B;
        #10;
        if (result !== 32'hCAFE_BABE) begin
            $display("[FAIL] Test 11: PASS_B failed. Got: 0x%08h", result);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Test 11: PASS_B (b = 0x%08h)", result);
        end

        // Test Summary
        $display("--------------------------------------------------");
        if (test_errors == 0) begin
            $display("   ALL ALU TESTS PASSED!                          ");
        end else begin
            $display("   TESTS COMPLETED WITH %0d ERROR(S)              ", test_errors);
        end
        $display("--------------------------------------------------");

        #10;
        $finish;
    end

endmodule
