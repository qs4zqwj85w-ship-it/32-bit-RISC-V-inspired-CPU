/*
 * main.c - compact "show your friends" demo for a homemade RV32I CPU.
 *
 * Output goes over the memory-mapped UART (115200 baud) with ANSI codes.
 * Open it in a real terminal, at least 70 columns x 28 rows:
 *     screen /dev/cu.usbserial-XXXX 115200      (quit: Ctrl-A, then K)
 *
 * Loops forever through:
 *   1. Banner: the CPU reads its own misa CSR and prints the ISA it reports.
 *   2. Trap demo: ecall and ebreak caught by the CPU's trap hardware.
 *   3. Mandelbrot set, fixed point, computed on the CPU.
 *   4. Conway's Game of Life on a 32x16 torus.
 *
 * Plain RV32I only: no multiply, divide, libc, or printf. Nothing relies on
 * .data/.bss initialisation. Compile with -Os; if it still doesn't fit your
 * memory limit, set one of the ENABLE_* switches below to 0.
 *
 * Preview on a Mac/PC without the board:
 *     gcc -O2 -DHOST_SIM -DDEMO_ROUNDS=1 main.c -o demo && ./demo
 */
#include <stdint.h>

/* Keep the code small whatever -O level the build script uses (GCC). */
#pragma GCC optimize ("Os")

#ifndef ENABLE_TRAPS
#define ENABLE_TRAPS 1
#endif
#ifndef ENABLE_MANDEL
#define ENABLE_MANDEL 1
#endif
#ifndef ENABLE_LIFE
#define ENABLE_LIFE 1
#endif
#ifndef MAXIT
#define MAXIT 32            /* the palette below assumes 32 */
#endif
#ifndef LIFE_GENS
#define LIFE_GENS 200       /* must be below 10000 */
#endif
#ifndef PAUSE
#define PAUSE 3000000u      /* busy-wait between sections; tune to taste */
#endif
#ifndef DEMO_ROUNDS
#define DEMO_ROUNDS 0       /* 0 = repeat forever */
#endif
#if LIFE_GENS > 9999
#error "LIFE_GENS must be below 10000"
#endif

/* =====================================================================
 * Platform layer: the only code that touches hardware
 * ===================================================================== */
#ifdef HOST_SIM
#include <stdio.h>
volatile uint32_t last_cause;
static void uart_putc(char c)       { putchar(c); }
static void spin(uint32_t n)        { (void)n; }
static uint32_t read_misa(void)     { return 0x40000100u; }   /* RV32 + I */
static void install_trap_handler(void) {}
static void do_ecall(void)          { last_cause = 11; }
static void do_ebreak(void)         { last_cause = 3; }
#else
#define UART_DATA (*(volatile uint8_t  *)0x10000000u)
#define UART_STAT (*(volatile uint32_t *)0x10000004u)

volatile uint32_t last_cause;       /* not static: the handler asm names it */

static void uart_putc(char c) { while (UART_STAT & 1u) ; UART_DATA = (uint8_t)c; }
static void spin(uint32_t n)  { for (volatile uint32_t i = 0; i < n; i++) ; }

static uint32_t read_misa(void)
{ uint32_t v; __asm__ volatile ("csrr %0, misa" : "=r"(v) :: "memory"); return v; }

/* Saves mcause, skips the trapping instruction, returns. */
__attribute__((naked, noinline, used, aligned(4), section(".text")))
void trap_handler(void)
{
    __asm__ volatile (
        "csrr t0, mcause\n"
        "la   t1, last_cause\n"
        "sw   t0, 0(t1)\n"
        "csrr t0, mepc\n"
        "addi t0, t0, 4\n"
        "csrw mepc, t0\n"
        "mret\n"
    );
}

static void install_trap_handler(void)
{ __asm__ volatile ("csrw mtvec, %0" :: "r"((uintptr_t)&trap_handler) : "memory"); }
static void do_ecall(void)  { __asm__ volatile ("ecall"  ::: "memory", "t0", "t1"); }
static void do_ebreak(void) { __asm__ volatile ("ebreak" ::: "memory", "t0", "t1"); }
#endif

