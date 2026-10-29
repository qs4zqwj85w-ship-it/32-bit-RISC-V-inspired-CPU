#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"
OUT="$ROOT/.sdram-cpu-diag"
SRC="$ROOT/software/sdram_cpu_test.c"
ORIGINAL_HEX="$OUT/original_program.hex"
RESTORE_NEEDED=0

fail() { echo "ERROR: $*" >&2; exit 1; }
restore_program_hex() {
  if [[ "$RESTORE_NEEDED" == "1" && -s "$ORIGINAL_HEX" ]]; then
    cp "$ORIGINAL_HEX" "$ROOT/program.hex"
    echo "Restored original program.hex."
  fi
}
trap restore_program_hex EXIT

for f in "$SRC" "$ROOT/19_CPU/CPU.sv" "$ROOT/19_CPU/cpu_fpga_top.sv" "$ROOT/18_control_fsm/control_fsm.sv" "$ROOT/cpu_fpga_top.cst" "$ROOT/build.sh"; do
  [[ -s "$f" ]] || fail "Required file missing or empty: $f"
done
mkdir -p "$OUT"
cp "$ROOT/program.hex" "$ORIGINAL_HEX"
RESTORE_NEEDED=1

set +u
source "$HOME/tools/oss-cad-suite/environment"
set -u

for tool in riscv64-elf-gcc riscv64-elf-as riscv64-elf-objcopy riscv64-elf-objdump riscv64-elf-nm python3 yosys nextpnr-himbaechel gowin_pack openFPGALoader; do
  command -v "$tool" >/dev/null 2>&1 || fail "Cannot find '$tool'; check OSS CAD Suite/toolchain PATH."
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

echo "=== Compile CPU SDRAM test firmware ==="
riscv64-elf-gcc \
  -march=rv32i_zicsr -mabi=ilp32 -O0 -ffreestanding -fno-builtin \
  -fno-pic -fno-pie -msmall-data-limit=0 \
  -fno-asynchronous-unwind-tables -fno-unwind-tables \
  -S "$SRC" -o "$OUT/sdram_cpu_test.s"
riscv64-elf-as -march=rv32i_zicsr -mabi=ilp32 -o "$OUT/start.o" "$OUT/start.S"
riscv64-elf-as -march=rv32i_zicsr -mabi=ilp32 -o "$OUT/sdram_cpu_test.o" "$OUT/sdram_cpu_test.s"
riscv64-elf-gcc -march=rv32i_zicsr -mabi=ilp32 -nostdlib -nostartfiles -fno-pic -fno-pie \
  -Wl,-T,"$OUT/linker.ld" -Wl,--no-relax \
  -o "$OUT/sdram_cpu_test.elf" "$OUT/start.o" "$OUT/sdram_cpu_test.o"
riscv64-elf-objdump -d "$OUT/sdram_cpu_test.elf" > "$OUT/sdram_cpu_test.dis"
riscv64-elf-objcopy -O binary --only-section=.text "$OUT/sdram_cpu_test.elf" "$OUT/sdram_cpu_test.bin"
IMAGE_END="$(riscv64-elf-nm -n "$OUT/sdram_cpu_test.elf" | awk '$3 == "__image_end" { print $1; exit }')"
[[ -n "$IMAGE_END" ]] || fail "Could not determine test image end."

python3 - "$OUT/sdram_cpu_test.bin" "$ROOT/program.hex" "$IMAGE_END" <<'PY'
from pathlib import Path
import sys
binary_path, hex_path = Path(sys.argv[1]), Path(sys.argv[2])
image_end = int(sys.argv[3], 16)
if image_end > 0xF00:
    raise SystemExit(f"ERROR: image ends at 0x{image_end:X}; must be <= 0xF00 to reserve the BRAM stack.")
data = binary_path.read_bytes()
data += b"\x00" * ((-len(data)) % 4)
words = [f"{int.from_bytes(data[i:i+4], 'little'):08x}" for i in range(0, len(data), 4)]
if len(words) > 1024:
    raise SystemExit(f"ERROR: image uses {len(words)} words; BRAM holds 1024.")
hex_path.write_text("\n".join(words) + "\n")
print(f"Wrote {len(words)} test words to program.hex (image end 0x{image_end:X}).")
PY

