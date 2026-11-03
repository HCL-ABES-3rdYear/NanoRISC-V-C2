// ============================================================================
// File: data_memory.v
// Project: NanoRISC-V-C2 (2-Stage RV32I Core)
// Description: Data Memory unit supporting byte, halfword, and word accesses
//              with proper sign-extension and zero-extension for RV32I loads
//              (LB, LH, LW, LBU, LHU) and stores (SB, SH, SW).
// ============================================================================

`timescale 1ns / 1ps

module data_memory #(
    parameter MEM_DEPTH = 1024 // 1024 32-bit words (4KB)
)(
    input  wire        clk,        // Clock
    input  wire        rst,        // Synchronous active-high reset
    input  wire        mem_read,   // Read enable
    input  wire        mem_write,  // Write enable
    input  wire [2:0]  funct3,     // Memory access width and sign from instruction
    input  wire [31:0] addr,       // 32-bit memory byte address
    input  wire [31:0] write_data, // 32-bit write data (from rs2)
    output reg  [31:0] read_data   // 32-bit read data (to writeback mux)
);

    // RAM array
    reg [31:0] ram [0:MEM_DEPTH-1];

    wire [29:0] word_addr   = addr[31:2];
    wire [1:0]  byte_offset = addr[1:0];

    // Synchronous Write logic
    integer i;
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < MEM_DEPTH; i = i + 1) begin
                ram[i] <= 32'h0000_0000;
            end
        end else if (mem_write && (word_addr < MEM_DEPTH)) begin
            case (funct3)
                3'b000: begin // SB (Store Byte)
                    case (byte_offset)
                        2'b00: ram[word_addr][7:0]   <= write_data[7:0];
                        2'b01: ram[word_addr][15:8]  <= write_data[7:0];
                        2'b10: ram[word_addr][23:16] <= write_data[7:0];
                        2'b11: ram[word_addr][31:24] <= write_data[7:0];
                    endcase
                end

                3'b001: begin // SH (Store Halfword)
                    case (byte_offset[1])
                        1'b0: ram[word_addr][15:0]  <= write_data[15:0];
                        1'b1: ram[word_addr][31:16] <= write_data[15:0];
                    endcase
                end

                3'b010: begin // SW (Store Word)
                    ram[word_addr] <= write_data;
                end

                default: begin
                    ram[word_addr] <= write_data;
                end
            endcase
        end
    end

    // Combinational Read logic
    wire [31:0] raw_word = (word_addr < MEM_DEPTH) ? ram[word_addr] : 32'h0000_0000;

    always @(*) begin
        if (mem_read) begin
            case (funct3)
                3'b000: begin // LB (Load Byte, Signed)
                    case (byte_offset)
                        2'b00: read_data = {{24{raw_word[7]}},  raw_word[7:0]};
                        2'b01: read_data = {{24{raw_word[15]}}, raw_word[15:8]};
                        2'b10: read_data = {{24{raw_word[23]}}, raw_word[23:16]};
                        2'b11: read_data = {{24{raw_word[31]}}, raw_word[31:24]};
                    endcase
                end

                3'b001: begin // LH (Load Halfword, Signed)
                    case (byte_offset[1])
                        1'b0: read_data = {{16{raw_word[15]}}, raw_word[15:0]};
                        1'b1: read_data = {{16{raw_word[31]}}, raw_word[31:16]};
                    endcase
                end

                3'b010: begin // LW (Load Word)
                    read_data = raw_word;
                end

                3'b100: begin // LBU (Load Byte Unsigned)
                    case (byte_offset)
                        2'b00: read_data = {24'b0, raw_word[7:0]};
                        2'b01: read_data = {24'b0, raw_word[15:8]};
                        2'b10: read_data = {24'b0, raw_word[23:16]};
                        2'b11: read_data = {24'b0, raw_word[31:24]};
                    endcase
                end

                3'b101: begin // LHU (Load Halfword Unsigned)
                    case (byte_offset[1])
                        1'b0: read_data = {16'b0, raw_word[15:0]};
                        1'b1: read_data = {16'b0, raw_word[31:16]};
                    endcase
                end

                default: begin
                    read_data = raw_word;
                end
            endcase
        end else begin
            read_data = 32'h0000_0000;
        end
    end

endmodule
