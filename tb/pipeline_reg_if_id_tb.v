// ============================================================================
// File: pipeline_reg_if_id_tb.v
// Project: NanoRISC-V-C2 (2-Stage RV32I Core)
// Description: Dedicated testbench for the Stage 1 to Stage 2 Pipeline Register.
//              Tests normal latching, synchronous flush, reset, and stall.
// ============================================================================

`timescale 1ns / 1ps

module pipeline_reg_if_id_tb;

    reg         clk;
    reg         rst;
    reg         flush;
    reg         stall;
    reg  [31:0] pc_if;
    reg  [31:0] inst_if;
    wire [31:0] pc_id;
    wire [31:0] inst_id;

    integer test_errors = 0;

    pipeline_reg_if_id uut (
        .clk(clk),
        .rst(rst),
        .flush(flush),
        .stall(stall),
        .pc_if(pc_if),
        .inst_if(inst_if),
        .pc_id(pc_id),
        .inst_id(inst_id)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("pipeline_reg_if_id.vcd");
        $dumpvars(0, pipeline_reg_if_id_tb);

        clk     = 0;
        rst     = 1;
        flush   = 0;
        stall   = 0;
        pc_if   = 32'h0000_0000;
        inst_if = 32'h0000_0013;

        $display("--------------------------------------------------");
        $display("   TESTBENCH: pipeline_reg_if_id_tb               ");
        $display("--------------------------------------------------");

        // Test 1: Reset check
        #12;
        if (inst_id !== 32'h0000_0013 || pc_id !== 32'h0000_0000) begin
            $display("[FAIL] Test 1: Reset failed. pc_id: 0x%08h, inst_id: 0x%08h", pc_id, inst_id);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Test 1: Reset initialized pipeline register to NOP (0x00000013)");
        end

        // Deassert reset, supply valid instruction
        @(negedge clk);
        rst     = 0;
        pc_if   = 32'h0000_0004;
        inst_if = 32'h1234_5678;

        // Test 2: Normal latching across clock edge
        @(negedge clk);
        if (pc_id !== 32'h0000_0004 || inst_id !== 32'h1234_5678) begin
            $display("[FAIL] Test 2: Normal latch failed. pc_id: 0x%08h, inst_id: 0x%08h", pc_id, inst_id);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Test 2: Normal instruction latch verified (0x12345678)");
        end

        // Test 3: Stall signal
        stall   = 1;
        pc_if   = 32'h0000_0008;
        inst_if = 32'h9999_8888;
        @(negedge clk);
        if (pc_id !== 32'h0000_0004 || inst_id !== 32'h1234_5678) begin
            $display("[FAIL] Test 3: Stall failed. Register updated unexpectedly.");
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Test 3: Stall preserved previous stage contents");
        end

        // Test 4: Flush signal (turns instruction into NOP bubble)
        stall   = 0;
        flush   = 1;
        @(negedge clk);
        if (inst_id !== 32'h0000_0013) begin
            $display("[FAIL] Test 4: Flush failed to inject NOP bubble. Got: 0x%08h", inst_id);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Test 4: Flush successfully injected NOP bubble");
        end

        // Test Summary
        $display("--------------------------------------------------");
        if (test_errors == 0) begin
            $display("   ALL PIPELINE REGISTER TESTS PASSED!            ");
        end else begin
            $display("   TESTS COMPLETED WITH %0d ERROR(S)              ", test_errors);
        end
        $display("--------------------------------------------------");

        #10;
        $finish;
    end

endmodule
