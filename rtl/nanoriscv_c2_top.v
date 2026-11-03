// ============================================================================
// File: nanoriscv_c2_top.v
// Project: NanoRISC-V-C2 (2-Stage RV32I Core)
// Description: Top-Level Wrapper integrating all RV32I microarchitectural blocks:
//              - Stage 1 (Fetch): PC, Instruction Memory (IMEM)
//              - Pipeline Register: IF/ID (Synchronous Flush & Latch)
//              - Stage 2 (Decode/Execute/Memory/Writeback):
//                Register File, Control Unit, ALU, Data Memory (DMEM), Writeback
// ============================================================================

`timescale 1ns / 1ps

module nanoriscv_c2_top #(
    parameter IMEM_DEPTH = 1024, // Instruction Memory Depth (4KB)
    parameter DMEM_DEPTH = 1024, // Data Memory Depth (4KB)
    parameter HEX_FILE   = ""    // Optional preloaded code hex file
)(
    input  wire        clk,              // Main processor clock
    input  wire        rst,              // Synchronous active-high reset

    // Monitoring and Verification Debug Ports (Observable in Vivado Sim/ILAs)
    output wire [31:0] debug_pc_if,      // Current Fetch PC
    output wire [31:0] debug_pc_id,      // Current Execute PC
    output wire [31:0] debug_inst_id,    // Current Instruction executing
    output wire [31:0] debug_alu_result, // ALU computation output
    output wire [31:0] debug_wb_data,    // Register writeback data
    output wire [4:0]  debug_wb_reg,     // Destination register address
    output wire        debug_reg_write   // Register write enable
);

    // ========================================================================
    // Internal Interconnect Signals
    // ========================================================================

    // Stage 1 (Fetch) Signals
    wire [31:0] pc_if;
    wire [31:0] pc_next;
    wire [31:0] pc_plus_4 = pc_if + 32'd4;
    wire [31:0] inst_if;
    wire [31:0] branch_jump_target;
    wire        pc_src;
    wire        stall = 1'b0; // Core stall line (can be used for multi-cycle bus)

    // Pipeline Register (IF -> ID/EX) Signals
    wire [31:0] pc_id;
    wire [31:0] inst_id;
    wire        flush = pc_src; // Flush speculative instruction on branch/jump

    // Stage 2 (Decode / Execute / Memory / Writeback) Signals
    wire [4:0]  rs1_addr = inst_id[19:15];
    wire [4:0]  rs2_addr = inst_id[24:20];
    wire [4:0]  rd_addr  = inst_id[11:7];

    wire [31:0] rs1_data;
    wire [31:0] rs2_data;
    wire [31:0] rd_data;

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

    wire [31:0] alu_in_a;
    wire [31:0] alu_in_b;
    wire [31:0] alu_result;
    wire        alu_zero;

    wire [31:0] mem_read_data;

    // ========================================================================
    // STAGE 1: INSTRUCTION FETCH (IF)
    // ========================================================================

    // Next PC selection logic:
    // If branch taken or jump (JAL/JALR), redirect to calculated target;
    // Otherwise, increment PC sequentially by 4 bytes.
    assign branch_jump_target = (jump_jalr) ? ((rs1_data + imm) & ~32'h0000_0001) :
                                              (pc_id + imm);

    assign pc_src = branch_taken | jump_jal | jump_jalr;
    assign pc_next = (pc_src) ? branch_jump_target : pc_plus_4;

    // Program Counter Instance
    program_counter u_pc (
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .pc_next(pc_next),
        .pc(pc_if)
    );

    // Instruction Memory Instance
    instruction_memory #(
        .MEM_DEPTH(IMEM_DEPTH),
        .HEX_FILE(HEX_FILE)
    ) u_imem (
        .addr(pc_if),
        .instruction(inst_if)
    );

    // ========================================================================
    // PIPELINE REGISTER: STAGE 1 (IF) -> STAGE 2 (ID/EX/MEM/WB)
    // ========================================================================

    pipeline_reg_if_id u_pipe_reg (
        .clk(clk),
        .rst(rst),
        .flush(flush),
        .stall(stall),
        .pc_if(pc_if),
        .inst_if(inst_if),
        .pc_id(pc_id),
        .inst_id(inst_id)
    );

    // ========================================================================
    // STAGE 2: DECODE, EXECUTE, MEMORY ACCESS, AND WRITEBACK
    // ========================================================================

    // Register File Instance
    register_file u_rf (
        .clk(clk),
        .rst(rst),
        .reg_write_en(reg_write),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rd_addr(rd_addr),
        .rd_data(rd_data),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    // Control Unit & Immediate Generator Instance
    control_unit u_ctrl (
        .inst(inst_id),
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

    // ALU Operand Multiplexers
    assign alu_in_a = (alu_op_pc) ? pc_id : rs1_data;
    assign alu_in_b = (alu_src)   ? imm   : rs2_data;

    // Arithmetic Logic Unit Instance
    alu u_alu (
        .a(alu_in_a),
        .b(alu_in_b),
        .alu_ctrl(alu_ctrl),
        .result(alu_result),
        .zero(alu_zero)
    );

    // Data Memory Instance
    data_memory #(
        .MEM_DEPTH(DMEM_DEPTH)
    ) u_dmem (
        .clk(clk),
        .rst(rst),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .funct3(mem_funct3),
        .addr(alu_result),
        .write_data(rs2_data),
        .read_data(mem_read_data)
    );

    // Writeback Data Multiplexer
    reg [31:0] wb_data_mux;
    always @(*) begin
        case (mem_to_reg)
            2'b00:   wb_data_mux = alu_result;             // ALU result
            2'b01:   wb_data_mux = mem_read_data;          // Data from DMEM
            2'b10:   wb_data_mux = pc_id + 32'd4;          // JAL/JALR link address
            2'b11:   wb_data_mux = imm;                    // LUI immediate
            default: wb_data_mux = alu_result;
        endcase
    end
    assign rd_data = wb_data_mux;

    // ========================================================================
    // Debug Outputs Assignment
    // ========================================================================
    assign debug_pc_if      = pc_if;
    assign debug_pc_id      = pc_id;
    assign debug_inst_id    = inst_id;
    assign debug_alu_result = alu_result;
    assign debug_wb_data    = rd_data;
    assign debug_wb_reg     = rd_addr;
    assign debug_reg_write  = reg_write;

endmodule
