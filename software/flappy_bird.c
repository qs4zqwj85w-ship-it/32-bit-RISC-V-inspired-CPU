/*
 * flappy_bird.c - Flappy Bird for the Tang Nano 20K multi-cycle RV32I CPU.
 *
 * Display : 360 x 240 RGB332 framebuffer in external SDRAM, scanned out by
 *           the framebuffer controller over the DVI/HDMI pipeline. Each
 *           framebuffer byte covers 2x2 screen pixels, so the game surface
 *           is 360 x 240 logical pixels.
 * Input   : the on-board button only. It is debounced in hardware and reads
 *           as bit 0 of the GPIO register. Press = flap.
 *
 * Renderer idea:
 *   A pipe is a solid vertical bar, so scrolling it left by N pixels only
 *   changes the N columns at its leading edge and the N columns it leaves
 *   behind. Every interior column is identical before and after the move.
 *   That keeps a frame at a few thousand byte stores instead of a full
 *   86,400-store redraw, which matters because each store is a real SDRAM
 *   byte transaction through the CPU.
 *
 * Physics:
 *   Semi-implicit Euler, one update per frame. A flap sets the velocity to
 *   FLAP_V and gravity adds GRAVITY each frame, so the rise from one flap is
 *   the triangular sum 7+6+...+1 = 28 pixels. That is exactly 2 x the 14
 *   pixel bird height, and 40% of the 70 pixel pipe opening - the ratios the
 *   original game uses.
 *
 * Build:  ./run.sh                          (this file, then flash the board)
 *         SRC=software/main.c ./run.sh      (to build a different demo)
 *
 * Tuning: FRAME_DELAY sets the frame rate, SCROLL_SPEED / GRAVITY / FLAP_V
 * set the difficulty. The game logic is frame-based, so if the board runs
 * slower than expected everything slows down together.
 */

#include <stdint.h>

#pragma GCC optimize ("Os")

/* =====================================================================
 * Memory-mapped hardware
 * ===================================================================== */

#define UART_DATA   (*(volatile uint8_t  *)0x10000000u)
#define UART_STAT   (*(volatile uint32_t *)0x10000004u)

#define VIDEO_BASE  (*(volatile uint32_t *)0x10000010u)   /* fb CPU address */
#define VIDEO_CTRL  (*(volatile uint32_t *)0x10000014u)   /* bit 0 enable   */

#define BUTTON      (*(volatile uint32_t *)0x1000001Cu)   /* bit 0 pressed  */

/*
 * Framebuffer image address. This is a CPU-visible SDRAM byte address, not a
 * physical SDRAM offset: cpu_fpga_top subtracts 0x1000 from the VIDEO_BASE
 * register before handing it to the framebuffer controller, exactly as
 * sdram_adapter does for CPU loads and stores. VIDEO_BASE must therefore be
 * set to this same value. 0x00101000 is the project's established framebuffer
 * base (see software/hdmi_demo.c), i.e. a physical SDRAM offset of 0x100000.
 */
#define FB_ADDR     0x00101000u
#define FB          ((volatile uint8_t *)FB_ADDR)

/* =====================================================================
 * Screen and game constants
 * ===================================================================== */

#define SCR_W       360
#define SCR_H       240
#define GROUND_H    28
#define PLAY_H      (SCR_H - GROUND_H)     /* 212 */

/* RGB332: 3 bits red, 3 bits green, 2 bits blue. */
#define RGB332(r, g, b) \
    ((uint8_t)((((r) & 7u) << 5) | (((g) & 7u) << 2) | ((b) & 3u)))

#define C_SKY       RGB332(3, 6, 7)
#define C_GRASS     RGB332(1, 7, 0)
#define C_GRASS_DK  RGB332(0, 5, 0)
#define C_DIRT      RGB332(5, 3, 0)
#define C_DIRT_DK   RGB332(3, 2, 0)
#define C_BIRD      RGB332(7, 7, 0)
#define C_BELLY     RGB332(7, 7, 2)
#define C_WING      RGB332(6, 4, 0)
#define C_BEAK      RGB332(7, 4, 0)
#define C_BEAK_DK   RGB332(5, 2, 0)
#define C_EYE       RGB332(7, 7, 3)
#define C_PUPIL     RGB332(0, 0, 0)
#define C_TEXT      RGB332(7, 7, 3)
#define C_DARK      RGB332(0, 0, 1)

