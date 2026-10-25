#include <stdint.h>

/*
 * Bare-metal RV32IM integration test for the custom CPU.
 *
 * The test emits raw M-extension encodings with GNU assembler's .insn
 * directive so the surrounding C code can still be compiled for RV32I.
 * This prevents the compiler from silently using M instructions for its
 * own C arithmetic, which would make it harder to isolate decoder/datapath
 * failures.
 */

#define UART_DATA (*(volatile uint32_t *)0x10000000u)
#define UART_STAT (*(volatile uint32_t *)0x10000004u)

static uint32_t tests_run;
static uint32_t tests_failed;

static void uart_putc(char c)
{
    /* UART_STAT bit 0 is 1 while the transmitter is busy. */
    while ((UART_STAT & 1u) != 0u) {
        /* Wait for the previous character to finish. */
    }
    UART_DATA = (uint32_t)(uint8_t)c;
}

static void uart_puts(const char *s)
{
    while (*s != '\0') {
        uart_putc(*s++);
    }
}

static void uart_put_hex32(uint32_t value)
{
    static const char hex_digits[] = "0123456789ABCDEF";
    int shift;

    uart_puts("0x");
    for (shift = 28; shift >= 0; shift -= 4) {
        uart_putc(hex_digits[(value >> shift) & 0xFu]);
    }
}

static void check_result(const char *name, uint32_t actual, uint32_t expected)
{
    ++tests_run;

    if (actual == expected) {
        uart_puts("PASS: ");
        uart_puts(name);
        uart_puts("\r\n");
    } else {
        ++tests_failed;
        uart_puts("FAIL: ");
        uart_puts(name);
        uart_puts(" actual=");
        uart_put_hex32(actual);
        uart_puts(" expected=");
        uart_put_hex32(expected);
        uart_puts("\r\n");
    }
}

/*
 * R-type encoding: opcode=0x33, funct7=1, funct3=F3.
 * Register constraints intentionally use normal input/output operands:
 * an R-type instruction may legally have rd equal to rs1 or rs2.
 */
#define M_INSN(F3, OUT, A, B)                                             \
    __asm__ volatile (                                                    \
        ".insn r 0x33, " #F3 ", 1, %0, %1, %2"                           \
        : "=r" (OUT)                                                      \
        : "r" (A), "r" (B)                                               \
        : "memory")

static inline uint32_t m_mul(uint32_t a, uint32_t b)
{
    uint32_t result;
    M_INSN(0, result, a, b);
    return result;
}

static inline uint32_t m_mulh(uint32_t a, uint32_t b)
{
    uint32_t result;
    M_INSN(1, result, a, b);
    return result;
}

static inline uint32_t m_mulhsu(uint32_t a, uint32_t b)
{
    uint32_t result;
    M_INSN(2, result, a, b);
    return result;
}

static inline uint32_t m_mulhu(uint32_t a, uint32_t b)
{
    uint32_t result;
    M_INSN(3, result, a, b);
    return result;
}

static inline uint32_t m_div(uint32_t a, uint32_t b)
{
    uint32_t result;
    M_INSN(4, result, a, b);
    return result;
}

static inline uint32_t m_divu(uint32_t a, uint32_t b)
{
    uint32_t result;
    M_INSN(5, result, a, b);
    return result;
}

static inline uint32_t m_rem(uint32_t a, uint32_t b)
{
    uint32_t result;
    M_INSN(6, result, a, b);
    return result;
}

static inline uint32_t m_remu(uint32_t a, uint32_t b)
{
    uint32_t result;
    M_INSN(7, result, a, b);
    return result;
}

