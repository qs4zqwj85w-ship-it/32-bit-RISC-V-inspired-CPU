/*
 * main.c - a polar bear walking across the Arctic, drawn into the HDMI
 * framebuffer (360x240, RGB332, one byte per pixel).
 *
 * Needs RV32IM (uses the hardware multiplier: build with -march=rv32im).
 * Nothing relies on .data/.bss initialisation (everything is set at run time).
 *
 *   ANIMATE 0 (default): one still picture of the bear mid-stride.
 *   ANIMATE 1          : draws two strides into two framebuffers and flips
 *                        VIDEO_BASE between them so the bear appears to walk.
 *                        Needs RAM at FB_B (see below) and VIDEO_BASE to take
 *                        effect cleanly; if the picture glitches, use ANIMATE 0.
 *
 * Preview on a Mac/PC (writes bear_a.ppm / bear_b.ppm):
 *     gcc -O2 -DHOST_SIM -DANIMATE=1 main.c -o bear && ./bear
 */
#include <stdint.h>

/* Keep the code small whatever -O level the build script uses (GCC). */
#pragma GCC optimize ("Os")

#ifndef ANIMATE
#define ANIMATE 1
#endif

#define WIDTH   360
#define HEIGHT  240

#define FB_A    0x00101000u
#define FB_B    0x00117000u          /* FB_A + 0x16000 (a bit over 86400 bytes) */

#ifdef HOST_SIM
#include <stdio.h>
static uint8_t  sim_mem[0x16000 * 2];
static uint32_t sim_regs[2];
#define VIDEO_BASE  sim_regs[0]
#define VIDEO_CTRL  sim_regs[1]
#define FB_PTR(a)   (sim_mem + ((a) - FB_A))
#else
#define VIDEO_BASE  (*(volatile uint32_t *)0x10000010u)
#define VIDEO_CTRL  (*(volatile uint32_t *)0x10000014u)
#define FB_PTR(a)   ((uint8_t *)(a))
#endif

#define RGB332(r, g, b) \
    ((uint8_t)((((r) & 7u) << 5) | (((g) & 7u) << 2) | ((b) & 3u)))

/* Palette */
#define SKY1    RGB332(3, 5, 3)
#define SKY2    RGB332(4, 6, 3)
#define SKY3    RGB332(5, 6, 3)
#define SKY4    RGB332(6, 7, 3)
#define MTN_FAR RGB332(5, 6, 3)
#define MTN_NEAR RGB332(4, 5, 3)
#define SNOW1   RGB332(6, 7, 3)
#define SNOW2   RGB332(5, 7, 3)
#define SHADOW  RGB332(4, 6, 3)
#define FUR     RGB332(7, 7, 3)
#define FUR_SH  RGB332(6, 6, 3)
#define OUTLINE RGB332(3, 3, 2)
#define BLACK   RGB332(0, 0, 0)

static uint8_t *fb;                          /* framebuffer being drawn */

/* ---------------- primitives (no multiply, no divide) ---------------- */
static int absd(int a, int b) { return a > b ? a - b : b - a; }

static uint8_t *rowp(int y) { return fb + y * WIDTH; }

__attribute__((optimize("no-tree-loop-distribute-patterns")))
static void hline(int y, int x0, int x1, uint8_t c)
{
    if (y < 0 || y >= HEIGHT) return;
    if (x0 < 0) x0 = 0;
    if (x1 >= WIDTH) x1 = WIDTH - 1;
    uint8_t *p = rowp(y);
    for (int x = x0; x <= x1; x++) p[x] = c;
}

static void fill_ellipse(int cx, int cy, int rx, int ry, uint8_t c)
{
    int A = rx * rx, B = ry * ry;
    int AB = A * B;
    int hw = rx;                              /* half-width only shrinks as |dy| grows */
    for (int dy = 0; dy < ry; dy++) {         /* stop before the 1-pixel tip row */
        int t = dy * dy * A;
        while (hw > 0 && hw * hw * B + t > AB) hw--;
        hline(cy - dy, cx - hw, cx + hw, c);
        hline(cy + dy, cx - hw, cx + hw, c);
    }
}

/* A leg: slanted band from (xt,yt) down to (xb,yb), plus a paw. g = outline growth. */
static void leg(int xt, int yt, int xb, int yb, int hw, int g, uint8_t c)
{
    int dx  = absd(xb, xt);
    int dyy = yb - yt;                        /* > 0 */
    int sx  = (xb > xt) ? 1 : -1;
    int err = 0, x = xt;
    for (int y = yt; y <= yb; y++) {
        hline(y, x - hw - g, x + hw + g, c);
        err += dx;
        while (err >= dyy) { err -= dyy; x += sx; }
    }
    fill_ellipse(xb + 4, yb, hw + 5 + g, 7 + g, c);
}