/* Pipe greens: body, brighter cap band, dark outline on the cap edge. */
#define C_PIPE      RGB332(1, 5, 1)
#define C_PIPE_DK   RGB332(0, 2, 0)
#define C_PIPE_CAP  RGB332(1, 7, 1)

#define PIPE_N        3
#define PIPE_W        36
#define PIPE_GAP      70
#define PIPE_SPACING  132
#define PIPE_LIP_W    5
#define PIPE_TOP_MIN  20
#define PIPE_RELOAD   (PIPE_N * PIPE_SPACING)

/* The bird is 2 x 7 pixels bigger than a 14x10 sprite and 80% more area. */
#define BIRD_W   16
#define BIRD_H   14
#define BIRD_X   80

/* Collision box is inset from the sprite, as in the original game. */
#define BIRD_HIT_X   (BIRD_X + 2)
#define BIRD_HIT_W   (BIRD_W - 4)
#define BIRD_HIT_TOP 2
#define BIRD_HIT_BOT (BIRD_H - 2)

#define GRAVITY      1
#define FLAP_V     (-8)                 /* rise = 7+6+...+1 = 28 px */
#define MAX_FALL     6

#define SCROLL_SPEED 2

/*
 * Busy-wait iterations between frames. The generated loop costs about 34
 * cycles per iteration on this FSM (lw 7, bgeu 4, lw 7, addi 5, sw 5, jal 6),
 * so 23000 iterations is roughly 29 ms at 27 MHz. With the ~5 ms of
 * rendering per frame that targets ~30 fps. This is an estimate from the
 * instruction sequence, not a measured frame time: raise it to slow the game
 * down, lower it to speed it up.
 */
#define FRAME_DELAY  23000u

#define ST_READY 0
#define ST_PLAY  1
#define ST_OVER  2

/* =====================================================================
 * Game state
 * ===================================================================== */

static int16_t  pipe_x[PIPE_N];
static uint8_t  gap_y[PIPE_N];
static uint8_t  scored[PIPE_N];

static int      bird_y = 96;
static int      bird_v = 0;

static int      score = 0;
static int      state = ST_READY;
static uint32_t tick  = 0;
static uint32_t rng   = 0x2F6E2B1u;

/* 3x5 font: digits 0-9, then G A M E O V R S C and space. */
static const uint8_t font3x5[] = {
    7, 5, 5, 5, 7,   /* 0 */
    2, 6, 2, 2, 7,   /* 1 */
    7, 1, 7, 4, 7,   /* 2 */
    7, 1, 7, 1, 7,   /* 3 */
    5, 5, 7, 1, 1,   /* 4 */
    7, 4, 7, 1, 7,   /* 5 */
    7, 4, 7, 5, 7,   /* 6 */
    7, 1, 1, 1, 1,   /* 7 */
    7, 5, 7, 5, 7,   /* 8 */
    7, 5, 7, 1, 7,   /* 9 */
    7, 4, 5, 5, 7,   /* G */
    7, 5, 7, 5, 5,   /* A */
    5, 7, 7, 5, 5,   /* M */
    7, 4, 6, 4, 7,   /* E */
    7, 5, 5, 5, 7,   /* O */
    5, 5, 5, 5, 2,   /* V */
    6, 5, 6, 5, 5,   /* R */
    7, 4, 7, 1, 7,   /* S */
    7, 4, 4, 4, 7,   /* C */
    0, 0, 0, 0, 0    /* space */
};

/*
 * Bird silhouette, 16 wide x 14 tall, one 16-bit row per line, bit 15 is the
 * leftmost pixel. Round body, big beak at the right, wing on the left.
 */
static const uint16_t bird_rows[BIRD_H] = {
    0x0FE0, 0x3FF8, 0x7FFC, 0xFFFE, 0xFFFF, 0xFFFF, 0xFFFF,
    0x7FFF, 0x7FFF, 0x3FFE, 0x1FFC, 0x0FF8, 0x07F0, 0x03E0
};

