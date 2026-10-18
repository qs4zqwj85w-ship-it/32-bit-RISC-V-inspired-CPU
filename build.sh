#!/usr/bin/env bash
set -euo pipefail

source "$HOME/tools/oss-cad-suite/environment"

rm -f cpu.json pnr.json cpu.fs

# Explicit RTL allowlist. printf makes this one flat string
# for the Yosys command parser.

FILES="$(printf '%s ' \
  './01_Register_File/register_file.sv' \
  './20_UART/uart_tx.sv' \
  './19_CPU/CPU.sv' \
  './19_CPU/cpu_fpga_top.sv' \
  './06_memory/memory_subword.sv' \
  './12_muxes_32/mux4_32.sv' \
  './12_muxes_32/mux2_32.sv' \
  './02_alu/alu.sv' \
  './09_ALU_out_reg/alu_out_reg.sv' \
  './16_memory_address_mux/memory_address_mux.sv' \
  './15_next_pc_mux/next_pc_mux.sv' \
  './03_imm_gen/imm_gen.sv' \
  './08_MDR/mdr.sv' \
  './17_memory_writeback_mux/memory_writeback_mux.sv' \
  './14_alu_input_muxes/alu_input_muxes.sv' \
  './05_PC/pc.sv' \
  './04_decoder/decoder.sv' \
  './11_op_AB_reg/op_AB_reg.sv' \
  './07_instruction_register/instruction_reg.sv' \
  './18_control_fsm/control_fsm.sv' \
  './10_MAR/mar.sv' \
  './13_branch_control/branch_control.sv'
)"


echo "=== Synthesis ==="
yosys -p "read_verilog -sv $FILES; synth_gowin -top cpu_fpga_top -json cpu.json" > synth.log 2>&1

echo "=== Place and route ==="
nextpnr-himbaechel \
  --json cpu.json \
  --write pnr.json \
  --device GW2AR-LV18QN88C8/I7 \
  --vopt family=GW2A-18C \
  --vopt cst=cpu_fpga_top.cst

echo "=== Pack bitstream ==="
gowin_pack -d GW2A-18C -o cpu.fs pnr.json

test -s cpu.fs

echo "=== Flash Tang Nano 20K ==="
openFPGALoader -b tangnano20k cpu.fs

echo "Build and programming complete."