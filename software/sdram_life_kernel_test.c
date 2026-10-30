/*
 * sdram_life_kernel_test.c
 *
 * Isolates Conway's Life memory-access pattern from Unicode rendering and
 * per-cell UART diagnostics. Runs a 128x48 generation using two SDRAM buffers.
 * Reports only once per completed row, then verifies that all generations
 * finish and prints a final pass message.
 *
 * Build with the project's existing run.sh by selecting this source file.
 */
#include <stdint.h>

#pragma GCC optimize ("Os")

#define UART_DATA (*(volatile uint8_t  *)0x10000000u)
#define UART_STAT (*(volatile uint32_t *)0x10000004u)
#define WIDTH 128u
#define HEIGHT 48u
#define CELL_COUNT (WIDTH * HEIGHT)
#define GRID_A_ADDR 0x00001000u
#define GRID_B_ADDR 0x00003000u
#define GENERATIONS 3u

static uint32_t rng_state = 0x6D2B79F5u;

static void uart_putc(char c)
{
    while (UART_STAT & 1u) { }
    UART_DATA = (uint8_t)c;
}

static void uart_puts(const char *s)
{
    while (*s) uart_putc(*s++);
}

static void uart_put_u32(uint32_t value)
{
    static const uint32_t places[5] = {10000u, 1000u, 100u, 10u, 1u};
    uint32_t i, started = 0u;
    for (i = 0u; i < 5u; ++i) {
        uint32_t digit = 0u;
        while (value >= places[i]) { value -= places[i]; ++digit; }
        if (started || digit || i == 4u) {
            uart_putc((char)('0' + digit));
            started = 1u;
        }
    }
}

static uint32_t random_next(void)
{
    uint32_t x = rng_state;
    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;
    rng_state = x;
    return x;
}

static uint32_t seed_grid(volatile uint8_t *grid)
{
    uint32_t i, alive = 0u;
    for (i = 0u; i < CELL_COUNT; ++i) {
        uint8_t value = ((random_next() & 0xFFu) < 52u) ? 1u : 0u;
        grid[i] = value;
        alive += value;
    }
    return alive;
}

static uint32_t life_step(const volatile uint8_t *current,
                          volatile uint8_t *next,
                          uint32_t generation)
{
    uint32_t y, alive = 0u;
    for (y = 0u; y < HEIGHT; ++y) {
        uint32_t up = (y == 0u) ? HEIGHT - 1u : y - 1u;
        uint32_t down = (y == HEIGHT - 1u) ? 0u : y + 1u;
        uint32_t row_up = up * WIDTH;
        uint32_t row_mid = y * WIDTH;
        uint32_t row_down = down * WIDTH;
        uint32_t x;

        for (x = 0u; x < WIDTH; ++x) {
            uint32_t left = (x == 0u) ? WIDTH - 1u : x - 1u;
            uint32_t right = (x == WIDTH - 1u) ? 0u : x + 1u;
            uint32_t neighbors;
            uint8_t was_alive = current[row_mid + x];
            uint8_t will_live;

            neighbors = current[row_up + left]
                      + current[row_up + x]
                      + current[row_up + right]
                      + current[row_mid + left]
                      + current[row_mid + right]
                      + current[row_down + left]
                      + current[row_down + x]
                      + current[row_down + right];

            will_live = (neighbors == 3u ||
                        (neighbors == 2u && was_alive)) ? 1u : 0u;
            next[row_mid + x] = will_live;
            alive += will_live;
        }

        /* Intentionally one UART report per row, not per 16 cells. */
        uart_puts("GEN="); uart_put_u32(generation);
        uart_puts(" ROW="); uart_put_u32(y);
        uart_puts(" DONE\r\n");
    }
    return alive;
}

int main(void)
{
    volatile uint8_t *a = (volatile uint8_t *)GRID_A_ADDR;
    volatile uint8_t *b = (volatile uint8_t *)GRID_B_ADDR;
    volatile uint8_t *current = a;
    volatile uint8_t *next = b;
    uint32_t generation, alive;

    uart_puts("SDRAM LIFE KERNEL TEST START\r\n");
    uart_puts("Two buffers; 8 neighbor reads + 1 center read + 1 write per cell.\r\n");
    alive = seed_grid(current);
    uart_puts("GRID INIT DONE alive="); uart_put_u32(alive); uart_puts("\r\n");

    for (generation = 0u; generation < GENERATIONS; ++generation) {
        uart_puts("BEGIN GENERATION "); uart_put_u32(generation); uart_puts("\r\n");
        alive = life_step(current, next, generation);
        {
            volatile uint8_t *temporary = current;
            current = next;
            next = temporary;
        }
        uart_puts("GENERATION COMPLETE "); uart_put_u32(generation);
        uart_puts(" alive="); uart_put_u32(alive); uart_puts("\r\n");
    }

    uart_puts("ALL SDRAM LIFE KERNEL TESTS PASSED\r\n");
    for (;;) { }
}