# Make temporary instrumented copies. The checked-in RTL and constraints remain untouched.
python3 - "$ROOT/19_CPU/CPU.sv" "$ROOT/19_CPU/cpu_fpga_top.sv" "$ROOT/cpu_fpga_top.cst" "$OUT" <<'PY'
from pathlib import Path
import re, sys
cpu_path, top_path, cst_path, out_dir = map(Path, sys.argv[1:])
cpu = cpu_path.read_text()
# Add debug outputs to the CPU's existing module port list.
pattern = r'(output\s+wire\s+\[3:0\]\s+SDRAM_DQM)(\s*\n\s*\);)'
cpu, n = re.subn(pattern, r'\1,\n    output wire [31:0] dbg_pc,\n    output wire dbg_sdram_req,\n    output wire dbg_sdram_req_ready,\n    output wire dbg_sdram_done\2', cpu, count=1)
if n != 1:
    raise SystemExit("Could not patch CPU port list (SDRAM_DQM signature differed from expected). No source files were changed.")
needle = 'assign sdram_req = sdram_address_sel && (mem_read_enable || mem_write_enable);'
if cpu.count(needle) != 1:
    raise SystemExit("Could not locate sdram_req assignment in CPU.sv. No source files were changed.")
cpu = cpu.replace(needle, needle + '''\n\n    // Diagnostic-only exports; do not alter the CPU-side handshake.\n    assign dbg_pc = pc_out;\n    assign dbg_sdram_req = sdram_req;\n    assign dbg_sdram_req_ready = sdram_req_ready;\n    assign dbg_sdram_done = sdram_done;''', 1)
(out_dir / "CPU_diag.sv").write_text(cpu)

top = top_path.read_text()
top, n = re.subn(r'(output\s+logic\s+led0_n\s*,)', r'\1\n    output logic led1_n,', top, count=1)
if n != 1:
    raise SystemExit("Could not add LED1 port to cpu_fpga_top.sv. No source files were changed.")
# Add debug signals beside the existing CPU result signal.
needle = 'logic [31:0] cpu_result;'
if top.count(needle) != 1:
    raise SystemExit("Could not locate cpu_result declaration in top. No source files were changed.")
top = top.replace(needle, needle + '''\n    logic [31:0] dbg_pc;\n    logic dbg_sdram_req;\n    logic dbg_sdram_req_ready;\n    logic dbg_sdram_done;''', 1)
# Hook the new signals into the existing CPU instance.
needle = '.result       (cpu_result),'
if needle not in top:
    # tolerate minor spacing changes
    match = re.search(r'\.result\s*\(cpu_result\)\s*,', top)
    if not match:
        raise SystemExit("Could not locate CPU .result connection in top. No source files were changed.")
    insert_at = match.end()
    top = top[:insert_at] + '''\n        .dbg_pc(dbg_pc),\n        .dbg_sdram_req(dbg_sdram_req),\n        .dbg_sdram_req_ready(dbg_sdram_req_ready),\n        .dbg_sdram_done(dbg_sdram_done),''' + top[insert_at:]
else:
    top = top.replace(needle, needle + '''\n        .dbg_pc(dbg_pc),\n        .dbg_sdram_req(dbg_sdram_req),\n        .dbg_sdram_req_ready(dbg_sdram_req_ready),\n        .dbg_sdram_done(dbg_sdram_done),''', 1)

# Replace only the UART mux inputs, keeping the project's UART transmitter itself.
top, n1 = re.subn(r'\.data_in\s*\(cpu_uart_data\)', '.data_in (uart_mux_data)', top, count=1)
top, n2 = re.subn(r'\.start\s*\(cpu_uart_wr\s*&&\s*!uart_busy\)', '.start (uart_mux_start)', top, count=1)
if n1 != 1 or n2 != 1:
    raise SystemExit("Could not patch UART data/start connections in top. No source files were changed.")
# Declare mux signals before the transmitter instantiation for readability.
needle = 'logic       uart_busy;'
if needle not in top:
    raise SystemExit("Could not locate uart_busy declaration in top. No source files were changed.")
top = top.replace(needle, needle + '''\n    logic [7:0] uart_mux_data;\n    logic       uart_mux_start;''', 1)

# Replace the original result LED with PC-progress / SDRAM-completion LEDs and
# event logging that arbitrates with normal CPU UART writes.
start_marker = '    // Sticky LED: lights once the CPU\'s result register has been 12.'
start = top.find(start_marker)
if start < 0:
    raise SystemExit("Could not locate existing sticky LED section in top. No source files were changed.")
end_marker = '    assign led0_n = result_seen ? 1\'b0 : 1\'b1;'
end = top.find(end_marker, start)
if end < 0:
    raise SystemExit("Could not locate end of existing LED assignment in top. No source files were changed.")
