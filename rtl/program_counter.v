// ============================================================================
// File: program_counter.v
// Project: NanoRISC-V-C2 (2-Stage RV32I Core)
// Description: Program Counter (PC) module. Maintains the 32-bit instruction
//              fetch address. Supports synchronous active-high reset, stall,
//              and PC loading for sequential execution, branches, and jumps.
// ============================================================================

`timescale 1ns / 1ps

module program_counter (
    input  wire        clk,      // Clock signal
    input  wire        rst,      // Synchronous active-high reset
    input  wire        stall,    // Stall signal (holds current PC)
    input  wire [31:0] pc_next,  // Next PC value to be latched
    output reg  [31:0] pc        // Current Program Counter output
);

    // Initial PC reset address: 32'h0000_0000 (standard RV32 base)
    always @(posedge clk) begin
        if (rst) begin
            pc <= 32'h0000_0000;
        end else if (!stall) begin
            pc <= pc_next;
        end
        // If stall is high, pc retains its current value
    end

endmodule
