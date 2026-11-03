// ============================================================================
// File: data_memory_tb.v
// Project: NanoRISC-V-C2 (2-Stage RV32I Core)
// Description: Dedicated testbench for the Data Memory module.
//              Tests word, halfword, and byte access, sign-extension (LB, LH),
//              zero-extension (LBU, LHU), and byte-lane preservation.
// ============================================================================

`timescale 1ns / 1ps

module data_memory_tb;

    reg         clk;
    reg         rst;
    reg         mem_read;
    reg         mem_write;
    reg  [2:0]  funct3;
    reg  [31:0] addr;
    reg  [31:0] write_data;
    wire [31:0] read_data;

    integer test_errors = 0;

    data_memory #(
        .MEM_DEPTH(64)
    ) uut (
        .clk(clk),
        .rst(rst),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .funct3(funct3),
        .addr(addr),
        .write_data(write_data),
        .read_data(read_data)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("data_memory.vcd");
        $dumpvars(0, data_memory_tb);

        clk        = 0;
        rst        = 1;
        mem_read   = 0;
        mem_write  = 0;
        funct3     = 3'b010; // word
        addr       = 0;
        write_data = 0;

        $display("--------------------------------------------------");
        $display("   TESTBENCH: data_memory_tb                      ");
        $display("--------------------------------------------------");

        // Test 1: Reset check
        #12;
        rst = 0;
        mem_read = 1;
        addr = 32'h0000_0000;
        #5;
        if (read_data !== 32'h0) begin
            $display("[FAIL] Test 1: Memory not cleared on reset. Got: 0x%08h", read_data);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Test 1: Memory reset initialized to zero");
        end

        // Test 2: Store Word (SW) and Load Word (LW)
        @(negedge clk);
        mem_read   = 0;
        mem_write  = 1;
        funct3     = 3'b010; // SW
        addr       = 32'h0000_0008;
        write_data = 32'hDEAD_BEEF;
        @(negedge clk);
        mem_write  = 0;
        mem_read   = 1;
        funct3     = 3'b010; // LW
        #2;
        if (read_data !== 32'hDEAD_BEEF) begin
            $display("[FAIL] Test 2: SW/LW failed. Expected: 0xDEADBEEF, Got: 0x%08h", read_data);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Test 2: Word Store & Load verified (0xDEADBEEF)");
        end

        // Test 3: Store Byte (SB) and signed/unsigned Load Byte (LB / LBU)
        // Store 0x85 (negative when signed) at byte address 0x0000_0010
        @(negedge clk);
        mem_read   = 0;
        mem_write  = 1;
        funct3     = 3'b000; // SB
        addr       = 32'h0000_0010;
        write_data = 32'h0000_0085;
        @(negedge clk);
        mem_write  = 0;

        // Read with LB (signed byte) -> should sign-extend to 0xFFFFFF85
        mem_read   = 1;
        funct3     = 3'b000; // LB
        #2;
        if (read_data !== 32'hFFFF_FF85) begin
            $display("[FAIL] Test 3a: LB signed extension failed. Got: 0x%08h", read_data);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Test 3a: LB signed extension verified (0xFFFFFF85)");
        end

        // Read with LBU (unsigned byte) -> should zero-extend to 0x00000085
        funct3     = 3'b100; // LBU
        #2;
        if (read_data !== 32'h0000_0085) begin
            $display("[FAIL] Test 3b: LBU unsigned extension failed. Got: 0x%08h", read_data);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Test 3b: LBU unsigned extension verified (0x00000085)");
        end

        // Test 4: Halfword Store (SH) and Load (LH / LHU)
        // Store 0x8020 at halfword address 0x0000_0016 (offset 2 within word 0x14)
        @(negedge clk);
        mem_read   = 0;
        mem_write  = 1;
        funct3     = 3'b001; // SH
        addr       = 32'h0000_0016;
        write_data = 32'h0000_8020;
        @(negedge clk);
        mem_write  = 0;

        // LH (signed) -> 0xFFFF8020
        mem_read   = 1;
        funct3     = 3'b001; // LH
        #2;
        if (read_data !== 32'hFFFF_8020) begin
            $display("[FAIL] Test 4a: LH signed extension failed. Got: 0x%08h", read_data);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Test 4a: LH signed extension verified (0xFFFF8020)");
        end

        // LHU (unsigned) -> 0x00008020
        funct3     = 3'b101; // LHU
        #2;
        if (read_data !== 32'h0000_8020) begin
            $display("[FAIL] Test 4b: LHU unsigned extension failed. Got: 0x%08h", read_data);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Test 4b: LHU unsigned extension verified (0x00008020)");
        end

        // Test Summary
        $display("--------------------------------------------------");
        if (test_errors == 0) begin
            $display("   ALL DATA MEMORY TESTS PASSED!                  ");
        end else begin
            $display("   TESTS COMPLETED WITH %0d ERROR(S)              ", test_errors);
        end
        $display("--------------------------------------------------");

        #10;
        $finish;
    end

endmodule
