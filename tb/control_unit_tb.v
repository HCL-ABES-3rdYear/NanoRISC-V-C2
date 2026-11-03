// ============================================================================
// File: control_unit_tb.v
// Project: NanoRISC-V-C2 (2-Stage RV32I Core)
// Description: Dedicated testbench for the Control Unit.
//              Verifies decoding across R, I, S, B, U, J format instructions,
//              immediate decoding, and branch condition logic.
// ============================================================================

`timescale 1ns / 1ps

module control_unit_tb;

    reg  [31:0] inst;
    reg  [31:0] rs1_data;
    reg  [31:0] rs2_data;
    wire        reg_write;
    wire        alu_src;
    wire        alu_op_pc;
    wire        mem_read;
    wire        mem_write;
    wire [1:0]  mem_to_reg;
    wire [3:0]  alu_ctrl;
    wire        branch_taken;
    wire        jump_jal;
    wire        jump_jalr;
    wire [31:0] imm;
    wire [2:0]  mem_funct3;

    integer test_errors = 0;

    control_unit uut (
        .inst(inst),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .reg_write(reg_write),
        .alu_src(alu_src),
        .alu_op_pc(alu_op_pc),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_to_reg(mem_to_reg),
        .alu_ctrl(alu_ctrl),
        .branch_taken(branch_taken),
        .jump_jal(jump_jal),
        .jump_jalr(jump_jalr),
        .imm(imm),
        .mem_funct3(mem_funct3)
    );

    initial begin
        $dumpfile("control_unit.vcd");
        $dumpvars(0, control_unit_tb);

        inst     = 32'h0000_0013; // NOP (addi x0, x0, 0)
        rs1_data = 32'h0;
        rs2_data = 32'h0;

        $display("--------------------------------------------------");
        $display("   TESTBENCH: control_unit_tb                     ");
        $display("--------------------------------------------------");

        // Test 1: ADDI x1, x0, 10 -> 0x00a00093
        inst = 32'h00a00093;
        #10;
        if (reg_write !== 1'b1 || alu_src !== 1'b1 || imm !== 32'd10 || alu_ctrl !== 4'b0000) begin
            $display("[FAIL] Test 1: ADDI decode failed. reg_w: %b, alu_src: %b, imm: %d", reg_write, alu_src, imm);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Test 1: ADDI decoded correctly (imm = %0d)", imm);
        end

        // Test 2: ADD x3, x1, x2 -> 0x002081b3
        inst = 32'h002081b3;
        #10;
        if (reg_write !== 1'b1 || alu_src !== 1'b0 || alu_ctrl !== 4'b0000 || mem_to_reg !== 2'b00) begin
            $display("[FAIL] Test 2: ADD decode failed.");
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Test 2: ADD decoded correctly (R-type ALU)");
        end

        // Test 3: SUB x4, x3, x1 -> 0x40118233
        inst = 32'h40118233;
        #10;
        if (reg_write !== 1'b1 || alu_src !== 1'b0 || alu_ctrl !== 4'b0001) begin
            $display("[FAIL] Test 3: SUB decode failed. alu_ctrl: %b", alu_ctrl);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Test 3: SUB decoded correctly");
        end

        // Test 4: LW x5, 8(x2) -> 0x00812283
        inst = 32'h00812283;
        #10;
        if (reg_write !== 1'b1 || mem_read !== 1'b1 || mem_to_reg !== 2'b01 || imm !== 32'd8) begin
            $display("[FAIL] Test 4: LW decode failed. mem_read: %b, mem_to_reg: %b", mem_read, mem_to_reg);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Test 4: LW decoded correctly");
        end

        // Test 5: SW x5, 12(x2) -> 0x00512623 (imm = 12)
        inst = 32'h00512623;
        #10;
        if (reg_write !== 1'b0 || mem_write !== 1'b1 || imm !== 32'd12) begin
            $display("[FAIL] Test 5: SW decode failed. mem_write: %b, imm: %d", mem_write, imm);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Test 5: SW decoded correctly (imm = %0d)", imm);
        end

        // Test 6: BEQ x1, x2 (Equal -> Branch Taken)
        inst     = 32'h00208863; // beq x1, x2, offset
        rs1_data = 32'd25;
        rs2_data = 32'd25;
        #10;
        if (branch_taken !== 1'b1) begin
            $display("[FAIL] Test 6: BEQ taken check failed.");
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Test 6: BEQ satisfied condition (branch_taken = 1)");
        end

        // Test 7: BEQ x1, x2 (Not Equal -> Branch Not Taken)
        rs2_data = 32'd50;
        #10;
        if (branch_taken !== 1'b0) begin
            $display("[FAIL] Test 7: BEQ not-taken check failed.");
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Test 7: BEQ not satisfied condition (branch_taken = 0)");
        end

        // Test 8: LUI x10, 0x12345 -> 0x12345537
        inst = 32'h12345537;
        #10;
        if (reg_write !== 1'b1 || mem_to_reg !== 2'b11 || imm !== 32'h12345000) begin
            $display("[FAIL] Test 8: LUI decode failed. imm: 0x%08h", imm);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Test 8: LUI decoded correctly (imm = 0x%08h)", imm);
        end

        // Test 9: JAL x1, offset -> 0x010000ef
        inst = 32'h010000ef;
        #10;
        if (reg_write !== 1'b1 || jump_jal !== 1'b1 || mem_to_reg !== 2'b10) begin
            $display("[FAIL] Test 9: JAL decode failed.");
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Test 9: JAL decoded correctly (jump_jal = 1)");
        end

        // Test Summary
        $display("--------------------------------------------------");
        if (test_errors == 0) begin
            $display("   ALL CONTROL UNIT TESTS PASSED!                 ");
        end else begin
            $display("   TESTS COMPLETED WITH %0d ERROR(S)              ", test_errors);
        end
        $display("--------------------------------------------------");

        #10;
        $finish;
    end

endmodule