/* =====================================================================
 * Output helpers (no printf, no divide)
 * ===================================================================== */
static void uart_puts(const char *s) { while (*s) uart_putc(*s++); }

static void cls(void)  { uart_puts("\x1b[2J\x1b[H\x1b[?25l"); }   /* clear, home, hide cursor */
static void home(void) { uart_puts("\x1b[H"); }
/* ANSI foreground: '1' red '2' green '3' yellow '4' blue '5' magenta '6' cyan '7' white '9' default */
static void color(char c) { uart_puts("\x1b[3"); uart_putc(c); uart_putc('m'); }

static void put_dec(uint32_t v)              /* 0..9999, no leading zeros */
{
    static const uint32_t p10[4] = { 1000u, 100u, 10u, 1u };
    int started = 0;
    for (int i = 0; i < 4; i++) {
        char d = '0';
        while (v >= p10[i]) { v -= p10[i]; d++; }
        if (d != '0' || started || i == 3) { uart_putc(d); started = 1; }
    }
}

/* =====================================================================
 * 1. Banner
 * ===================================================================== */
static void banner(void)
{
    uint32_t m = read_misa();
    cls(); color('7');
    uart_puts("  _       _\r\n"
              " (_)_____(_)\r\n"
              "  /  o o  \\\r\n"
              " (    ^    )\r\n"
              "  \\  \\_/  /\r\n"
              "   '-----'\r\n");
    color('6');
    uart_puts("HOMEMADE RISC-V CPU\r\n"
              "32-bit, multi-cycle\r\n"
              "SystemVerilog on FPGA\r\n");
    color('9');
    uart_puts("misa says: RV");
    uart_puts((m >> 30) == 1u ? "32" : "??");
    for (int i = 0; i < 26; i++)
        if ((m >> i) & 1u) uart_putc((char)('A' + i));
    uart_puts("\r\n");
}

/* =====================================================================
 * 2. Trap demo
 * ===================================================================== */
#if ENABLE_TRAPS
static void trap_demo(void)
{
    install_trap_handler();
    last_cause = 0;
    do_ecall();
    uart_puts(last_cause == 11u ? "ecall trap OK\r\n"  : "ecall FAIL\r\n");
    do_ebreak();
    uart_puts(last_cause == 3u  ? "ebreak trap OK\r\n" : "ebreak FAIL\r\n");
}
#endif

/* =====================================================================
 * 3. Mandelbrot, Q4.12 fixed point (multiply is shift-and-add: no M ext.)
 * ===================================================================== */
#if ENABLE_MANDEL
#define FIX     12
#define FOUR    (4 << FIX)
#define X0      (-9011)     /* -2.2 */
#define Y0      (-4915)     /* -1.2 */
#define DX      218         /* ~3.2 / 60 columns */
#define DY      410         /* ~2.4 / 24 rows */

static int32_t mul_fix(int32_t a, int32_t b)
{
    uint32_t neg = (uint32_t)((a < 0) ^ (b < 0));
    uint32_t ua  = (a < 0) ? (uint32_t)(-a) : (uint32_t)a;
    uint32_t ub  = (b < 0) ? (uint32_t)(-b) : (uint32_t)b;
    uint32_t p   = 0;
    while (ub) {
        if (ub & 1u) p += ua;
        ua <<= 1;
        ub >>= 1;
    }
    p >>= FIX;
    return neg ? -(int32_t)p : (int32_t)p;
}

static void mandelbrot(void)
{
    static const char pal[8] = { ' ', '.', ':', '-', '=', '+', '*', '%' };
    static const char col[8] = { '4', '4', '6', '2', '3', '1', '5', '7' };
    int last = -1;
    int32_t cy = Y0;

    cls();
    for (int row = 0; row < 24; row++, cy += DY) {
        int32_t cx = X0;
        for (int c = 0; c < 60; c++, cx += DX) {
            int32_t x = 0, y = 0;
            int it = 0;
            while (it < MAXIT) {
                int32_t x2 = mul_fix(x, x);
                int32_t y2 = mul_fix(y, y);
                if (x2 + y2 > FOUR) break;           /* escaped */
                int32_t xy = mul_fix(x, y);
                y = (xy + xy) + cy;
                x = (x2 - y2) + cx;
                it++;
            }
            if (it >= MAXIT) {                       /* inside the set */
                if (last != 8) { color('7'); last = 8; }
                uart_putc('@');
            } else {
                int idx = (it >> 2) & 7;
                if (idx != last) { color(col[idx]); last = idx; }
                uart_putc(pal[idx]);
            }
        }
        uart_puts("\r\n");
    }
    color('9');
}
#endif