/* ---------------- the bear ---------------- */
/* s = +1: near-front and far-rear legs forward; s = -1: the other pair.
 * g = growth for the outline pass. cfar = far legs, cmain = everything else. */
static void bear_parts(int s, int g, uint8_t cfar, uint8_t cmain, uint8_t cshade)
{
    int fwd = (s > 0);                        /* forward legs are lifted a little */

    /* far legs, behind the body */
    leg(215, 165, 220 - 18 * s, fwd ? 208 : 201, 12, g, cfar);   /* far front */
    leg(125, 165, 130 + 18 * s, fwd ? 201 : 208, 12, g, cfar);   /* far rear  */

    fill_ellipse(76, 138, 9 + g, 7 + g, cmain);                  /* tail */
    fill_ellipse(160, 152, 88 + g, 42 + g, cmain);               /* body */
    fill_ellipse(205, 135, 42 + g, 32 + g, cmain);               /* shoulder hump */
    fill_ellipse(160, 178, 66, 12, cshade);                      /* belly shade */

    /* near legs */
    leg(232, 165, 232 + 18 * s, fwd ? 201 : 208, 13, g, cmain);  /* near front */
    leg(112, 165, 118 - 18 * s, fwd ? 208 : 201, 13, g, cmain);  /* near rear  */

    /* neck, ear, head, muzzle */
    fill_ellipse(240, 148, 30 + g, 26 + g, cmain);
    fill_ellipse(258, 130, 9 + g, 9 + g, cmain);
    fill_ellipse(268, 152, 30 + g, 24 + g, cmain);
    fill_ellipse(296, 162, 22 + g, 13 + g, cmain);
}

/* ---------------- the scene ---------------- */
static void vline(int x, int y0, int y1, uint8_t c)
{
    uint8_t *p = rowp(y0) + x;
    for (int y = y0; y < y1; y++) { *p = c; p += WIDTH; }
}

static void draw_scene(uint32_t base, int s)
{
    fb = FB_PTR(base);

    /* sky bands */
    for (int y = 0; y < 150; y++)
        hline(y, 0, WIDTH - 1, y < 40 ? SKY1 : y < 80 ? SKY2 : y < 120 ? SKY3 : SKY4);

    /* two ranges of icy mountains: far (pale) then near */
    for (int x = 0; x < WIDTH; x++) {
        int r = 150, a;
        a =  76 + (absd(x,  70) >> 1); if (a < r) r = a;
        a =  92 + (absd(x, 190) >> 1); if (a < r) r = a;
        a =  84 + (absd(x, 320) >> 1); if (a < r) r = a;
        vline(x, r, 150, MTN_FAR);
        r = 150;
        a = 112 + (absd(x,  20) >> 1); if (a < r) r = a;
        a = 118 + (absd(x, 250) >> 1); if (a < r) r = a;
        vline(x, r, 150, MTN_NEAR);
    }

    /* snow */
    for (int y = 150; y < HEIGHT; y++)
        hline(y, 0, WIDTH - 1, y < 180 ? SNOW1 : SNOW2);

    /* shadow and footprints behind the bear */
    fill_ellipse(175, 212, 108, 8, SHADOW);
    fill_ellipse(22, 210, 7, 4, SHADOW);
    fill_ellipse(46, 224, 7, 4, SHADOW);
    fill_ellipse(70, 216, 7, 4, SHADOW);

    /* bear: outline pass (everything grown by 3 px), then the fur */
    bear_parts(s, 3, OUTLINE, OUTLINE, OUTLINE);
    bear_parts(s, 0, FUR_SH, FUR, FUR_SH);

    /* face */
    fill_ellipse(278, 147, 3, 3, BLACK);                         /* eye  */
    fill_ellipse(316, 158, 5, 4, BLACK);                         /* nose */
}

#ifndef HOST_SIM
static void delay(void) { for (volatile uint32_t i = 0; i < 1000000u; i++) ; }
#endif

int main(void)
{
#ifdef HOST_SIM
    (void)sim_regs;
    draw_scene(FB_A, 1);
    FILE *f = fopen("bear_a.raw", "wb"); fwrite(FB_PTR(FB_A), 1, WIDTH * HEIGHT, f); fclose(f);
    draw_scene(FB_B, -1);
    f = fopen("bear_b.raw", "wb"); fwrite(FB_PTR(FB_B), 1, WIDTH * HEIGHT, f); fclose(f);
    return 0;
#else
    VIDEO_CTRL = 0;
    draw_scene(FB_A, 1);
#if ANIMATE
    draw_scene(FB_B, -1);
#endif
    VIDEO_BASE = FB_A;
    VIDEO_CTRL = 1;

    for (;;) {
#if ANIMATE
        delay();
        VIDEO_BASE = FB_B;
        delay();
        VIDEO_BASE = FB_A;
#else
        __asm__ volatile ("nop");
#endif
    }
#endif
}