/* 32-bit xorshift; only shifts and xors, so no multiplier is emitted. */
static uint32_t rng_next(void)
{
    rng ^= rng << 13;
    rng ^= rng >> 17;
    rng ^= rng << 5;
    return rng;
}

/* =====================================================================
 * UART
 * ===================================================================== */

static void uart_putc(char c)
{
    while (UART_STAT & 1u)
        ;
    UART_DATA = (uint8_t)c;
}

static void uart_puts(const char *s)
{
    while (*s)
        uart_putc(*s++);
}

/* Three-digit decimal without division. */
static void uart_score(uint32_t v)
{
    int d;

    if (v > 999u)
        v = 999u;

    d = 0;
    while (v >= 100u) { v -= 100u; d++; }
    uart_putc((char)('0' + d));

    d = 0;
    while (v >= 10u) { v -= 10u; d++; }
    uart_putc((char)('0' + d));

    uart_putc((char)('0' + (int)v));
}

/* =====================================================================
 * Framebuffer primitives
 * ===================================================================== */

/* Row y is at FB + y * 360, built with shifts to avoid a multiplier. */
static volatile uint8_t *row_ptr(int y)
{
    return FB + ((uint32_t)y << 8) + ((uint32_t)y << 6)
              + ((uint32_t)y << 5) + ((uint32_t)y << 3);
}

static void fill_rect(int x, int y, int w, int h, uint8_t c)
{
    int yy, xx;

    if (w <= 0 || h <= 0)
        return;

    for (yy = 0; yy < h; yy++) {
        volatile uint8_t *p = row_ptr(y + yy) + x;
        for (xx = 0; xx < w; xx++)
            p[xx] = c;
    }
}

/* =====================================================================
 * Text
 * ===================================================================== */

static void draw_glyph(int x, int y, int idx, uint8_t c)
{
    const uint8_t *g = font3x5 + ((idx << 2) + idx);   /* idx * 5 */
    int r, col;

    for (r = 0; r < 5; r++) {
        uint8_t bits = g[r];
        for (col = 0; col < 3; col++) {
            if (bits & (4 >> col))
                fill_rect(x + (col << 1), y + (r << 1), 2, 2, c);
        }
    }
}

static void draw_text(int x, int y, const uint8_t *ids, int n)
{
    int i;

    for (i = 0; i < n; i++)
        draw_glyph(x + (i << 3), y, ids[i], C_TEXT);
}

/* Score lives on the ground strip, which pipes never cover. */
static void draw_score(void)
{
    int v = score;
    int h = 0, t = 0;

    if (v > 999)
        v = 999;

    while (v >= 100) { v -= 100; h++; }
    while (v >= 10)  { v -= 10;  t++; }

    fill_rect(6, 216, 26, 11, C_DIRT);
    draw_glyph(8,  217, h, C_TEXT);
    draw_glyph(16, 217, t, C_TEXT);
    draw_glyph(24, 217, v, C_TEXT);
}

/* =====================================================================
 * Background
 * ===================================================================== */

static void draw_ground(void)
{
    fill_rect(0, PLAY_H, SCR_W, GROUND_H, C_DIRT);
    fill_rect(0, PLAY_H, SCR_W, 3, C_GRASS);
    fill_rect(0, PLAY_H + 3, SCR_W, 2, C_GRASS_DK);
    fill_rect(0, PLAY_H + 12, SCR_W, 2, C_DIRT_DK);
}

/* =====================================================================
 * Pipes
 * ===================================================================== */

/*
 * Colour of one pipe pixel at row y, for a gap starting at g. Only the row
 * matters: the renderer repaints just the columns a pipe gains or loses, so
 * every column keeps the colour it was painted with for the whole scroll.
 * A colour that varied with the column offset would therefore freeze each
 * column at its value at entry time and smear the pipe into vertical stripes.
 * Rows never move, so cap bands and their outlines are safe.
 */
