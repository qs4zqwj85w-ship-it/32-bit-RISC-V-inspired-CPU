/*
 * sdram_life_uart_nopoll_diag.c
 * Isolates the UART transmitter from the UART status-register read path.
 * It NEVER reads UART_STAT. Instead, it waits a conservative software delay
 * after every byte so the previous 115200-baud transmission should finish.
 */
#include <stdint.h>

#pragma GCC optimize ("Os")

#define UART_DATA (*(volatile uint8_t *)0x10000000u)

static void tx_delay(void)
{
    /* Volatile loop prevents optimization; deliberately much longer than one
       115200-baud 8-N-1 character time on the 27 MHz CPU clock. */
    volatile uint32_t delay;
    for (delay = 0u; delay < 2000u; ++delay) {
        __asm__ volatile ("nop");
    }
}

static void uart_putc_nopoll(char c)
{
    UART_DATA = (uint8_t)c;
    tx_delay();
}

static void uart_puts_nopoll(const char *s)
{
    while (*s) {
        uart_putc_nopoll(*s++);
    }
}

static void uart_put_u32_nopoll(uint32_t value)
{
    static const uint32_t places[5] = { 10000u, 1000u, 100u, 10u, 1u };
    uint32_t i;
    uint32_t started = 0u;

    for (i = 0u; i < 5u; ++i) {
        uint32_t digit = 0u;
        while (value >= places[i]) {
            value -= places[i];
            ++digit;
        }
        if (started || digit != 0u || i == 4u) {
            uart_putc_nopoll((char)('0' + digit));
            started = 1u;
        }
    }
}

int main(void)
{
    uint32_t block;
    uart_puts_nopoll("UART NO-POLL TEST START; UART_STAT is never read.\r\n");

    for (block = 0u; block < 64u; ++block) {
        uint32_t i;
        uart_puts_nopoll("BLOCK ");
        uart_put_u32_nopoll(block);
        uart_puts_nopoll(" START\r\n");

        for (i = 0u; i < 128u; ++i) {
            uart_putc_nopoll(((i + block) & 1u) ? 'A' : 'B');
        }

        uart_puts_nopoll("\r\nBLOCK ");
        uart_put_u32_nopoll(block);
        uart_puts_nopoll(" DONE\r\n");
    }

    uart_puts_nopoll("UART NO-POLL TEST PASSED: 8192 data characters sent.\r\n");
    for (;;) {
    }
}
