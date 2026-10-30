#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

# Load OSS CAD Suite so FPGA tools are available in this script.
   set +u
   source "$HOME/tools/oss-cad-suite/environment"
   set -u

SRC="$ROOT/software/sdram_life_optimized_nopoll.c"
OUT="$ROOT/.c-build"

die() {
    echo "ERROR: $*" >&2
    exit 1
}

[[ -f "$SRC" ]] || die "Missing software/main.c"
[[ -f "$ROOT/build.sh" ]] || die "Missing build.sh"

# Check required tools before starting.
for tool in \
    riscv64-elf-gcc \
    riscv64-elf-as \
    riscv64-elf-objcopy \
    riscv64-elf-objdump \
    riscv64-elf-nm \
    python3 \
    yosys \
    nextpnr-himbaechel \
    gowin_pack \
    openFPGALoader
do
    command -v "$tool" >/dev/null 2>&1 ||
        die "Cannot find '$tool'. Check your toolchain/PATH."
done

mkdir -p "$OUT"

echo
echo "=== 1/4: Generate startup code and linker script ==="

cat > "$OUT/start.S" <<'ASM'
.section .text.start,"ax",@progbits
.option nopic
.globl _start
.type _start,@function

_start:
    # Initialize stack at the top of the 4 KiB RAM.
    lui sp, 0x1

    # Initialize zero-initialized C globals (.bss).
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

    /* Keep code and initialized data in the same physical RAM image. */
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

    /* Zero-initialized globals occupy RAM but not the HEX file. */
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

echo
echo "=== 2/4: Compile C, assemble, and link for RV32I ==="

riscv64-elf-gcc \
    -march=rv32i_zicsr -mabi=ilp32 \
    -O0 -ffreestanding -fno-builtin \
    -fno-pic -fno-pie -msmall-data-limit=0 \
    -fno-asynchronous-unwind-tables -fno-unwind-tables \
    -S "$SRC" -o "$OUT/main.s"

riscv64-elf-as \
    -march=rv32i_zicsr -mabi=ilp32 \
    -o "$OUT/start.o" "$OUT/start.S"

riscv64-elf-as \
    -march=rv32i_zicsr -mabi=ilp32 \
    -o "$OUT/main.o" "$OUT/main.s"

riscv64-elf-gcc \
    -march=rv32i_zicsr -mabi=ilp32 \
    -nostdlib -nostartfiles \
    -fno-pic -fno-pie \
    -Wl,-T,"$OUT/linker.ld" \
    -Wl,--no-relax \
    -o "$OUT/main.elf" \
    "$OUT/start.o" "$OUT/main.o"

riscv64-elf-objdump -d "$OUT/main.elf" > "$OUT/main.dis"
echo "Executable: $OUT/main.elf"
echo "Disassembly: $OUT/main.dis"

echo
echo "=== 3/4: Generate FPGA instruction-memory image ==="

riscv64-elf-objcopy \
    -O binary --only-section=.text \
    "$OUT/main.elf" "$OUT/main.bin"

IMAGE_END="$(
    riscv64-elf-nm -n "$OUT/main.elf" |
    awk '$3 == "__image_end" { print $1; exit }'
)"

[[ -n "$IMAGE_END" ]] || die "Could not determine program memory size"

python3 - "$OUT/main.bin" "$ROOT/program.hex" "$IMAGE_END" <<'PY'
from pathlib import Path
import sys

binary_path = Path(sys.argv[1])
hex_path = Path(sys.argv[2])
image_end = int(sys.argv[3], 16)

# Reserve the top 256 bytes of the 4 KiB RAM for the stack.
if image_end > 0xF00:
    raise SystemExit(
        f"ERROR: program/data end at 0x{image_end:X}; "
        "must stay at or below 0xF00 to reserve stack space."
    )

data = binary_path.read_bytes()
data += b"\x00" * ((-len(data)) % 4)

if len(data) > 4096:
    raise SystemExit("ERROR: program image exceeds the 4 KiB RAM.")

words = [
    f"{int.from_bytes(data[i:i+4], 'little'):08x}"
    for i in range(0, len(data), 4)
]

if len(words) > 1024:
    raise SystemExit("ERROR: program exceeds 1024 memory words.")

hex_path.write_text("\n".join(words) + "\n")
print(f"Wrote {len(words)} 32-bit words to {hex_path.name}")
PY

echo
echo "=== 4/4: Build FPGA bitstream and flash board ==="

# Close old serial monitors BEFORE openFPGALoader claims the USB device.
killall screen 2>/dev/null || true
sleep 1

bash "$ROOT/build.sh"

[[ -s "$ROOT/cpu.fs" ]] ||
    die "FPGA bitstream cpu.fs was not generated."




echo "SUCCESS: C program built and board flashed."

# Open the serial monitor on the board's UART port.
PORT="${UART_PORT:-}"
if [[ -z "$PORT" ]]; then
    sleep 2   # let the USB-serial ports re-appear after flashing
    PORT="$(ls /dev/cu.usbserial-* 2>/dev/null | tail -n 1 || true)"
fi
[[ -n "$PORT" ]] || die "No /dev/cu.usbserial-* port found."

echo "Opening $PORT at 115200 (exit: Ctrl-A, then K, then Y)"
exec screen "$PORT" 115200