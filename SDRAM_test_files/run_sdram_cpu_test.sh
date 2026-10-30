#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"
SRC="$ROOT/software/sdram_cpu_test.c"
OUT="$ROOT/.sdram-cpu-test-build"
ORIGINAL_HEX="$OUT/original_program.hex"
RESTORE_NEEDED=0

fail() { echo "ERROR: $*" >&2; exit 1; }
restore_program_image() {
    if [[ "$RESTORE_NEEDED" == "1" && -s "$ORIGINAL_HEX" ]]; then
        cp "$ORIGINAL_HEX" "$ROOT/program.hex"
        echo "Restored original program.hex."
    fi
}
trap restore_program_image EXIT

[[ -f "$SRC" ]] || fail "Missing $SRC"
[[ -f "$ROOT/build.sh" ]] || fail "Missing build.sh"
[[ -f "$ROOT/19_CPU/cpu_fpga_top.sv" ]] || fail "Missing CPU FPGA top"
[[ -f "$ROOT/cpu_fpga_top.cst" ]] || fail "Missing constraints"
[[ -s "$ROOT/program.hex" ]] || fail "Missing/empty original program.hex"

mkdir -p "$OUT"
cp "$ROOT/program.hex" "$ORIGINAL_HEX"
RESTORE_NEEDED=1

set +u
source "$HOME/tools/oss-cad-suite/environment"
set -u

for tool in riscv64-elf-gcc riscv64-elf-as riscv64-elf-objcopy riscv64-elf-objdump riscv64-elf-nm python3 yosys nextpnr-himbaechel gowin_pack; do
    command -v "$tool" >/dev/null 2>&1 || fail "Cannot find '$tool'; check your toolchain/PATH."
done

cat > "$OUT/start.S" <<'ASM'
.section .text.start,"ax",@progbits
.option nopic
.globl _start
.type _start,@function
_start:
    lui sp, 0x1
    la t0, __bss_start
    la t1, __bss_end
    bgeu t0, t1, .Lrun_main
.Lclear_bss:
    sw zero, 0(t0)
    addi t0, t0, 4
    bltu t0, t1, .Lclear_bss
.Lrun_main:
    jal ra, main
.Lhalt:
    jal zero, .Lhalt
ASM

cat > "$OUT/linker.ld" <<'LD'
OUTPUT_ARCH(riscv)
ENTRY(_start)
SECTIONS
{
    . = 0x00000000;
    .text :
    {
        . = ALIGN(4);
        KEEP(*(.text.start))
        *(.text*)
        *(.rodata*)
        *(.srodata*)
        *(.data*)
        *(.sdata*)
        . = ALIGN(4);
    }
    .bss (NOLOAD) :
    {
        . = ALIGN(4);
        __bss_start = .;
        *(.bss*)
        *(.sbss*)
        *(COMMON)
        . = ALIGN(4);
        __bss_end = .;
    }
    __image_end = .;
}
LD

echo "=== Compile SDRAM test firmware ==="
riscv64-elf-gcc \
    -march=rv32i_zicsr -mabi=ilp32 \
    -O0 -ffreestanding -fno-builtin \
    -fno-pic -fno-pie -msmall-data-limit=0 \
    -fno-asynchronous-unwind-tables -fno-unwind-tables \
    -S "$SRC" -o "$OUT/sdram_cpu_test.s"
riscv64-elf-as -march=rv32i_zicsr -mabi=ilp32 -o "$OUT/start.o" "$OUT/start.S"
riscv64-elf-as -march=rv32i_zicsr -mabi=ilp32 -o "$OUT/sdram_cpu_test.o" "$OUT/sdram_cpu_test.s"
riscv64-elf-gcc \
    -march=rv32i_zicsr -mabi=ilp32 \
    -nostdlib -nostartfiles -fno-pic -fno-pie \
    -Wl,-T,"$OUT/linker.ld" -Wl,--no-relax \
    -o "$OUT/sdram_cpu_test.elf" "$OUT/start.o" "$OUT/sdram_cpu_test.o"
riscv64-elf-objdump -d "$OUT/sdram_cpu_test.elf" > "$OUT/sdram_cpu_test.dis"
riscv64-elf-objcopy -O binary --only-section=.text "$OUT/sdram_cpu_test.elf" "$OUT/sdram_cpu_test.bin"

IMAGE_END="$(riscv64-elf-nm -n "$OUT/sdram_cpu_test.elf" | awk '$3 == "__image_end" { print $1; exit }')"
[[ -n "$IMAGE_END" ]] || fail "Could not determine linked image size"

python3 - "$OUT/sdram_cpu_test.bin" "$ROOT/program.hex" "$IMAGE_END" <<'PY'
from pathlib import Path
import sys
binary_path = Path(sys.argv[1])
hex_path = Path(sys.argv[2])
image_end = int(sys.argv[3], 16)
if image_end > 0xF00:
    raise SystemExit(f"ERROR: image ends at 0x{image_end:X}; must be <= 0xF00 to reserve BRAM stack space.")
data = binary_path.read_bytes()
data += b"\x00" * ((-len(data)) % 4)
words = [f"{int.from_bytes(data[i:i+4], 'little'):08x}" for i in range(0, len(data), 4)]
if len(words) > 1024:
    raise SystemExit(f"ERROR: image has {len(words)} words; BRAM holds 1024.")
hex_path.write_text("\n".join(words) + "\n")
print(f"Wrote {len(words)} test words to program.hex (image end 0x{image_end:X}).")
PY

echo "=== Build test bitstream only (no USB/JTAG access) ==="
SKIP_FLASH=1 bash "$ROOT/build.sh"
cp "$ORIGINAL_HEX" "$ROOT/program.hex"
RESTORE_NEEDED=0

echo
echo "READY: cpu.fs now contains the SDRAM test firmware."
echo "The original program.hex has been restored. Nothing was flashed."
echo "Next, with all serial monitors CLOSED, run: ./flash_sdram_cpu_test.sh"
