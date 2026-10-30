/*
 * sdram_life_uart_status_stress.c
 * Long-duration, bounded test of the CPU-visible UART busy/status path.
 *
 * Payload characters use the same "wait for UART_STAT idle, then write
 * UART_DATA" protocol as the original polled UART diagnostic. If a status
 * wait ever exceeds the bound, the program exits that loop and attempts to
 * report the precise block/character using a paced no-poll output routine.
 * Progress/report text uses software pacing so it does not depend on STAT.
 */
#include <stdint.h>

#pragma GCC optimize ("Os")

#define UART_DATA (*(volatile uint8_t  *)0x10000000u)
#define UART_STAT (*(volatile uint32_t *)0x10000004u)
#define POLL_LIMIT 50000u

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

static int putc_polled_bounded(char c, uint32_t *poll_count)
{
    uint32_t polls = 0u;
    while (UART_STAT & 1u) {
        ++polls;
        if (polls >= POLL_LIMIT) {
            *poll_count = polls;
            return 0;
        }
    }
    UART_DATA = (uint8_t)c;
    *poll_count = polls;
    return 1;
}

int main(void)
{
    uint32_t block, total_polls = 0u;
    puts_nopoll("UART STATUS STRESS START: 8192 chars; bounded polling\r\n");

    for (block = 0u; block < 64u; ++block) {
        uint32_t i;
        puts_nopoll("BLOCK ");
        put_u32_nopoll(block);
        puts_nopoll(" START\r\n");

        for (i = 0u; i < 128u; ++i) {
            uint32_t polls = 0u;
            char ch = (((i + block) & 1u) != 0u) ? 'A' : 'B';
            if (!putc_polled_bounded(ch, &polls)) {
                puts_nopoll("STATUS POLL TIMEOUT block=");
                put_u32_nopoll(block);
                puts_nopoll(" char=");
                put_u32_nopoll(i);
                puts_nopoll(" polls=");
                put_u32_nopoll(polls);
                puts_nopoll("\r\n");
                for (;;) { }
            }
            total_polls += polls;
        }

        puts_nopoll("\r\nBLOCK ");
        put_u32_nopoll(block);
        puts_nopoll(" DONE total_polls=");
        put_u32_nopoll(total_polls);
        puts_nopoll("\r\n");
    }

    puts_nopoll("UART STATUS STRESS PASSED: 8192 chars; total_polls=");
    put_u32_nopoll(total_polls);
    puts_nopoll("\r\n");
    for (;;) { }
}
