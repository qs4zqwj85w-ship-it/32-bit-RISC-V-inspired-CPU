/*
 * CPU-side SDRAM integration test.
 * The test program itself executes from BRAM. It checks SDRAM loads/stores
 * through the CPU address decoder and sdram_adapter, then reports on UART.
 */
#include <stdint.h>

#pragma GCC optimize ("Os")

#define UART_DATA (*(volatile uint8_t  *)0x10000000u)
#define UART_STAT (*(volatile uint32_t *)0x10000004u)
#define SDRAM_BASE 0x00001000u

static void uart_putc(char c)
{
    while (UART_STAT & 1u) { }
    UART_DATA = (uint8_t)c;
}

static void uart_puts(const char *s)
{
    while (*s)
        uart_putc(*s++);
}

static void fail(const char *message)
{
    uart_puts("FAIL: ");
    uart_puts(message);
    uart_puts("\r\n");
    for (;;) { }
}

static void pass(const char *message)
{
    uart_puts("PASS: ");
    uart_puts(message);
    uart_puts("\r\n");
}

int main(void)
{
    volatile uint32_t *words = (volatile uint32_t *)SDRAM_BASE;
    volatile uint8_t *bytes;
    volatile uint8_t *u8;
    volatile int8_t *s8;
    volatile uint16_t *u16;
    volatile int16_t *s16;
    volatile uint32_t *p0;
    volatile uint32_t *p1;
    volatile uint32_t *p2;
    volatile uint32_t *plast;

    uart_puts("\r\nCPU SDRAM TEST START\r\n");
    uart_puts("Program is running from BRAM; test data uses SDRAM.\r\n");

    // Word access at the base.
    words[0] = 0x12345678u;
    if (words[0] != 0x12345678u)
        fail("word read/write at 0x00001000");
    pass("word read/write");

    // Word access at a separate location.
    words[1] = 0x89ABCDEFu;
    if (words[1] != 0x89ABCDEFu)
        fail("second word address/pattern");
    pass("different word address");

    // Byte store, byte load, and preservation of the other byte lanes.
    words[2] = 0x11223344u;
    bytes = (volatile uint8_t *)(SDRAM_BASE + 8u);
    bytes[1] = 0xA5u;
    if (bytes[1] != 0xA5u)
        fail("byte read/write");
    if (words[2] != 0x1122A544u)
        fail("byte store changed neighboring lanes");
    pass("byte access and lane preservation");

    // Halfword store in the upper half of a word.
    words[3] = 0x11223344u;
    u16 = (volatile uint16_t *)(SDRAM_BASE + 14u);
    *u16 = 0xBEEFu;
    if (*u16 != 0xBEEFu)
        fail("halfword read/write");
    if (words[3] != 0xBEEF3344u)
        fail("halfword store changed neighboring lanes");
    pass("halfword access and lane preservation");

    // Signed and unsigned byte loads.
    words[6] = 0u;
    u8 = (volatile uint8_t *)(SDRAM_BASE + 24u);
    s8 = (volatile int8_t *)(SDRAM_BASE + 24u);
    *u8 = 0x80u;
    if (*u8 != 0x80u)
        fail("unsigned byte load");
    if ((int32_t)*s8 != -128)
        fail("signed byte extension");
    pass("signed/unsigned byte loads");

    // Signed and unsigned halfword loads.
    words[7] = 0u;
    u16 = (volatile uint16_t *)(SDRAM_BASE + 30u);
    s16 = (volatile int16_t *)(SDRAM_BASE + 30u);
    *u16 = 0x8001u;
    if (*u16 != 0x8001u)
        fail("unsigned halfword load");
    if ((int32_t)*s16 != -32767)
        fail("signed halfword extension");
    if (words[7] != 0x80010000u)
        fail("upper halfword byte lanes");
    pass("signed/unsigned halfword loads");

    // Check that far-apart addresses do not alias and that the end of the
    // declared 8 MiB SDRAM window is decoded correctly.
    p0 = (volatile uint32_t *)0x00001000u;
    p1 = (volatile uint32_t *)0x00002000u;
    p2 = (volatile uint32_t *)0x00010000u;
    plast = (volatile uint32_t *)0x00800FFCu;

    *p0 = 0x0A0A0A0Au;
    *p1 = 0x1B1B1B1Bu;
    *p2 = 0x2C2C2C2Cu;
    *plast = 0x3D3D3D3Du;

    if (*p0 != 0x0A0A0A0Au ||
        *p1 != 0x1B1B1B1Bu ||
        *p2 != 0x2C2C2C2Cu ||
        *plast != 0x3D3D3D3Du)
        fail("address range/alias test");
    pass("separate addresses, including last SDRAM word");

        // Repeat PASS so it remains visible in the UART terminal.
    for (;;) {
        uart_puts("ALL SDRAM CPU TESTS PASSED\r\n");

        // Delay between messages to avoid flooding the terminal.
        for (volatile uint32_t delay = 0;
             delay < 500000u;
             delay++) {
        }
    }
}
