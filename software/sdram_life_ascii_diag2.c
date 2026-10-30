/*
 * sdram_life_ascii_diag2.c - SDRAM-backed Conway's Game of Life for the homemade RV32 CPU.
 *
 * The 128 x 48 cell world uses two byte-per-cell buffers in external SDRAM:
 *   Grid A: 0x00001000 .. 0x000027FF (6 KiB)
 *   Grid B: 0x00003000 .. 0x000047FF (6 KiB)
 *
 * The executable itself still runs from BRAM. The world buffers are placed
 * explicitly in the CPU's SDRAM address window. This diagnostic build renders ASCII cells and row markers rather than Braille,
 * so UART/terminal behavior can be isolated from the Game of Life kernel.
 *
 * Build with the project's freestanding RV32I/Zicsr toolchain. No libc,
 * printf, heap, multiplication, or division is required by this program.
 */
#include <stdint.h>

#pragma GCC optimize ("Os")

#define UART_DATA (*(volatile uint8_t  *)0x10000000u)
#define UART_STAT (*(volatile uint32_t *)0x10000004u)

#define WIDTH          128u
#define HEIGHT          48u
#define CELL_COUNT     (WIDTH * HEIGHT)
#define GRID_A_ADDR    0x00001000u
#define GRID_B_ADDR    0x00003000u
#define RESEED_AFTER    80u
#define MIN_POPULATION  16u

static uint32_t rng_state;

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

/* Print a value from 0 to 99999 without using divide/modulo instructions. */
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

static uint32_t random_next(void)
{
    uint32_t x = rng_state;
    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;
    rng_state = x;
    return x;
}

/* Fill one SDRAM buffer with a deterministic, moderately sparse random world. */
static uint32_t seed_grid(volatile uint8_t *grid)
{
    uint32_t i;
    uint32_t alive = 0u;

    for (i = 0u; i < CELL_COUNT; i++) {
        uint8_t cell = ((random_next() & 0xFFu) < 52u) ? 1u : 0u;
        grid[i] = cell;
        alive += cell;
    }

    /* Insert a small, recognizable glider near the upper-left corner. */
    grid[1u * WIDTH + 2u] = 1u;
    grid[2u * WIDTH + 3u] = 1u;
    grid[3u * WIDTH + 1u] = 1u;
    grid[3u * WIDTH + 2u] = 1u;
    grid[3u * WIDTH + 3u] = 1u;

    /* Recount after inserting the five glider cells (some may already be alive). */
    alive = 0u;
    for (i = 0u; i < CELL_COUNT; i++) {
        alive += (grid[i] != 0u) ? 1u : 0u;
    }
    return alive;
}

/* One toroidal Life generation. Return the new population count. */
static uint32_t life_step(const volatile uint8_t *current,
                          volatile uint8_t *next)
{
    uint32_t y;
    uint32_t alive = 0u;

    for (y = 0u; y < HEIGHT; y++) {
        uint32_t up = (y == 0u) ? (HEIGHT - 1u) : (y - 1u);
        uint32_t down = (y == HEIGHT - 1u) ? 0u : (y + 1u);
        uint32_t row_up = up * WIDTH;
        uint32_t row_mid = y * WIDTH;
        uint32_t row_down = down * WIDTH;
        uint32_t x;

        for (x = 0u; x < WIDTH; x++) {
            uint32_t left = (x == 0u) ? (WIDTH - 1u) : (x - 1u);
            uint32_t right = (x == WIDTH - 1u) ? 0u : (x + 1u);
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
    }

    return alive;
}

/* ASCII diagnostic renderer. This deliberately avoids UTF-8 bytes and ANSI
 * cursor-control sequences so we can separate terminal rendering from SDRAM
 * compute. It also prints row markers and buffers each row before output, separating SDRAM loads from UART transmission. */
static void render_grid(const volatile uint8_t *grid,
                        uint32_t generation, uint32_t population)
{
    uint32_t y;

    uart_puts("\r\nASCII SDRAM LIFE gen=");
    uart_put_u32(generation);
    uart_puts(" alive=");
    uart_put_u32(population);
    uart_puts("\r\n");

    for (y = 0u; y < HEIGHT; y++) {
        uint32_t x;
        uint8_t row_cells[WIDTH];

        uart_puts("ROW ");
        uart_put_u32(y);
        uart_puts(" START\r\n");

        /* Read the entire row from SDRAM before sending any cell characters.
           This separates SDRAM loads from the UART-heavy print loop. */
        for (x = 0u; x < WIDTH; x++) {
            row_cells[x] = grid[y * WIDTH + x];
        }

        uart_puts("ROW ");
        uart_put_u32(y);
        uart_puts(" DATA LOADED\r\n");

        for (x = 0u; x < WIDTH; x++) {
            uart_putc(row_cells[x] ? '#' : '.');
        }
        uart_puts("\r\nROW ");
        uart_put_u32(y);
        uart_puts(" DONE\r\n");
    }
    uart_puts("ASCII RENDER COMPLETE\r\n");
}

int main(void)
{
    volatile uint8_t *grid_a = (volatile uint8_t *)GRID_A_ADDR;
    volatile uint8_t *grid_b = (volatile uint8_t *)GRID_B_ADDR;
    volatile uint8_t *current = grid_a;
    volatile uint8_t *next = grid_b;
    uint32_t population;

    rng_state = 0x6D2B79F5u;

    uart_puts("Starting SDRAM-backed Conway's Game of Life...\r\n");
    uart_puts("Initializing 12 KiB of grid buffers in SDRAM.\r\n");
    population = seed_grid(current);

    for (;;) {
        uint32_t generation;

        for (generation = 0u; generation < RESEED_AFTER; generation++) {
            render_grid(current, generation, population);
            uart_puts("TRACE: render complete; life_step start\r\n");
            population = life_step(current, next);
            uart_puts("TRACE: life_step complete; alive=");
            uart_put_u32(population);
            uart_puts("\r\n");

            {
                volatile uint8_t *temporary = current;
                current = next;
                next = temporary;
            }
            uart_puts("TRACE: buffers swapped\r\n");

            if (population < MIN_POPULATION) {
                uart_puts("TRACE: low population; reseeding\r\n");
                break;
            }
        }

        uart_puts("\r\nRe-seeding the world in SDRAM...\r\n");
        population = seed_grid(current);
    }
}
