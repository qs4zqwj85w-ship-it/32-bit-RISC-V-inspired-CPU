#!/usr/bin/env bash
set -eo pipefail

# Build and flash only the standalone SDRAM tester. This script deliberately
# does not touch the CPU project's cpu.json/cpu.fs or invoke the CPU build.
# OSS CAD Suite environment activation expects nounset to be disabled.
set +u
source "$HOME/tools/oss-cad-suite/environment"
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"

for f in sdram.v gowin_rpll.v sdram_test_top.sv sdram_test.cst; do
  if [[ ! -s "$f" ]]; then
    echo "ERROR: required file '$f' is missing or empty in $(pwd)" >&2
    exit 1
  fi
done

rm -f sdram_test.json sdram_test_pnr.json sdram_test.fs

echo "=== Synthesize standalone SDRAM tester ==="
yosys -p 'read_verilog gowin_rpll.v sdram.v; read_verilog -sv sdram_test_top.sv; synth_gowin -top sdram_test_top -json sdram_test.json' > synth_sdram_test.log 2>&1

echo "=== Place and route ==="
nextpnr-himbaechel \
  --json sdram_test.json \
  --write sdram_test_pnr.json \
  --device GW2AR-LV18QN88C8/I7 \
  --vopt family=GW2A-18C \
  --vopt cst=sdram_test.cst

echo "=== Pack bitstream ==="
gowin_pack -d GW2A-18C -o sdram_test.fs sdram_test_pnr.json

test -s sdram_test.fs
echo "=== Flash Tang Nano 20K ==="
openFPGALoader -b tangnano20k sdram_test.fs

echo "Build and programming complete."