static uint8_t pipe_px(int y, int g)
{
    int b = g + PIPE_GAP;

    if (y < g - PIPE_LIP_W || y >= b + PIPE_LIP_W)
        return C_PIPE;
    if (y >= g && y < b)
        return C_SKY;
    if (y == g - PIPE_LIP_W || y == b + PIPE_LIP_W - 1)
        return C_PIPE_DK;
    return C_PIPE_CAP;
}

static void pipe_col(int x, int g)
{
    volatile uint8_t *p;
    int y;

    if (x < 0 || x >= SCR_W)
        return;

    p = FB + x;
    for (y = 0; y < PLAY_H; y++) {
        *p = pipe_px(y, g);
        p += SCR_W;
    }
}

/* Colour of the static scene at a point, used to erase the bird. */
static uint8_t bg_at(int x, int y)
{
    int i;

    if (y >= PLAY_H) {
        if (y < PLAY_H + 3)
            return C_GRASS;
        if (y < PLAY_H + 5)
            return C_GRASS_DK;
        if (y >= PLAY_H + 12 && y < PLAY_H + 14)
            return C_DIRT_DK;
        return C_DIRT;
    }

    for (i = 0; i < PIPE_N; i++) {
        if (x >= pipe_x[i] && x < pipe_x[i] + PIPE_W)
            return pipe_px(y, gap_y[i]);
    }

    return C_SKY;
}

static void scroll_pipes(void)
{
    int i, k;

    for (i = 0; i < PIPE_N; i++) {
        int x0 = pipe_x[i];
        int g  = gap_y[i];

        /* Columns the pipe is leaving become sky again. */
        for (k = 0; k < SCROLL_SPEED; k++) {
            int x = x0 + PIPE_W - 1 - k;

            if (x >= 0 && x < SCR_W) {
                volatile uint8_t *p = FB + x;
                int y;

                for (y = 0; y < PLAY_H; y++) {
                    *p = C_SKY;
                    p += SCR_W;
                }
            }
        }

        pipe_x[i] = (int16_t)(x0 - SCROLL_SPEED);

        /* Columns it is entering are drawn with its gap. */
        for (k = 0; k < SCROLL_SPEED; k++)
            pipe_col(pipe_x[i] + k, g);

        /* Recycle once the whole pipe has passed the left edge. */
        if (pipe_x[i] + PIPE_W <= 0) {
            int nx;

            pipe_x[i] = (int16_t)(pipe_x[i] + PIPE_RELOAD);
            gap_y[i]  = (uint8_t)(PIPE_TOP_MIN + (rng_next() & 63u));
            scored[i] = 0;

            /* Normally off screen; repaint fully if it landed on screen. */
            for (nx = pipe_x[i]; nx < pipe_x[i] + PIPE_W; nx++)
                pipe_col(nx, gap_y[i]);
        }

        if (!scored[i] && pipe_x[i] + PIPE_W < BIRD_X) {
            scored[i] = 1;
            score++;
            draw_score();
        }
    }
}

static int bird_hits(void)
{
    int i;

    /* Ground and ceiling use the full sprite so it never sinks into them. */
    if (bird_y + BIRD_H >= PLAY_H)
        return 1;

    for (i = 0; i < PIPE_N; i++) {
        if (BIRD_HIT_X + BIRD_HIT_W > pipe_x[i] &&
            BIRD_HIT_X < pipe_x[i] + PIPE_W) {
            if (bird_y + BIRD_HIT_TOP < gap_y[i] ||
                bird_y + BIRD_HIT_BOT > gap_y[i] + PIPE_GAP)
                return 1;
        }
    }

    return 0;
}

/* =====================================================================
 * Bird
 * ===================================================================== */

static void erase_bird(int y)
{
    int yy, xx;

    for (yy = 0; yy < BIRD_H; yy++) {
        volatile uint8_t *p = row_ptr(y + yy) + BIRD_X;
        for (xx = 0; xx < BIRD_W; xx++)
            p[xx] = bg_at(BIRD_X + xx, y + yy);
    }
}

