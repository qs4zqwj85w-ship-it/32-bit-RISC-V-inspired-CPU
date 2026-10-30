#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITSTREAM="$ROOT/.sdram-cpu-diag/cpu_sdram_diag.fs"
[[ -s "$BITSTREAM" ]] || { echo "ERROR: diagnostic bitstream not found. Run ./build_sdram_cpu_diag.sh first." >&2; exit 1; }
command -v openFPGALoader >/dev/null 2>&1 || { echo "ERROR: openFPGALoader not found in PATH." >&2; exit 1; }
echo "Close screen/serial monitor before flashing; USB serial may share the FTDI device."
echo "Flashing diagnostic bitstream..."
openFPGALoader -b tangnano20k "$BITSTREAM"
echo "Flash finished. Now open the serial monitor:"
echo "  screen /dev/cu.usbserial-20250303170 115200"
echo "Leave it running for at least 60 seconds to observe the CPU-test heartbeat and SDRAM transaction."