/* =====================================================================
 * 4. Conway's Game of Life, 32x16 torus, one uint32_t per row
 * ===================================================================== */
#if ENABLE_LIFE
#define L_ROWS 16

static uint32_t buf_a[L_ROWS], buf_b[L_ROWS];
static uint32_t rng_state;

static uint32_t rng(void)                    /* xorshift32: no multiply */
{
    uint32_t x = rng_state;
    x ^= x << 13; x ^= x >> 17; x ^= x << 5;
    rng_state = x;
    return x;
}

static int cell(const uint32_t *g, int r, int c)
{ return (int)((g[r & (L_ROWS - 1)] >> (c & 31)) & 1u); }

static void life_step(const uint32_t *cur, uint32_t *nxt)
{
    for (int r = 0; r < L_ROWS; r++) {
        uint32_t row = 0;
        for (int c = 0; c < 32; c++) {
            int n = 0;                           /* 3x3 sum, centre included */
            for (int dr = -1; dr <= 1; dr++)
                for (int dc = -1; dc <= 1; dc++)
                    n += cell(cur, r + dr, c + dc);
            if (n == 3 || (n == 4 && cell(cur, r, c))) row |= 1u << c;
        }
        nxt[r] = row;
    }
}

static int same(const uint32_t *a, const uint32_t *b)
{
    for (int r = 0; r < L_ROWS; r++) if (a[r] != b[r]) return 0;
    return 1;
}

static uint32_t population(const uint32_t *g)
{
    uint32_t n = 0;
    for (int r = 0; r < L_ROWS; r++) {
        uint32_t x = g[r];
        while (x) { x &= x - 1u; n++; }
    }
    return n;
}

static void reseed(uint32_t *g)
{
    for (int r = 0; r < L_ROWS; r++) g[r] = rng() & rng();   /* ~25% alive */
}

static void hline(void)
{
    uart_putc('+');
    for (int c = 0; c < 64; c++) uart_putc('-');
    uart_puts("+\r\n");
}

static void render(const uint32_t *g, uint32_t gen)
{
    home(); color('2');
    hline();
    for (int r = 0; r < L_ROWS; r++) {
        uart_putc('|');
        for (int c = 0; c < 32; c++) {
            char ch = ((g[r] >> c) & 1u) ? '#' : ' ';
            uart_putc(ch); uart_putc(ch);
        }
        uart_puts("|\r\n");
    }
    hline();
    uart_puts("gen "); put_dec(gen);
    uart_puts("  alive "); put_dec(population(g));
    uart_puts("   \r\n");
}

static void life_demo(void)
{
    uint32_t *cur = buf_a, *nxt = buf_b;
    rng_state = 0x2545F491u;
    reseed(cur);
    cls();
    for (uint32_t gen = 0; gen < LIFE_GENS; gen++) {
        render(cur, gen);
        life_step(cur, nxt);
        int stuck = same(nxt, cur);              /* still life: start over */
        uint32_t *t = cur; cur = nxt; nxt = t;
        if (stuck) reseed(cur);
    }
}
#endif

/* =====================================================================
 * main
 * ===================================================================== */
int main(void)
{
    spin(PAUSE);
    for (int round = 0; DEMO_ROUNDS == 0 || round < DEMO_ROUNDS; round++) {
        banner();
#if ENABLE_TRAPS
        trap_demo();
#endif
        spin(PAUSE);
#if ENABLE_MANDEL
        mandelbrot();
        spin(PAUSE * 2u);
#endif
#if ENABLE_LIFE
        life_demo();
#endif
    }
    return 0;
}