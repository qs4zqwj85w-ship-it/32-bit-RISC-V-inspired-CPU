#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"
[[ -s "$ROOT/cpu.fs" ]] || { echo "ERROR: cpu.fs not found. Run ./run_sdram_cpu_test.sh first." >&2; exit 1; }
command -v openFPGALoader >/dev/null 2>&1 || { echo "ERROR: openFPGALoader not found in PATH." >&2; exit 1; }
echo "Flashing the already-built SDRAM test bitstream. Do not have screen or another serial monitor open."
openFPGALoader -b tangnano20k "$ROOT/cpu.fs"
echo "Flash complete. Now open the serial monitor separately, for example:"
echo "  screen /dev/cu.usbserial-20250303170 115200"
