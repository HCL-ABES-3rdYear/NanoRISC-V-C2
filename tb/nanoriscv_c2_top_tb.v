// ============================================================================
// File: nanoriscv_c2_top_tb.v
// Project: NanoRISC-V-C2 (2-Stage RV32I Core)
// Description: Dedicated testbench for the NanoRISC-V-C2 top-level processor core.
//              Runs an integrated test program exercising ALU operations, data
//              memory loads and stores, branch taken resolution, pipeline flush
//              verification (flushing wrong-path instructions), and register states.
// ============================================================================

`timescale 1ns / 1ps

module nanoriscv_c2_top_tb;

    reg         clk;
    reg         rst;

    // Debug signals from top
    wire [31:0] debug_pc_if;
    wire [31:0] debug_pc_id;
    wire [31:0] debug_inst_id;
    wire [31:0] debug_alu_result;
    wire [31:0] debug_wb_data;
    wire [4:0]  debug_wb_reg;
    wire        debug_reg_write;

    integer cycle_count = 0;
    integer test_errors = 0;

    // Instantiate NanoRISC-V-C2 Top-Level Core
    nanoriscv_c2_top #(
        .IMEM_DEPTH(1024),
        .DMEM_DEPTH(1024),
        .HEX_FILE("") // Uses default verification program
    ) uut (
        .clk(clk),
        .rst(rst),
        .debug_pc_if(debug_pc_if),
        .debug_pc_id(debug_pc_id),
        .debug_inst_id(debug_inst_id),
        .debug_alu_result(debug_alu_result),
        .debug_wb_data(debug_wb_data),
        .debug_wb_reg(debug_wb_reg),
        .debug_reg_write(debug_reg_write)
    );

    // Clock generation: 100MHz (10ns period)
    always #5 clk = ~clk;

    // Cycle logger for detailed execution tracking
    always @(posedge clk) begin
        if (!rst) begin
            cycle_count = cycle_count + 1;
            if (debug_reg_write && debug_wb_reg != 5'd0) begin
                $display("[Cycle %02d] PC_EX: 0x%08h | Inst: 0x%08h | WB -> x%0d = %0d (0x%08h)",
                         cycle_count, debug_pc_id, debug_inst_id, debug_wb_reg, debug_wb_data, debug_wb_data);
            end else begin
                $display("[Cycle %02d] PC_EX: 0x%08h | Inst: 0x%08h | (No WB)",
                         cycle_count, debug_pc_id, debug_inst_id);
            end
        end
    end

    initial begin
        // Waveform dump for GTKWave / Vivado xsim
        $dumpfile("nanoriscv_c2_top.vcd");
        $dumpvars(0, nanoriscv_c2_top_tb);

        clk = 0;
        rst = 1;

        $display("==================================================");
        $display("   NANORISC-V-C2 (2-STAGE RV32I) TOP TESTBENCH    ");
        $display("==================================================");
        $display("Starting reset sequence...");

        // Hold reset for 2 clock cycles
        #20;
        @(negedge clk);
        rst = 0;
        $display("Reset released. Executing program...\n");

        // Run processor for 16 clock cycles to complete the test program
        repeat (16) @(posedge clk);

        #10;
        $display("\n==================================================");
        $display("   PROGRAM EXECUTION COMPLETE: VERIFYING STATE    ");
        $display("==================================================");

        // Verification Check 1: Register x1 = 10 (from ADDI x1, x0, 10)
        if (uut.u_rf.rf[1] !== 32'd10) begin
            $display("[FAIL] x1 != 10 (Got: %0d)", uut.u_rf.rf[1]);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Register x1 = %0d (ADDI x1, x0, 10)", uut.u_rf.rf[1]);
        end

        // Verification Check 2: Register x2 = 20 (from ADDI x2, x0, 20)
        if (uut.u_rf.rf[2] !== 32'd20) begin
            $display("[FAIL] x2 != 20 (Got: %0d)", uut.u_rf.rf[2]);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Register x2 = %0d (ADDI x2, x0, 20)", uut.u_rf.rf[2]);
        end

        // Verification Check 3: Register x3 = 30 (from ADD x3, x1, x2)
        if (uut.u_rf.rf[3] !== 32'd30) begin
            $display("[FAIL] x3 != 30 (Got: %0d)", uut.u_rf.rf[3]);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Register x3 = %0d (ADD x3, x1, x2)", uut.u_rf.rf[3]);
        end

        // Verification Check 4: Register x4 = 20 (from SUB x4, x3, x1)
        if (uut.u_rf.rf[4] !== 32'd20) begin
            $display("[FAIL] x4 != 20 (Got: %0d)", uut.u_rf.rf[4]);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Register x4 = %0d (SUB x4, x3, x1)", uut.u_rf.rf[4]);
        end

        // Verification Check 5: Data Memory word at address 4 = 30 (from SW x3, 4(x0))
        if (uut.u_dmem.ram[1] !== 32'd30) begin
            $display("[FAIL] DMEM[4] != 30 (Got: %0d)", uut.u_dmem.ram[1]);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] DMEM[4] = %0d (SW x3, 4(x0))", uut.u_dmem.ram[1]);
        end

        // Verification Check 6: Register x5 = 30 (from LW x5, 4(x0))
        if (uut.u_rf.rf[5] !== 32'd30) begin
            $display("[FAIL] x5 != 30 (Got: %0d)", uut.u_rf.rf[5]);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Register x5 = %0d (LW x5, 4(x0))", uut.u_rf.rf[5]);
        end

        // Verification Check 7: Branch Flush Verification
        // Register x6 MUST be 0! The instruction at 0x1C was ADDI x6, x0, 99.
        // Because BEQ was taken, 0x1C must have been flushed (bubble).
        if (uut.u_rf.rf[6] !== 32'd0) begin
            $display("[FAIL] Pipeline Flush Failed! x6 was modified to %0d (Expected: 0)", uut.u_rf.rf[6]);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Register x6 = 0 (Confirmed speculative instruction FLUSHED)");
        end

        // Verification Check 8: Branch Target Execution
        // Register x7 MUST be 42! Branch jumped to 0x20 (ADDI x7, x0, 42).
        if (uut.u_rf.rf[7] !== 32'd42) begin
            $display("[FAIL] x7 != 42 (Got: %0d)", uut.u_rf.rf[7]);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Register x7 = %0d (Branch Target successfully executed)", uut.u_rf.rf[7]);
        end

        $display("==================================================");
        if (test_errors == 0) begin
            $display("   >>> ALL 8 CORE VERIFICATION CHECKS PASSED! <<< ");
            $display("   NANORISC-V-C2 2-STAGE RV32I IS FULLY FUNCTIONAL");
        end else begin
            $display("   CORE TEST FAILED WITH %0d ERROR(S)", test_errors);
        end
        $display("==================================================");

        #20;
        $finish;
    end

endmodule
