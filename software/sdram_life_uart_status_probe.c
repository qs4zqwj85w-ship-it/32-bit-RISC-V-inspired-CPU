/*
 * sdram_life_uart_status_probe.c
 * Probes the CPU-visible UART status register with a bounded polling loop.
 * All diagnostic text is sent through UART_DATA with a software delay, so
 * printing the result does not depend on UART_STAT working correctly.
 */
#include <stdint.h>

#pragma GCC optimize ("Os")

#define UART_DATA (*(volatile uint8_t  *)0x10000000u)
#define UART_STAT (*(volatile uint32_t *)0x10000004u)

static void tx_delay(void)
{
    volatile uint32_t delay;
    for (delay = 0u; delay < 2000u; ++delay) {
        __asm__ volatile ("nop");
    }
}

static void putc_nopoll(char c)
{
    UART_DATA = (uint8_t)c;
    tx_delay();
}

static void puts_nopoll(const char *s)
{
    while (*s) putc_nopoll(*s++);
}

static void put_u32_nopoll(uint32_t value)
{
    static const uint32_t places[5] = { 10000u, 1000u, 100u, 10u, 1u };
    uint32_t i, digit, started = 0u;
    for (i = 0u; i < 5u; ++i) {
        digit = 0u;
        while (value >= places[i]) {
            value -= places[i];
            ++digit;
        }
        if (started || digit != 0u || i == 4u) {
            putc_nopoll((char)('0' + digit));
            started = 1u;
        }
    }
}

static void print_bit_result(uint32_t trial, uint32_t first,
                             uint32_t last, uint32_t polls,
                             uint32_t cleared)
{
    puts_nopoll("TRIAL "); put_u32_nopoll(trial);
    puts_nopoll(" first="); put_u32_nopoll(first);
    puts_nopoll(" last="); put_u32_nopoll(last);
    puts_nopoll(" polls="); put_u32_nopoll(polls);
    puts_nopoll(cleared ? " CLEARED\r\n" : " TIMEOUT\r\n");
}

int main(void)
{
    uint32_t trial;
    puts_nopoll("UART STATUS PROBE START (bounded polling; output bypasses STAT)\r\n");

    for (trial = 0u; trial < 8u; ++trial) {
        uint32_t first, last, polls, cleared;

        /* The previous diagnostic text was paced, so UART should be idle.
           Start one character directly, then sample status immediately. */
        UART_DATA = (uint8_t)'X';
        first = UART_STAT;
        last = first;
        polls = 0u;
        cleared = ((first & 1u) == 0u);

        /* Bound the wait so a stuck busy bit cannot hang this diagnostic. */
        while (!cleared && polls < 50000u) {
            last = UART_STAT;
            ++polls;
            cleared = ((last & 1u) == 0u);
        }

        print_bit_result(trial, first & 1u, last & 1u, polls, cleared);
        /* Ensure the next probe starts with the UART given ample idle time. */
        tx_delay();
    }

    puts_nopoll("UART STATUS PROBE COMPLETE\r\n");
    for (;;) { }
}
