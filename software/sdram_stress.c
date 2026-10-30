/*
 * sdram_stress.c - sustained CPU-side SDRAM byte-access test.
 *
 * Runs from BRAM and hammers the CPU SDRAM path with byte stores followed by
 * byte loads across 16 KiB of the SDRAM window. This is intended to reproduce
 * long-running transaction/refresh issues, not just check a few isolated
 * locations. It uses only RV32I/Zicsr-compatible operations.
 */
#include <stdint.h>

#pragma GCC optimize ("Os")

#define UART_DATA (*(volatile uint8_t  *)0x10000000u)
#define UART_STAT (*(volatile uint32_t *)0x10000004u)
#define SDRAM_BASE 0x00001000u
#define TEST_SPAN  0x00004000u   /* 16 KiB: spans both Life buffers and gap */
#define ITERATIONS 65536u        /* 131,072 SDRAM transactions */

static void uart_putc(char c)
{
    while (UART_STAT & 1u) { }
    UART_DATA = (uint8_t)c;
}

static void uart_puts(const char *s)
{
    while (*s) uart_putc(*s++);
}

static void uart_hex32(uint32_t value)
{
    static const char digits[] = "0123456789ABCDEF";
    int shift;
    uart_puts("0x");
    for (shift = 28; shift >= 0; shift -= 4) {
        uart_putc(digits[(value >> shift) & 0xFu]);
    }
}

static void report_progress(uint32_t iteration, uint32_t address)
{
    uart_puts("PROGRESS iterations=");
    uart_hex32(iteration);
    uart_puts(" last_addr=");
    uart_hex32(address);
    uart_puts("\r\n");
}

static void report_failure(uint32_t iteration, uint32_t address,
                           uint8_t expected, uint8_t actual)
{
    uart_puts("\r\nFAIL iteration=");
    uart_hex32(iteration);
    uart_puts(" address=");
    uart_hex32(address);
    uart_puts(" expected=");
    uart_hex32((uint32_t)expected);
    uart_puts(" actual=");
    uart_hex32((uint32_t)actual);
    uart_puts("\r\n");
    for (;;) { }
}

int main(void)
{
    volatile uint8_t *memory = (volatile uint8_t *)SDRAM_BASE;
    uint32_t i;

    uart_puts("CPU SDRAM STRESS TEST START\r\n");
    uart_puts("Pattern: byte write then immediate byte read/compare.\r\n");
    uart_puts("Span: 16 KiB; total: 65536 iterations / 131072 SDRAM ops.\r\n");

    for (i = 0; i < ITERATIONS; i++) {
        uint32_t offset = i & (TEST_SPAN - 1u);
        uint32_t address = SDRAM_BASE + offset;
        uint8_t expected = (uint8_t)((i ^ (i >> 8) ^ 0xA5u) & 0xFFu);
        uint8_t actual;

        memory[offset] = expected;
        actual = memory[offset];
        if (actual != expected) {
            report_failure(i, address, expected, actual);
        }

        if ((i & 1023u) == 1023u) {
            report_progress(i + 1u, address);
        }
    }

    uart_puts("\r\nALL SDRAM STRESS TESTS PASSED\r\n");
    for (;;) { }
}