int main(void)
{
    uint32_t chain_mul;
    uint32_t chain_div;
    uint32_t chain_rem;
    uint32_t dependent_add;

    uart_puts("\r\n=== RV32IM CPU integration test ===\r\n");

    /* Multiplication: all four funct3 operations. */
    check_result("MUL low word", m_mul(0xFFFFFFF0u, 16u),
                 0xFFFFFF00u);

    /* Signed -2147483648 * -1 = 2147483648; high word is zero. */
    check_result("MULH signed x signed", m_mulh(0x80000000u, 0xFFFFFFFFu),
                 0x00000000u);

    /* Signed -2147483648 * unsigned 0xFFFFFFFF: high word 0x80000000. */
    check_result("MULHSU signed x unsigned",
                 m_mulhsu(0x80000000u, 0xFFFFFFFFu), 0x80000000u);

    /* (2^32-1)^2 = 0xFFFFFFFE00000001. */
    check_result("MULHU unsigned x unsigned",
                 m_mulhu(0xFFFFFFFFu, 0xFFFFFFFFu), 0xFFFFFFFEu);

    /* Signed and unsigned division/remainder. */
    check_result("DIV -20 / 3", m_div(0xFFFFFFECu, 3u), 0xFFFFFFFAu);
    check_result("DIV 20 / -3", m_div(20u, 0xFFFFFFFDu), 0xFFFFFFFAu);
    check_result("DIVU UINT_MAX / 2", m_divu(0xFFFFFFFFu, 2u),
                 0x7FFFFFFFu);
    check_result("REM -20 % 3", m_rem(0xFFFFFFECu, 3u), 0xFFFFFFFEu);
    check_result("REM 20 % -3", m_rem(20u, 0xFFFFFFFDu), 2u);
    check_result("REMU UINT_MAX % 10", m_remu(0xFFFFFFFFu, 10u), 5u);

    /* Division by zero: quotient is all ones; remainder is dividend. */
    check_result("DIV by zero", m_div(0x12345678u, 0u), 0xFFFFFFFFu);
    check_result("DIVU by zero", m_divu(0x12345678u, 0u), 0xFFFFFFFFu);
    check_result("REM negative dividend by zero",
                 m_rem(0xFFFFFF85u, 0u), 0xFFFFFF85u);
    check_result("REMU by zero", m_remu(0x12345678u, 0u), 0x12345678u);

    /* RISC-V signed overflow case: INT_MIN / -1 wraps to INT_MIN. */
    check_result("DIV INT_MIN / -1", m_div(0x80000000u, 0xFFFFFFFFu),
                 0x80000000u);
    check_result("REM INT_MIN % -1", m_rem(0x80000000u, 0xFFFFFFFFu),
                 0x00000000u);

    /*
     * Dependency / back-to-back test:
     * MUL result is consumed by DIVU, then DIVU result by REMU.
     * The ordinary ADD afterwards also checks that the written register
     * values can be consumed by following RV32I instructions.
     */
    /* Keep these three M instructions adjacent in the emitted code. */
    {
        uint32_t lhs = 21u;
        uint32_t two = 2u;
        uint32_t seven = 7u;
        uint32_t four = 4u;

        __asm__ volatile (
            ".insn r 0x33, 0, 1, %[mul], %[lhs], %[two]\n\t"
            ".insn r 0x33, 5, 1, %[div], %[mul], %[seven]\n\t"
            ".insn r 0x33, 7, 1, %[rem], %[div], %[four]\n\t"
            : [mul] "=&r" (chain_mul),
              [div] "=&r" (chain_div),
              [rem] "=&r" (chain_rem)
            : [lhs] "r" (lhs),
              [two] "r" (two),
              [seven] "r" (seven),
              [four] "r" (four)
            : "memory");
    }
    dependent_add = chain_div + chain_rem; /* 8 */

    check_result("dependent chain MUL -> DIVU", chain_div, 6u);
    check_result("dependent chain DIVU -> REMU", chain_rem, 2u);
    check_result("M-extension result -> RV32I ADD", dependent_add, 8u);
    check_result("dependency chain original MUL value", chain_mul, 42u);

    uart_puts("\r\nTests run: ");
    uart_put_hex32(tests_run);
    uart_puts("\r\nTests failed: ");
    uart_put_hex32(tests_failed);
    uart_puts("\r\n");

    if (tests_failed == 0u) {
        uart_puts("ALL M-EXTENSION TESTS PASSED\r\n");
    } else {
        uart_puts("M-EXTENSION TEST FAILURE\r\n");
    }

    /* Stop here so the test summary remains visible on UART. */
    for (;;) {
        __asm__ volatile ("nop");
    }
}
