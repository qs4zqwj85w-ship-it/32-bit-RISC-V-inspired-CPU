
#include <stdint.h>

#define WIDTH  360u
#define HEIGHT 240u

#define FB_ADDR       0x00101000u
#define VIDEO_BASE    (*(volatile uint32_t *)0x10000010u)
#define VIDEO_CTRL    (*(volatile uint32_t *)0x10000014u)

#define RGB332(r, g, b) \
    ((uint8_t)((((r) & 7u) << 5) | (((g) & 7u) << 2) | ((b) & 3u)))

static uint8_t * const fb = (uint8_t *)FB_ADDR;

// --------------------------------------------------
// Drawing primitives
// --------------------------------------------------

static void draw_rect(unsigned x0, unsigned y0,
                      unsigned x1, unsigned y1,
                      uint8_t color) {
    if (x0 >= WIDTH || y0 >= HEIGHT)
        return;

    if (x1 > WIDTH)  x1 = WIDTH;
    if (y1 > HEIGHT) y1 = HEIGHT;

    unsigned offset = (y0 << 8) + (y0 << 6)
                    + (y0 << 5) + (y0 << 3) + x0;

    uint8_t *row = fb + offset;

    for (unsigned y = y0; y < y1; y++) {
        for (unsigned x = x0; x < x1; x++)
            row[x - x0] = color;

        row += WIDTH;
    }
}

// --------------------------------------------------
// Color palette
// --------------------------------------------------

#define SKY       RGB332(3, 6, 7)
#define SKY_LIGHT RGB332(5, 7, 7)

#define SNOW      RGB332(7, 7, 7)
#define SNOW_BLUE RGB332(5, 6, 7)
#define ICE       RGB332(3, 5, 7)
#define ICE_DARK  RGB332(2, 4, 6)

#define BEAR      RGB332(7, 7, 7)
#define BEAR_SHADE RGB332(5, 6, 7)
#define BEAR_DARK RGB332(3, 4, 5)

#define BLACK     RGB332(0, 0, 0)
#define NOSE      RGB332(1, 1, 1)

// --------------------------------------------------
// Background
// --------------------------------------------------

static void draw_background(void) {
    // Sky
    draw_rect(0, 0, WIDTH, 185, SKY);

    // Distant pale clouds
    draw_rect(35, 35, 85, 40, SKY_LIGHT);
    draw_rect(55, 30, 105, 36, SKY_LIGHT);

    draw_rect(225, 55, 280, 60, SKY_LIGHT);
    draw_rect(245, 49, 295, 55, SKY_LIGHT);

    // Distant ice formations
    draw_rect(65, 157, 105, 181, ICE);
    draw_rect(75, 148, 95, 157, ICE);
    draw_rect(82, 142, 90, 148, SNOW_BLUE);

    draw_rect(265, 161, 310, 181, ICE);
    draw_rect(277, 151, 298, 161, ICE);
    draw_rect(285, 145, 291, 151, SNOW_BLUE);

    // Snowy ground
    draw_rect(0, 185, WIDTH, HEIGHT, SNOW);

    // Foreground ice patches
    draw_rect(15, 205, 95, 208, SNOW_BLUE);
    draw_rect(120, 218, 205, 221, SNOW_BLUE);
    draw_rect(250, 201, 340, 204, SNOW_BLUE);

    // Small ice crystals
    draw_rect(30, 225, 34, 231, ICE);
    draw_rect(34, 221, 38, 231, ICE);

    draw_rect(315, 215, 319, 222, ICE);
    draw_rect(319, 211, 323, 222, ICE);
}

// --------------------------------------------------
// Restore the background behind the bear
// --------------------------------------------------

static void erase_bear(unsigned x) {
    unsigned right = x + 58;

    if (right > WIDTH)
        right = WIDTH;

    draw_rect(x, 135, right, 185, SKY);
    draw_rect(x, 185, right, 205, SNOW);

    // Restore distant scenery if the bear passed over it.
    if (x < 105 && right > 65) {
        draw_rect(65, 157, 105, 181, ICE);
        draw_rect(75, 148, 95, 157, ICE);
        draw_rect(82, 142, 90, 148, SNOW_BLUE);
    }

    if (x < 310 && right > 265) {
        draw_rect(265, 161, 310, 181, ICE);
        draw_rect(277, 151, 298, 161, ICE);
        draw_rect(285, 145, 291, 151, SNOW_BLUE);
    }
}

