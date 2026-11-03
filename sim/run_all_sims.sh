#!/usr/bin/env bash
set -e

echo "=============================================================="
echo "      NanoRISC-V-C2 Complete Simulation Suite (Icarus Verilog)"
echo "=============================================================="

cd ..

echo "[1/8] Simulating Program Counter..."
iverilog -g2001 -o sim_pc.vvp rtl/program_counter.v tb/program_counter_tb.v
vvp sim_pc.vvp
rm -f sim_pc.vvp

echo "[2/8] Simulating Instruction Memory..."
iverilog -g2001 -o sim_imem.vvp rtl/instruction_memory.v tb/instruction_memory_tb.v
vvp sim_imem.vvp
rm -f sim_imem.vvp

echo "[3/8] Simulating Pipeline Register IF/ID..."
iverilog -g2001 -o sim_preg.vvp rtl/pipeline_reg_if_id.v tb/pipeline_reg_if_id_tb.v
vvp sim_preg.vvp
rm -f sim_preg.vvp

echo "[4/8] Simulating Register File..."
iverilog -g2001 -o sim_rf.vvp rtl/register_file.v tb/register_file_tb.v
vvp sim_rf.vvp
rm -f sim_rf.vvp

echo "[5/8] Simulating ALU..."
iverilog -g2001 -o sim_alu.vvp rtl/alu.v tb/alu_tb.v
vvp sim_alu.vvp
rm -f sim_alu.vvp

echo "[6/8] Simulating Control Unit & ImmGen..."
iverilog -g2001 -o sim_cu.vvp rtl/control_unit.v tb/control_unit_tb.v
vvp sim_cu.vvp
rm -f sim_cu.vvp

echo "[7/8] Simulating Data Memory..."
iverilog -g2001 -o sim_dmem.vvp rtl/data_memory.v tb/data_memory_tb.v
vvp sim_dmem.vvp
rm -f sim_dmem.vvp

echo "[8/8] Simulating Top-Level Integration (nanoriscv_c2_top)...
iverilog -g2001 -o sim_top.vvp rtl/*.v tb/nanoriscv_c2_top_tb.v
vvp sim_top.vvp
rm -f sim_top.vvp

echo "=============================================================="
echo "      ALL 8 UNIT & TOP-LEVEL SIMULATIONS PASSED (100%)!"
echo "=============================================================="
