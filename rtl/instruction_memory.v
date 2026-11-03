// ============================================================================
// File: instruction_memory.v
// Project: NanoRISC-V-C2 (2-Stage RV32I Core)
// Description: Instruction Memory (ROM/RAM) for Stage 1 (Fetch).
//              Byte-addressable word-aligned combinational read memory.
//              Supports preloading via an optional hex file or built-in program.
// ============================================================================

`timescale 1ns / 1ps

module instruction_memory #(
    parameter MEM_DEPTH = 1024,                  // Depth in 32-bit words (4KB)
    parameter HEX_FILE  = ""                      // Optional hex file path
)(
    input  wire [31:0] addr,                     // 32-bit Byte Address from PC
    output wire [31:0] instruction               // 32-bit Fetched Instruction
);

    // Memory array: MEM_DEPTH 32-bit words
    reg [31:0] mem [0:MEM_DEPTH-1];

    // Word address calculation (PC is 4-byte aligned in RV32I)
    wire [29:0] word_addr = addr[31:2];

    // Combinational read: returns NOP (addi x0, x0, 0 = 32'h00000013) if out of bounds
    assign instruction = (word_addr < MEM_DEPTH) ? mem[word_addr] : 32'h0000_0013;

    integer i;
    initial begin
        // Initialize memory with default NOPs
        for (i = 0; i < MEM_DEPTH; i = i + 1) begin
            mem[i] = 32'h0000_0013; // addi x0, x0, 0
        end

        // Load external hex file if provided
        if (HEX_FILE != "") begin
            $readmemh(HEX_FILE, mem);
        end else begin
            // Default built-in verification program:
            // 0x00: ADDI x1, x0, 10       -> x1 = 10
            // 0x04: ADDI x2, x0, 20       -> x2 = 20
            // 0x08: ADD  x3, x1, x2       -> x3 = 30
            // 0x0C: SUB  x4, x3, x1       -> x4 = 20
            // 0x10: SW   x3, 4(x0)        -> mem[4] = 30
            // 0x14: LW   x5, 4(x0)        -> x5 = 30
            // 0x18: BEQ  x4, x2, 8        -> Branch to 0x20 (taken)
            // 0x1C: ADDI x6, x0, 99       -> (Branch delay slot/speculative - should be flushed)
            // 0x20: ADDI x7, x0, 42       -> x7 = 42
            // 0x24: JAL  x0, 0            -> Infinite loop (halt)
            mem[0] = 32'h00a00093; // addi x1, x0, 10
            mem[1] = 32'h01400113; // addi x2, x0, 20
            mem[2] = 32'h002081b3; // add  x3, x1, x2
            mem[3] = 32'h40118233; // sub  x4, x3, x1
            mem[4] = 32'h00302223; // sw   x3, 4(x0)
            mem[5] = 32'h00402283; // lw   x5, 4(x0)
            mem[6] = 32'h00220463; // beq  x4, x2, +8 (to index 8 = 0x20)
            mem[7] = 32'h06300313; // addi x6, x0, 99
            mem[8] = 32'h02a00393; // addi x7, x0, 42
            mem[9] = 32'h0000006f; // jal  x0, 0
        end
    end

endmodule