end += len(end_marker)
diag_block = r'''    // Diagnostic-only status. Both LEDs are active-low.
    // LED0 lights after the CPU PC begins advancing; LED1 lights after any SDRAM done pulse.
    logic cpu_started_seen = 1'b0;
    logic sdram_done_seen = 1'b0;

    logic boot_reported, req_reported, accept_reported, done_reported;
    logic req_timeout_reported, done_timeout_reported;
    logic diag_boot_pending, diag_req_pending, diag_accept_pending, diag_done_pending;
    logic diag_req_timeout_pending, diag_done_timeout_pending;
    logic [24:0] req_wait_counter;
    logic [24:0] done_wait_counter;
    logic waiting_for_done;
    logic cpu_uart_pending;
    logic [7:0] cpu_uart_pending_data;

    wire diag_any_pending = diag_boot_pending || diag_req_pending ||
        diag_accept_pending || diag_done_pending ||
        diag_req_timeout_pending || diag_done_timeout_pending;

    // The UART prints single-character breadcrumbs while preserving the C test's
    // normal UART text. Priority order keeps the first-transaction sequence legible:
    // B=CPU PC moved, Q=request, A=accepted, D=done, w=accept timeout, h=done timeout.
    always_comb begin
        uart_mux_data  = cpu_uart_data;
        uart_mux_start = 1'b0;
        if (!uart_busy) begin
            if (diag_boot_pending) begin uart_mux_data = 8'h42; uart_mux_start = 1'b1; end // B
            else if (diag_req_pending) begin uart_mux_data = 8'h51; uart_mux_start = 1'b1; end // Q
            else if (diag_accept_pending) begin uart_mux_data = 8'h41; uart_mux_start = 1'b1; end // A
            else if (diag_done_pending) begin uart_mux_data = 8'h44; uart_mux_start = 1'b1; end // D
            else if (diag_req_timeout_pending) begin uart_mux_data = 8'h77; uart_mux_start = 1'b1; end // w
            else if (diag_done_timeout_pending) begin uart_mux_data = 8'h68; uart_mux_start = 1'b1; end // h
            else if (cpu_uart_pending) begin uart_mux_data = cpu_uart_pending_data; uart_mux_start = 1'b1; end
            else if (cpu_uart_wr) begin uart_mux_data = cpu_uart_data; uart_mux_start = 1'b1; end
        end
    end

    always_ff @(posedge clk_main) begin
        if (reset) begin
            cpu_started_seen <= 1'b0;
            sdram_done_seen <= 1'b0;
            boot_reported <= 1'b0;
            req_reported <= 1'b0;
            accept_reported <= 1'b0;
            done_reported <= 1'b0;
            req_timeout_reported <= 1'b0;
            done_timeout_reported <= 1'b0;
            diag_boot_pending <= 1'b0;
            diag_req_pending <= 1'b0;
            diag_accept_pending <= 1'b0;
            diag_done_pending <= 1'b0;
            diag_req_timeout_pending <= 1'b0;
            diag_done_timeout_pending <= 1'b0;
            req_wait_counter <= 25'd0;
            done_wait_counter <= 25'd0;
            waiting_for_done <= 1'b0;
            cpu_uart_pending <= 1'b0;
            cpu_uart_pending_data <= 8'd0;
        end else begin
            if (dbg_pc != 32'd0) begin
                cpu_started_seen <= 1'b1;
                if (!boot_reported) begin boot_reported <= 1'b1; diag_boot_pending <= 1'b1; end
            end
            if (dbg_sdram_req && !req_reported) begin
                req_reported <= 1'b1;
                diag_req_pending <= 1'b1;
            end
            if (dbg_sdram_req && dbg_sdram_req_ready && !accept_reported) begin
                accept_reported <= 1'b1;
                diag_accept_pending <= 1'b1;
            end
            if (dbg_sdram_done) begin
                sdram_done_seen <= 1'b1;
                if (!done_reported) begin done_reported <= 1'b1; diag_done_pending <= 1'b1; end
            end

            // If req remains asserted without ready for ~1 s, emit lowercase 'w'.
            if (dbg_sdram_req && !dbg_sdram_req_ready) begin
                if (req_wait_counter < 25'd26999999)
                    req_wait_counter <= req_wait_counter + 1'b1;
                else if (!req_timeout_reported) begin
                    req_timeout_reported <= 1'b1;
                    diag_req_timeout_pending <= 1'b1;
                end
            end else begin
                req_wait_counter <= 25'd0;
            end

            // Once accepted, expect done within ~1 s; emit lowercase 'h' if it hangs.
            if (dbg_sdram_req && dbg_sdram_req_ready) begin
                waiting_for_done <= 1'b1;
                done_wait_counter <= 25'd0;
            end
            if (dbg_sdram_done) begin
                waiting_for_done <= 1'b0;
                done_wait_counter <= 25'd0;
            end else if (waiting_for_done) begin
                if (done_wait_counter < 25'd26999999)
                    done_wait_counter <= done_wait_counter + 1'b1;
                else if (!done_timeout_reported) begin
                    done_timeout_reported <= 1'b1;
                    diag_done_timeout_pending <= 1'b1;
                end
            end

            // Preserve a CPU character if a diagnostic breadcrumb wins the UART
            // at the exact cycle the firmware writes a character.
            if (cpu_uart_wr && (uart_busy || diag_any_pending)) begin
                cpu_uart_pending <= 1'b1;
                cpu_uart_pending_data <= cpu_uart_data;
            end

            // Retire exactly the source selected by the UART mux at this idle edge.
            if (!uart_busy) begin
                if (diag_boot_pending) diag_boot_pending <= 1'b0;
                else if (diag_req_pending) diag_req_pending <= 1'b0;
                else if (diag_accept_pending) diag_accept_pending <= 1'b0;
                else if (diag_done_pending) diag_done_pending <= 1'b0;
                else if (diag_req_timeout_pending) diag_req_timeout_pending <= 1'b0;
                else if (diag_done_timeout_pending) diag_done_timeout_pending <= 1'b0;
                else if (cpu_uart_pending) cpu_uart_pending <= 1'b0;
            end
        end
    end

    assign led0_n = cpu_started_seen ? 1'b0 : 1'b1;
    assign led1_n = sdram_done_seen ? 1'b0 : 1'b1;'''
