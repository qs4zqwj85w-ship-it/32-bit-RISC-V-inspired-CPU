/*
 * sdram_life_optimized_nopoll.c
 *
 * SDRAM-backed Conway's Game of Life for the homemade RV32I CPU.
 *
 * Main changes from the first version:
 *   - Cache three source rows in BRAM while calculating a generation.
 *     This avoids rereading the same SDRAM cells for every neighbor.
 *   - Build a compact 12x64 Braille framebuffer completely before rendering.
 *     UART output therefore does not alternate with SDRAM reads for every glyph.
 *   - Diagnostic variant: do not read UART_STAT; pace every transmitted byte
 *     with the same conservative software delay that passed the UART-only test.
 *   - Use only small static buffers; no heap or large stack allocations.
 *
 * The 128x48 toroidal world occupies two 6 KiB buffers in SDRAM:
 *   Grid A: 0x00001000 .. 0x000027FF
 *   Grid B: 0x00003000 .. 0x000047FF
 *
 * Compile with the project's existing freestanding RV32I/Zicsr run.sh.
 */
#include <stdint.h>

#pragma GCC optimize ("Os")

/*
 * The program is linked freestanding (without libc). GCC may lower a simple
 * zero-fill loop to a call to memset even when no C library is linked. Provide
 * the tiny routine locally. Volatile stores prevent the compiler from turning
 * this implementation back into a recursive memset call.
 */
void *memset(void *destination, int value, unsigned int count)
{
    volatile uint8_t *p = (volatile uint8_t *)destination;
    unsigned int i;

    for (i = 0u; i < count; ++i) {
        p[i] = (uint8_t)value;
    }
    return destination;
}

#define UART_DATA (*(volatile uint8_t  *)0x10000000u)

#define WIDTH             128u
#define HEIGHT             48u
#define CELL_COUNT        (WIDTH * HEIGHT)
#define GRID_A_ADDR       0x00001000u
#define GRID_B_ADDR       0x00003000u
#define BRAILLE_COLS      (WIDTH / 2u)
#define BRAILLE_ROWS      (HEIGHT / 4u)
#define RESEED_AFTER       80u
#define MIN_POPULATION     16u

/* Three cached source rows for Life; rendering reuses row_cache[0]. */
static uint8_t row_cache[3][WIDTH];
/* Store one byte per Braille glyph; encode UTF-8 only when transmitting. */
static uint8_t frame_patterns[BRAILLE_ROWS][BRAILLE_COLS];
static uint32_t rng_state;

/* Deliberately avoid UART_STAT in this diagnostic build. The UART-only test
 * passed with this same conservative software pacing method. At 27 MHz this
 * loop is intentionally much longer than one 115200-baud character time. */
static void uart_tx_delay(void)
{
    volatile uint32_t delay;
    for (delay = 0u; delay < 2000u; ++delay) {
        __asm__ volatile ("nop");
    }
}

static void uart_putc(char c)
{
    UART_DATA = (uint8_t)c;
    uart_tx_delay();
}

static void uart_puts(const char *s)
{
    while (*s != '\0') {
        uart_putc(*s++);
    }
}

