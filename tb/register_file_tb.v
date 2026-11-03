// ============================================================================
// File: register_file_tb.v
// Project: NanoRISC-V-C2 (2-Stage RV32I Core)
// Description: Dedicated testbench for the RV32I Register File.
//              Tests x0 zero-invariance, dual-port reading, writing,
//              write-enable gating, and internal write-through forwarding.
// ============================================================================

`timescale 1ns / 1ps

module register_file_tb;

    reg         clk;
    reg         rst;
    reg         reg_write_en;
    reg  [4:0]  rs1_addr;
    reg  [4:0]  rs2_addr;
    reg  [4:0]  rd_addr;
    reg  [31:0] rd_data;
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;

    integer test_errors = 0;

    register_file uut (
        .clk(clk),
        .rst(rst),
        .reg_write_en(reg_write_en),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rd_addr(rd_addr),
        .rd_data(rd_data),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("register_file.vcd");
        $dumpvars(0, register_file_tb);

        clk          = 0;
        rst          = 1;
        reg_write_en = 0;
        rs1_addr     = 0;
        rs2_addr     = 0;
        rd_addr      = 0;
        rd_data      = 0;

        $display("--------------------------------------------------");
        $display("   TESTBENCH: register_file_tb                    ");
        $display("--------------------------------------------------");

        // Test 1: Reset behavior
        #12;
        rst = 0;
        rs1_addr = 5'd1;
        rs2_addr = 5'd31;
        #5;
        if (rs1_data !== 32'b0 || rs2_data !== 32'b0) begin
            $display("[FAIL] Test 1: Reset failed. rs1: 0x%08h, rs2: 0x%08h", rs1_data, rs2_data);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Test 1: Reset initialized registers to 0x00000000");
        end

        // Test 2: Attempt writing to x0 (Must remain 0)
        @(negedge clk);
        reg_write_en = 1;
        rd_addr      = 5'd0;
        rd_data      = 32'hDEADBEEF;
        @(posedge clk);
        #1;
        rs1_addr = 5'd0;
        #2;
        if (rs1_data !== 32'h0000_0000) begin
            $display("[FAIL] Test 2: x0 was overwritten! Got: 0x%08h", rs1_data);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Test 2: x0 hardwired zero property preserved");
        end

        // Test 3: Standard write and dual-port read
        @(negedge clk);
        reg_write_en = 1;
        rd_addr      = 5'd5;
        rd_data      = 32'hA5A5_5A5A;
        @(negedge clk);
        rd_addr      = 5'd10;
        rd_data      = 32'h1234_5678;
        @(negedge clk);
        reg_write_en = 0;

        // Read back x5 on rs1 and x10 on rs2
        rs1_addr     = 5'd5;
        rs2_addr     = 5'd10;
        #2;
        if (rs1_data !== 32'hA5A5_5A5A || rs2_data !== 32'h1234_5678) begin
            $display("[FAIL] Test 3: Read back failed. rs1: 0x%08h, rs2: 0x%08h", rs1_data, rs2_data);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Test 3: Dual-port read verified (x5=0x%08h, x10=0x%08h)", rs1_data, rs2_data);
        end

        // Test 4: Write-Enable gating (reg_write_en = 0)
        @(negedge clk);
        reg_write_en = 0;
        rd_addr      = 5'd5;
        rd_data      = 32'hFFFF_FFFF;
        @(negedge clk);
        rs1_addr     = 5'd5;
        #2;
        if (rs1_data !== 32'hA5A5_5A5A) begin
            $display("[FAIL] Test 4: Register modified when reg_write_en=0. Got: 0x%08h", rs1_data);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Test 4: Write-enable gating verified");
        end

        // Test 5: Internal Forwarding / Bypass (Read same register being written)
        @(negedge clk);
        reg_write_en = 1;
        rd_addr      = 5'd7;
        rd_data      = 32'hCAFE_BABE;
        rs1_addr     = 5'd7; // Same cycle read
        #2;
        if (rs1_data !== 32'hCAFE_BABE) begin
            $display("[FAIL] Test 5: Forwarding failed. Got: 0x%08h, expected: 0xCAFEBABE", rs1_data);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Test 5: Same-cycle write-through forwarding verified");
        end

        // Test Summary
        $display("--------------------------------------------------");
        if (test_errors == 0) begin
            $display("   ALL REGISTER FILE TESTS PASSED!                ");
        end else begin
            $display("   TESTS COMPLETED WITH %0d ERROR(S)              ", test_errors);
        end
        $display("--------------------------------------------------");

        #10;
        $finish;
    end

endmodule
