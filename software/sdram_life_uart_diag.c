/*
 * sdram_life_uart_diag.c
 * Isolates the memory-mapped UART by transmitting >8 KiB of ASCII without
 * accessing SDRAM. Point run.sh at this source and flash using the usual flow.
 */
#include <stdint.h>

#pragma GCC optimize ("Os")

#define UART_DATA (*(volatile uint8_t  *)0x10000000u)
#define UART_STAT (*(volatile uint32_t *)0x10000004u)

static void uart_putc(char c)
{
    while (UART_STAT & 1u) {
    }
    UART_DATA = (uint8_t)c;
}

static void uart_puts(const char *s)
{
    while (*s) {
        uart_putc(*s++);
    }
}

static void uart_put_u32(uint32_t value)
{
    static const uint32_t places[5] = { 10000u, 1000u, 100u, 10u, 1u };
    uint32_t i;
    uint32_t started = 0u;

    for (i = 0u; i < 5u; i++) {
        uint32_t digit = 0u;
        while (value >= places[i]) {
            value -= places[i];
            digit++;
        }
        if (started || digit != 0u || i == 4u) {
            uart_putc((char)('0' + digit));
            started = 1u;
        }
    }
}

int main(void)
{
    uint32_t block;
    uart_puts("UART-ONLY TEST START; no SDRAM accesses follow.\r\n");

    /* 64 x 128 = 8192 data characters, plus markers. */
    for (block = 0u; block < 64u; block++) {
        uint32_t i;
        uart_puts("BLOCK ");
        uart_put_u32(block);
        uart_puts(" START\r\n");

        for (i = 0u; i < 128u; i++) {
            /* A deterministic ASCII pattern; no strings or memory buffers. */
            uart_putc(((i + block) & 1u) ? 'A' : 'B');
        }

        uart_puts("\r\nBLOCK ");
        uart_put_u32(block);
        uart_puts(" DONE\r\n");
    }

    uart_puts("UART-ONLY TEST PASSED: 8192 data characters sent.\r\n");
    for (;;) {
    }
}
