// ============================================================================
// File: alu.v
// Project: NanoRISC-V-C2 (2-Stage RV32I Core)
// Description: Arithmetic Logic Unit (ALU) supporting all RV32I operations:
//              ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND, and PASS_B.
//              Provides 32-bit result and zero flag.
// ============================================================================

`timescale 1ns / 1ps

module alu (
    input  wire [31:0] a,        // Operand A (rs1 or PC)
    input  wire [31:0] b,        // Operand B (rs2 or Immediate)
    input  wire [3:0]  alu_ctrl, // ALU 4-bit control code
    output reg  [31:0] result,   // 32-bit ALU computation result
    output wire        zero      // Zero flag (1 if result == 0)
);

    // ALU Control Operations encoding
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

    always @(*) begin
        case (alu_ctrl)
            ALU_ADD:    result = a + b;
            ALU_SUB:    result = a - b;
            ALU_SLL:    result = a << b[4:0];
            ALU_SLT:    result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            ALU_SLTU:   result = (a < b) ? 32'd1 : 32'd0;
            ALU_XOR:    result = a ^ b;
            ALU_SRL:    result = a >> b[4:0];
            ALU_SRA:    result = $signed(a) >>> b[4:0];
            ALU_OR:     result = a | b;
            ALU_AND:    result = a & b;
            ALU_PASS_B: result = b;
            default:    result = 32'h0000_0000;
        endcase
    end

    // Zero flag output
    assign zero = (result == 32'h0000_0000);

endmodule
