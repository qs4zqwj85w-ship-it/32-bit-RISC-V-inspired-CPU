#!/usr/bin/env bash
set -eo pipefail

# Build/flash only the adapter-level hardware test; the CPU build is untouched.
set +u
source "$HOME/tools/oss-cad-suite/environment"
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"

for f in sdram.v gowin_rpll.v sdram_adapter.sv sdram_adapter_test_top.sv sdram_test.cst; do
  if [[ ! -s "$f" ]]; then
    echo "ERROR: required file '$f' is missing or empty in $(pwd)" >&2
    exit 1
  fi
done

rm -f sdram_adapter_test.json sdram_adapter_test_pnr.json sdram_adapter_test.fs

echo "=== Synthesize SDRAM adapter tester ==="
yosys -p 'read_verilog gowin_rpll.v sdram.v; read_verilog -sv sdram_adapter.sv sdram_adapter_test_top.sv; synth_gowin -top sdram_adapter_test_top -json sdram_adapter_test.json' > synth_sdram_adapter_test.log 2>&1

echo "=== Place and route ==="
nextpnr-himbaechel \
  --json sdram_adapter_test.json \
  --write sdram_adapter_test_pnr.json \
  --device GW2AR-LV18QN88C8/I7 \
  --vopt family=GW2A-18C \
  --vopt cst=sdram_test.cst

echo "=== Pack bitstream ==="
gowin_pack -d GW2A-18C -o sdram_adapter_test.fs sdram_adapter_test_pnr.json

test -s sdram_adapter_test.fs
echo "=== Flash Tang Nano 20K ==="
openFPGALoader -b tangnano20k sdram_adapter_test.fs

echo "Build and programming complete."