// --------------------------------------------------
// Polar bear sprite
// --------------------------------------------------

static void draw_bear(unsigned x, unsigned phase) {

    // Legs: alternate positions to create a walking cycle.
    if (phase == 0 || phase == 2) {
        // Left leg forward
        draw_rect(x + 15, 174, x + 24, 195, BEAR);
        draw_rect(x + 11, 192, x + 25, 200, BEAR_SHADE);

        // Right leg backward
        draw_rect(x + 37, 174, x + 44, 191, BEAR);
        draw_rect(x + 34, 188, x + 47, 196, BEAR_SHADE);
    } else {
        // Left leg backward
        draw_rect(x + 15, 174, x + 23, 191, BEAR);
        draw_rect(x + 12, 188, x + 25, 196, BEAR_SHADE);

        // Right leg forward
        draw_rect(x + 36, 174, x + 45, 195, BEAR);
        draw_rect(x + 34, 192, x + 48, 200, BEAR_SHADE);
    }

    // Feet details
    draw_rect(x + 14, 197, x + 24, 200, BEAR_DARK);
    draw_rect(x + 37, 197, x + 47, 200, BEAR_DARK);

    // Arms: swing opposite to the legs.
    if (phase == 0 || phase == 2) {
        draw_rect(x + 8, 157, x + 17, 177, BEAR_SHADE);
        draw_rect(x + 42, 157, x + 51, 174, BEAR);
    } else {
        draw_rect(x + 8, 157, x + 17, 174, BEAR);
        draw_rect(x + 42, 157, x + 51, 177, BEAR_SHADE);
    }

    // Main body
    draw_rect(x + 10, 151, x + 48, 180, BEAR);

    // Belly shading
    draw_rect(x + 20, 163, x + 42, 177, BEAR_SHADE);

    // Back shading
    draw_rect(x + 10, 155, x + 15, 174, BEAR_DARK);

    // Neck and head
    draw_rect(x + 32, 145, x + 51, 166, BEAR);
    draw_rect(x + 39, 150, x + 54, 164, BEAR);

    // Ears
    draw_rect(x + 34, 140, x + 41, 148, BEAR);
    draw_rect(x + 45, 141, x + 52, 148, BEAR_DARK);

    // Ear highlights
    draw_rect(x + 36, 142, x + 39, 145, BEAR_SHADE);

    // Muzzle
    draw_rect(x + 47, 156, x + 57, 164, SNOW_BLUE);
    draw_rect(x + 51, 155, x + 57, 161, BEAR_SHADE);

    // Nose
    draw_rect(x + 54, 156, x + 58, 160, NOSE);

    // Eye
    draw_rect(x + 47, 150, x + 50, 153, BLACK);

    // Tail
    draw_rect(x + 5, 158, x + 12, 165, BEAR);
    draw_rect(x + 3, 160, x + 7, 164, BEAR_SHADE);
}

// --------------------------------------------------
// Main animation
// --------------------------------------------------

int main(void) {
    VIDEO_CTRL = 0;

    draw_background();

    unsigned bear_x = 10;
    unsigned phase = 0;

    // Initial frame
    draw_bear(bear_x, phase);

    VIDEO_BASE = FB_ADDR;
    VIDEO_CTRL = 1;

    while (1) {

        // Wait between animation frames.
        // Volatile prevents the compiler from removing the loop.
        for (volatile unsigned delay = 0;
             delay < 180000;
             delay++) {
        }

        // Erase previous sprite
        erase_bear(bear_x);

        // Move bear
        bear_x += 3;

        if (bear_x > 305)
            bear_x = 5;

        // Advance walking animation
        phase++;

        if (phase == 4)
            phase = 0;

        // Draw new frame
        draw_bear(bear_x, phase);
    }

    return 0;
}