top = top[:start] + diag_block + top[end:]
(out_dir / "cpu_fpga_top_diag.sv").write_text(top)

# Clone the current constraints and add LED1 on pin 16, the board LED pin used by
# the repo's standalone SDRAM test. Existing SDRAM/UART/clock constraints stay intact.
cst = cst_path.read_text()
if '"led1_n"' in cst:
    raise SystemExit("Current CST already defines led1_n; inspect it before building.")
match = re.search(r'IO_PORT\s+"led0_n"[^\n]*\n', cst)
if not match:
    raise SystemExit("Could not find led0_n constraints to anchor LED1 insertion.")
cst = cst[:match.end()] + 'IO_LOC  "led1_n" 16;\nIO_PORT "led1_n" IO_TYPE=LVCMOS33 PULL_MODE=NONE;\n' + cst[match.end():]
(out_dir / "cpu_fpga_top_diag.cst").write_text(cst)
print("Generated temporary diagnostic CPU/top/CST copies.")
PY

echo "=== Synthesize diagnostic CPU bitstream (no flashing) ==="
FILES="$(printf '%s ' \
  './01_Register_File/register_file.sv' \
  './20_UART/uart_tx.sv' \
  "$OUT/CPU_diag.sv" \
  "$OUT/cpu_fpga_top_diag.sv" \
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
  './13_branch_control/branch_control.sv' \
  './21_CSR/machine_csrs.sv' \
  './22_M_Extension/m_extension.sv' \
  './22_M_Extension/m_division.sv' \
  './23_SDRAM/sdram_adapter.sv' \
)"
yosys -p "read_verilog ./23_SDRAM/gowin_rpll.v ./23_SDRAM/sdram.v; read_verilog -sv $FILES; synth_gowin -top cpu_fpga_top -json $OUT/cpu_diag.json" > "$OUT/synth_diag.log" 2>&1

echo "=== Place and route diagnostic build ==="
nextpnr-himbaechel \
  --json "$OUT/cpu_diag.json" \
  --write "$OUT/pnr_diag.json" \
  --device GW2AR-LV18QN88C8/I7 \
  --vopt family=GW2A-18C \
  --vopt "cst=$OUT/cpu_fpga_top_diag.cst"

echo "=== Package diagnostic bitstream ==="
gowin_pack -d GW2A-18C -o "$OUT/cpu_sdram_diag.fs" "$OUT/pnr_diag.json"
test -s "$OUT/cpu_sdram_diag.fs"
cp "$ORIGINAL_HEX" "$ROOT/program.hex"
RESTORE_NEEDED=0

echo
echo "READY: $OUT/cpu_sdram_diag.fs"
echo "The test firmware is in the built bitstream; original program.hex is restored."
echo "No USB/JTAG flashing was attempted."
echo "Next, close serial monitors and run: ./flash_sdram_cpu_diag.sh"