static void draw_bird(void)
{
    int y, x;
    int wing = 6 + (int)((tick >> 2) & 1u) * 2;   /* wing up or down */

    for (y = 0; y < BIRD_H; y++) {
        volatile uint8_t *p = row_ptr(bird_y + y) + BIRD_X;
        uint16_t bits = bird_rows[y];
        int py = bird_y + y;

        for (x = 0; x < BIRD_W; x++) {
            uint8_t c;

            if (!(bits & (0x8000u >> x))) {
                c = bg_at(BIRD_X + x, py);
            } else if (x == 11 && y == 4) {
                c = C_PUPIL;
            } else if (x >= 9 && x <= 11 && y >= 3 && y <= 4) {
                c = C_EYE;
            } else if (x >= 13 && y >= 5 && y <= 7) {
                c = (y == 7) ? C_BEAK_DK : C_BEAK;
            } else if (x >= 3 && x <= 7 && y >= wing && y <= wing + 2) {
                c = C_WING;
            } else if (x >= 2 && x <= 6 && y >= 9 && y <= 11) {
                c = C_BELLY;
            } else {
                c = C_BIRD;
            }

            p[x] = c;
        }
    }
}

/* =====================================================================
 * Game flow
 * ===================================================================== */

static void draw_banner(void)
{
    static const uint8_t msg[] = { 10, 11, 12, 13, 19, 14, 15, 13, 16 };

    fill_rect(136, 88, 88, 26, C_DARK);
    draw_text(145, 96, msg, 9);
}

static void reset_game(void)
{
    int i;
    int x = 400;                 /* first pipe starts off screen */

    fill_rect(0, 0, SCR_W, PLAY_H, C_SKY);
    draw_ground();

    score = 0;
    draw_score();

    bird_y = 96;
    bird_v = 0;
    state  = ST_READY;

    for (i = 0; i < PIPE_N; i++) {
        pipe_x[i] = (int16_t)x;
        gap_y[i]  = (uint8_t)(PIPE_TOP_MIN + (rng_next() & 63u));
        scored[i] = 0;
        x += PIPE_SPACING;
    }
}

static void game_over(void)
{
    state = ST_OVER;
    draw_banner();

    uart_puts("\r\nGAME OVER  SCORE ");
    uart_score((uint32_t)score);
    uart_puts("\r\n");
}

static void frame_delay(void)
{
    volatile uint32_t i;

    for (i = 0; i < FRAME_DELAY; i++)
        ;
}

/* =====================================================================
 * Main loop
 * ===================================================================== */

int main(void)
{
    int prev_button = 0;
    int prev_bird_y;

    uart_puts("\r\nFLAPPY BIRD\r\npress the button to flap\r\n");

    VIDEO_CTRL = 0;
    VIDEO_BASE = FB_ADDR;

    reset_game();

    VIDEO_CTRL = 1;              /* start scanout once the image is ready */

    prev_bird_y = bird_y;

    for (;;) {
        int button = (int)(BUTTON & 1u);
        int press  = button && !prev_button;
        prev_button = button;

        if (state == ST_READY) {
            if (press) {
                state  = ST_PLAY;
                bird_v = FLAP_V;
            } else if (bird_y != 96 + (int)((tick >> 3) & 7u)) {
                bird_y = 96 + (int)((tick >> 3) & 7u);
            }
        } else if (state == ST_PLAY) {
            if (press)
                bird_v = FLAP_V;

            bird_v += GRAVITY;
            if (bird_v > MAX_FALL)
                bird_v = MAX_FALL;

            bird_y += bird_v;
            if (bird_y < 0) {
                bird_y = 0;
                bird_v = 0;
            }

            scroll_pipes();

            if (bird_hits()) {
                if (bird_y + BIRD_H > PLAY_H)
                    bird_y = PLAY_H - BIRD_H;
                game_over();
            }
        } else {
            /* Dead: let the bird drop, restart on the next press. */
            if (bird_y + BIRD_H < PLAY_H) {
                bird_v += GRAVITY;
                if (bird_v > MAX_FALL)
                    bird_v = MAX_FALL;

                bird_y += bird_v;
                if (bird_y + BIRD_H > PLAY_H)
                    bird_y = PLAY_H - BIRD_H;
            }

            if (press) {
                reset_game();
                prev_bird_y = bird_y;
            }
        }

        erase_bird(prev_bird_y);
        draw_bird();
        prev_bird_y = bird_y;

        tick++;
        frame_delay();
    }
}
