// ============================================================================
// File: register_file.v
// Project: NanoRISC-V-C2 (2-Stage RV32I Core)
// Description: RV32I General-Purpose Register File (32 x 32-bit).
//              - 2 asynchronous read ports (rs1, rs2)
//              - 1 synchronous write port (rd)
//              - Register x0 is hardwired to 32'h00000000
//              - Includes internal write-through forwarding for same-cycle bypass
// ============================================================================

`timescale 1ns / 1ps

module register_file (
    input  wire        clk,          // Clock
    input  wire        rst,          // Synchronous active-high reset
    input  wire        reg_write_en, // Register write enable
    input  wire [4:0]  rs1_addr,     // Read register 1 address
    input  wire [4:0]  rs2_addr,     // Read register 2 address
    input  wire [4:0]  rd_addr,      // Destination register write address
    input  wire [31:0] rd_data,      // Data to write to rd
    output wire [31:0] rs1_data,     // Read data 1 output
    output wire [31:0] rs2_data      // Read data 2 output
);

    // 32 registers of 32-bit width
    reg [31:0] rf [0:31];
    integer i;

    // Synchronous write logic with reset
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1) begin
                rf[i] <= 32'h0000_0000;
            end
        end else begin
            // Register x0 is strictly read-only 0, writes to x0 are ignored
            if (reg_write_en && (rd_addr != 5'd0)) begin
                rf[rd_addr] <= rd_data;
            end
        end
    end

    // Asynchronous read logic with internal forwarding and x0 hardwired to 0
    assign rs1_data = (rs1_addr == 5'd0) ? 32'h0000_0000 :
                      ((reg_write_en && (rd_addr == rs1_addr)) ? rd_data : rf[rs1_addr]);

    assign rs2_data = (rs2_addr == 5'd0) ? 32'h0000_0000 :
                      ((reg_write_en && (rd_addr == rs2_addr)) ? rd_data : rf[rs2_addr]);

endmodule
