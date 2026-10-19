
#include <stdint.h>

#define UART_DATA (*(volatile uint8_t *)0x10000000u)
#define UART_STAT (*(volatile uint32_t *)0x10000004u)
#define MIE_BIT   (1u << 3)
static void delay(void)
{
    for (volatile uint32_t i = 0; i < 5000000; i++) ;   // roughly 5 seconds
}

static void uart_putc(char c)
{
    while (UART_STAT & 1u) {
        // Wait for transmitter to become available.
    }
    UART_DATA = (uint8_t)c;
}

static void uart_puts(const char *s)
{
    while (*s)
        uart_putc(*s++);
}

static void fail(const char *message)
{
    while (1) {
        uart_puts("FAIL: ");
        uart_puts(message);
        uart_puts("\r\n");
        delay();
    }
}

static inline uint32_t read_mstatus(void)
{
    uint32_t value;
    __asm__ volatile ("csrr %0, mstatus"
                      : "=r"(value) :: "memory");
    return value;
}

static inline void write_mstatus(uint32_t value)
{
    __asm__ volatile ("csrw mstatus, %0"
                      :: "r"(value) : "memory");
}

static inline uint32_t read_mcause(void)
{
    uint32_t value;
    __asm__ volatile ("csrr %0, mcause"
                      : "=r"(value) :: "memory");
    return value;
}

/*
 * Minimal trap handler:
 * advance past the ECALL/EBREAK instruction, then return.
 * Keep it in .text so the existing .text-only image conversion
 * includes the handler.
 */
__attribute__((naked, noinline, used, aligned(4), section(".text")))
void trap_handler(void)
{
    __asm__ volatile (
        "csrr t0, mepc\n"
        "addi t0, t0, 4\n"
        "csrw mepc, t0\n"
        "mret\n"
    );
}


int main(void)
{
    uint32_t old;
    const uint32_t mask = MIE_BIT;

    delay();

    uart_puts("\r\n=== CSR / Trap Smoke Test ===\r\n");

    // 1. CSRRW: read old value and write MIE = 1.
    write_mstatus(0);
    __asm__ volatile ("csrrw %0, mstatus, %1"
                      : "=r"(old) : "r"(mask) : "memory");

    if ((old & 8u) != 0u)
        fail("CSRRW: wrong old MIE");

    if ((read_mstatus() & 8u) == 0u)
        fail("CSRRW: MIE not set");

    uart_puts("PASS: CSRRW\r\n");



    // 2. CSRRS: set MIE using a register mask.
    write_mstatus(0);
    __asm__ volatile ("csrrs %0, mstatus, %1"
                      : "=r"(old) : "r"(mask) : "memory");

    if ((old & MIE_BIT) != 0 ||
        (read_mstatus() & MIE_BIT) == 0)
        fail("CSRRS");

    uart_puts("PASS: CSRRS\r\n");

    // 3. CSRRC: clear MIE using a register mask.
    __asm__ volatile ("csrrc %0, mstatus, %1"
                      : "=r"(old) : "r"(mask) : "memory");

    if ((old & MIE_BIT) == 0 ||
        (read_mstatus() & MIE_BIT) != 0)
        fail("CSRRC");

    uart_puts("PASS: CSRRC\r\n");

    // 4. CSRRWI: write MIE = 1 using immediate 8.
    write_mstatus(0);
    __asm__ volatile ("csrrwi %0, mstatus, 8"
                      : "=r"(old) :: "memory");

    if ((old & MIE_BIT) != 0 ||
        (read_mstatus() & MIE_BIT) == 0)
        fail("CSRRWI");

    uart_puts("PASS: CSRRWI\r\n");

    // 5. CSRRSI: set MIE using immediate mask 8.
    write_mstatus(0);
    __asm__ volatile ("csrrsi %0, mstatus, 8"
                      : "=r"(old) :: "memory");

    if ((old & MIE_BIT) != 0 ||
        (read_mstatus() & MIE_BIT) == 0)
        fail("CSRRSI");

    uart_puts("PASS: CSRRSI\r\n");

    // 6. CSRRCI: clear MIE using immediate mask 8.
    __asm__ volatile ("csrrci %0, mstatus, 8"
                      : "=r"(old) :: "memory");

    if ((old & MIE_BIT) == 0 ||
        (read_mstatus() & MIE_BIT) != 0)
        fail("CSRRCI");

    uart_puts("PASS: CSRRCI\r\n");

    // Point mtvec at our handler, not the default address 0x100.
    uintptr_t handler_address = (uintptr_t)&trap_handler;
    __asm__ volatile ("csrw mtvec, %0"
                      :: "r"(handler_address) : "memory");

    // 7. ECALL trap entry, MRET return, and MIE restoration.
    write_mstatus(0);
    __asm__ volatile ("csrsi mstatus, 8" ::: "memory");

    __asm__ volatile ("ecall" ::: "memory");

    if (read_mcause() != 11)
        fail("ECALL mcause");

    if ((read_mstatus() & MIE_BIT) == 0)
        fail("MRET did not restore MIE after ECALL");

    uart_puts("PASS: ECALL -> MRET\r\n");

    // 8. EBREAK trap entry and MRET return.
    __asm__ volatile ("ebreak" ::: "memory");

    if (read_mcause() != 3)
        fail("EBREAK mcause");

    if ((read_mstatus() & MIE_BIT) == 0)
        fail("MRET did not restore MIE after EBREAK");

    uart_puts("PASS: EBREAK -> MRET\r\n");
        uart_puts("PASS: EBREAK -> MRET\r\n");

    while (1) {
        uart_puts("=== ALL TESTS PASSED ===\r\n");
        delay();
    }
}
