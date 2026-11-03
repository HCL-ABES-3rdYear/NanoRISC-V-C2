// ============================================================================
// File: pipeline_reg_if_id.v
// Project: NanoRISC-V-C2 (2-Stage RV32I Core)
// Description: Pipeline Register separating Stage 1 (Instruction Fetch) and
//              Stage 2 (Decode/Execute/Memory/Writeback). Supports synchronous
//              flush (bubbles for branch misprediction/jumps) and stall.
// ============================================================================

`timescale 1ns / 1ps

module pipeline_reg_if_id (
    input  wire        clk,          // Clock signal
    input  wire        rst,          // Synchronous active-high reset
    input  wire        flush,        // Pipeline flush signal (branch/jump taken)
    input  wire        stall,        // Pipeline stall signal
    input  wire [31:0] pc_if,        // PC from Fetch stage
    input  wire [31:0] inst_if,      // Fetched instruction from IMEM
    output reg  [31:0] pc_id,        // Latched PC in Execute stage
    output reg  [31:0] inst_id       // Latched Instruction in Execute stage
);

    // RV32I NOP: addi x0, x0, 0
    localparam NOP = 32'h0000_0013;

    always @(posedge clk) begin
        if (rst || flush) begin
            pc_id   <= 32'h0000_0000;
            inst_id <= NOP;
        end else if (!stall) begin
            pc_id   <= pc_if;
            inst_id <= inst_if;
        end
        // If stall is high, maintain current stage registers
    end

endmodule