/* Decimal output without printf, division, or remainder instructions. */
static void uart_put_u32(uint32_t value)
{
    static const uint32_t places[5] = {
        10000u, 1000u, 100u, 10u, 1u
    };
    uint32_t i;
    uint32_t started = 0u;

    for (i = 0u; i < 5u; ++i) {
        uint32_t digit = 0u;
        while (value >= places[i]) {
            value -= places[i];
            ++digit;
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

static void load_sdram_row(const volatile uint8_t *grid,
                           uint32_t y,
                           uint8_t *destination)
{
    uint32_t x;
    uint32_t base = y << 7; /* WIDTH is 128. */

    for (x = 0u; x < WIDTH; ++x) {
        destination[x] = grid[base + x];
    }
}

static void set_alive(volatile uint8_t *grid,
                      uint32_t index,
                      uint32_t *population)
{
    if (grid[index] == 0u) {
        grid[index] = 1u;
        ++(*population);
    }
}

/* Fill with a sparse random pattern and add a recognizable glider. */
static uint32_t seed_grid(volatile uint8_t *grid)
{
    uint32_t i;
    uint32_t alive = 0u;

    for (i = 0u; i < CELL_COUNT; ++i) {
        uint8_t cell = ((random_next() & 0xFFu) < 52u) ? 1u : 0u;
        grid[i] = cell;
        alive += cell;
    }

    /* A small glider in the upper-left area; population stays accurate. */
    set_alive(grid, 1u * WIDTH + 2u, &alive);
    set_alive(grid, 2u * WIDTH + 3u, &alive);
    set_alive(grid, 3u * WIDTH + 1u, &alive);
    set_alive(grid, 3u * WIDTH + 2u, &alive);
    set_alive(grid, 3u * WIDTH + 3u, &alive);

    return alive;
}

/*
 * One toroidal generation.
 * Read each source row into BRAM once as we move downward through the world.
 * This cuts repeated SDRAM neighbor loads substantially compared with the
 * straightforward per-cell implementation.
 */
static uint32_t life_step(const volatile uint8_t *current,
                          volatile uint8_t *next)
{
    uint8_t *row_up = row_cache[0];
    uint8_t *row_mid = row_cache[1];
    uint8_t *row_down = row_cache[2];
    uint32_t y;
    uint32_t alive = 0u;

    load_sdram_row(current, HEIGHT - 1u, row_up);
    load_sdram_row(current, 0u, row_mid);
    load_sdram_row(current, 1u, row_down);

    for (y = 0u; y < HEIGHT; ++y) {
        uint32_t x;
        uint32_t row_base = y << 7;

        for (x = 0u; x < WIDTH; ++x) {
            uint32_t left = (x == 0u) ? (WIDTH - 1u) : (x - 1u);
            uint32_t right = (x + 1u == WIDTH) ? 0u : (x + 1u);
            uint32_t neighbors =
                  row_up[left] + row_up[x] + row_up[right]
                + row_mid[left]                + row_mid[right]
                + row_down[left] + row_down[x] + row_down[right];
            uint8_t was_alive = row_mid[x];
            uint8_t will_live =
                (neighbors == 3u || (neighbors == 2u && was_alive)) ? 1u : 0u;

            next[row_base + x] = will_live;
            alive += will_live;
        }

        /* Rotate the three row buffers; load the next row into the old one. */
        if (y + 1u < HEIGHT) {
            uint8_t *temporary = row_up;
            uint32_t new_y = y + 2u;
            row_up = row_mid;
            row_mid = row_down;
            row_down = temporary;
            if (new_y >= HEIGHT) {
                new_y -= HEIGHT;
            }
            load_sdram_row(current, new_y, row_down);
        }
    }

    return alive;
}

/* Create the complete frame before printing anything from that frame. */
static void build_frame(const volatile uint8_t *grid)
{
    uint32_t glyph_y;

    for (glyph_y = 0u; glyph_y < BRAILLE_ROWS; ++glyph_y) {
        uint32_t cell_y = glyph_y * 4u;
        uint32_t glyph_x;
        uint32_t dot_row;

        /* Clear this output row, then add the corresponding two Braille dots
           as each of its four source rows is read. Only one cache row is
           needed for rendering, keeping the BRAM footprint small. */
        for (glyph_x = 0u; glyph_x < BRAILLE_COLS; ++glyph_x) {
            frame_patterns[glyph_y][glyph_x] = 0u;
        }

        for (dot_row = 0u; dot_row < 4u; ++dot_row) {
            load_sdram_row(grid, cell_y + dot_row, row_cache[0]);

            for (glyph_x = 0u; glyph_x < BRAILLE_COLS; ++glyph_x) {
                uint32_t x = glyph_x * 2u;
                uint32_t x_right = x + 1u;
                uint8_t pattern = frame_patterns[glyph_y][glyph_x];

                /* Unicode Braille dot layout for a 2-column by 4-row block. */
                if (row_cache[0][x] != 0u) {
                    pattern |= (dot_row == 0u) ? (1u << 0)
                             : (dot_row == 1u) ? (1u << 1)
                             : (dot_row == 2u) ? (1u << 2) : (1u << 6);
                }
                if (row_cache[0][x_right] != 0u) {
                    pattern |= (dot_row == 0u) ? (1u << 3)
                             : (dot_row == 1u) ? (1u << 4)
                             : (dot_row == 2u) ? (1u << 5) : (1u << 7);
                }
                frame_patterns[glyph_y][glyph_x] = pattern;
            }
        }
    }
}

static void uart_put_braille(uint8_t pattern)
{
    /* UTF-8 encoding of U+2800 + pattern. */
    uart_putc((char)0xE2u);
    uart_putc((char)(0xA0u + (pattern >> 6)));
    uart_putc((char)(0x80u | (pattern & 0x3Fu)));
}

static void render_frame(uint32_t generation, uint32_t population)
{
    uint32_t y;

    /* No SDRAM accesses occur during this transmission phase. */
    uart_puts("\x1b[2J\x1b[H\x1b[?25l\x1b[1;32m");
    uart_puts("SDRAM CONWAY'S LIFE  128x48 cells  |  generation ");
    uart_put_u32(generation);
    uart_puts("  |  alive ");
    uart_put_u32(population);
    uart_puts("\x1b[0m\r\n\r\n");

    for (y = 0u; y < BRAILLE_ROWS; ++y) {
        uint32_t x;
        for (x = 0u; x < BRAILLE_COLS; ++x) {
            uart_put_braille(frame_patterns[y][x]);
        }
        uart_puts("\r\n");
    }

    uart_puts("\r\nTwo byte-per-cell SDRAM buffers: 0x1000 and 0x3000\r\n");
    uart_puts("Re-seeds every 80 generations.\r\n");
}

int main(void)
{
    volatile uint8_t *grid_a = (volatile uint8_t *)GRID_A_ADDR;
    volatile uint8_t *grid_b = (volatile uint8_t *)GRID_B_ADDR;
    volatile uint8_t *current = grid_a;
    volatile uint8_t *next = grid_b;
    uint32_t population;

    rng_state = 0x6D2B79F5u;
    uart_puts("Starting optimized SDRAM-backed Conway's Game of Life (UART no-poll diagnostic)...\r\n");
    uart_puts("Caching rows in BRAM; frame-buffered output; UART_STAT bypassed.\r\n");
    population = seed_grid(current);

    for (;;) {
        uint32_t generation;

        for (generation = 0u; generation < RESEED_AFTER; ++generation) {
            /* All SDRAM reads needed for the image happen before UART output. */
            build_frame(current);
            render_frame(generation, population);

            population = life_step(current, next);
            {
                volatile uint8_t *temporary = current;
                current = next;
                next = temporary;
            }

            if (population < MIN_POPULATION) {
                break;
            }
        }

        uart_puts("\r\nRe-seeding the world in SDRAM...\r\n");
        population = seed_grid(current);
    }
}
