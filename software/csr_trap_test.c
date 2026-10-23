#include <stdint.h>

#define TEST_ILLEGAL 1   /* set to 0 if illegal-instruction traps aren't implemented */

#define UART_DATA (*(volatile uint8_t *)0x10000000u)
#define UART_STAT (*(volatile uint32_t *)0x10000004u)

#define CSRR(name, var) __asm__ volatile ("csrr %0, " #name : "=r"(var) :: "memory")
#define CSRW(name, val) __asm__ volatile ("csrw " #name ", %0" :: "r"(val) : "memory")

static void delay(void) { for (volatile uint32_t i = 0; i < 5000000; i++) ; }
static void uart_putc(char c) { while (UART_STAT & 1u) ; UART_DATA = (uint8_t)c; }
static void uart_puts(const char *s) { while (*s) uart_putc(*s++); }
static void put_hex(uint32_t v) {
    for (int i = 28; i >= 0; i -= 4) {
        uint32_t d = (v >> i) & 0xF;
        uart_putc(d < 10 ? '0' + d : 'A' + d - 10);
    }
}
static void put_dec2(uint32_t v) {          /* 0..99, no divide */
    char t = '0';
    while (v >= 10) { v -= 10; t++; }
    uart_putc(t);
    uart_putc('0' + v);
}

/* Written by the trap handler. Not static: the handler refers to them by name. */
volatile uint32_t last_cause = 0xFFFFFFFFu;
volatile uint32_t last_tval  = 0xFFFFFFFFu;
volatile uint32_t trap_count = 0;

static uint32_t total, fails;

static void check(const char *name, uint32_t got, uint32_t want)
{
    total++;
    if (got != want) {
        fails++;
        uart_puts("FAIL "); uart_puts(name);
        uart_puts(" got ");  put_hex(got);
        uart_puts(" want "); put_hex(want);
        uart_puts("\r\n");
    }
}

/* Records mcause and mtval, counts the trap, then skips the faulting instruction. */
__attribute__((naked, noinline, used, aligned(4), section(".text")))
void trap_handler(void)
{
    __asm__ volatile (
        "csrr t0, mcause\n"
        "la   t1, last_cause\n"
        "sw   t0, 0(t1)\n"
        "csrr t0, mtval\n"
        "la   t1, last_tval\n"
        "sw   t0, 0(t1)\n"
        "la   t1, trap_count\n"
        "lw   t0, 0(t1)\n"
        "addi t0, t0, 1\n"
        "sw   t0, 0(t1)\n"
        "csrr t0, mepc\n"
        "addi t0, t0, 4\n"
        "csrw mepc, t0\n"
        "mret\n"
    );
}

static void scratch_roundtrip(const char *name, uint32_t v)
{
    uint32_t r;
    __asm__ volatile ("csrw mscratch, %1\n\tcsrr %0, mscratch"
                      : "=&r"(r) : "r"(v) : "memory");
    check(name, r, v);
}

static void run_tests(void)
{
    uint32_t t, old;
    total = 0; fails = 0;

    __asm__ volatile ("csrw mtvec, %0" :: "r"((uintptr_t)&trap_handler) : "memory");

    /* ---- misa ---- */
    CSRR(misa, t);
    uint32_t misa_before = t;
    check("misa MXL is RV32", t >> 30, 1);
    check("misa has I",       (t >> 8) & 1u, 1);
    CSRW(misa, 0u);
    CSRR(misa, t);
    check("misa write ignored", t, misa_before);

    /* ---- mhartid ---- */
    CSRR(mhartid, t);
    check("mhartid is 0", t, 0);

    /* ---- mscratch: round trips ---- */
    scratch_roundtrip("mscratch DEADBEEF", 0xDEADBEEFu);
    scratch_roundtrip("mscratch 0",        0x00000000u);
    scratch_roundtrip("mscratch FFFFFFFF", 0xFFFFFFFFu);
    scratch_roundtrip("mscratch A5A5A5A5", 0xA5A5A5A5u);

    /* ---- mscratch: every CSR instruction form ---- */
    CSRW(mscratch, 0x11111111u);
    __asm__ volatile ("csrrw %0, mscratch, %1" : "=r"(old) : "r"(0x22222222u) : "memory");
    check("csrrw old", old, 0x11111111u);
    CSRR(mscratch, t);
    check("csrrw new", t, 0x22222222u);

    CSRW(mscratch, 0xF0u);
    __asm__ volatile ("csrrs %0, mscratch, %1" : "=r"(old) : "r"(0x0Fu) : "memory");
    check("csrrs old", old, 0xF0u);
    CSRR(mscratch, t);
    check("csrrs new", t, 0xFFu);

    __asm__ volatile ("csrrc %0, mscratch, %1" : "=r"(old) : "r"(0x3Cu) : "memory");
    check("csrrc old", old, 0xFFu);
    CSRR(mscratch, t);
    check("csrrc new", t, 0xC3u);

    __asm__ volatile ("csrrwi %0, mscratch, 21" : "=r"(old) :: "memory");
    check("csrrwi old", old, 0xC3u);
    CSRR(mscratch, t);
    check("csrrwi new", t, 21);

    __asm__ volatile ("csrrsi %0, mscratch, 10" : "=r"(old) :: "memory");
    CSRR(mscratch, t);
    check("csrrsi new", t, 31);                 /* 21 | 10 */

    __asm__ volatile ("csrrci %0, mscratch, 1" : "=r"(old) :: "memory");
    CSRR(mscratch, t);
    check("csrrci new", t, 30);                 /* 31 & ~1 */

    /* ---- mtval: plain read/write ---- */
    CSRW(mtval, 0x12345678u);
    CSRR(mtval, t);
    check("mtval write/read", t, 0x12345678u);

    /* ---- mtval and mcause updated by traps ---- */
    CSRW(mtval, 0x5A5A5A5Au);
    last_cause = 0xFFFFFFFFu; last_tval = 0xFFFFFFFFu;
    __asm__ volatile ("ecall" ::: "memory", "t0", "t1");
    check("ecall cause", last_cause, 11);
    check("ecall mtval", last_tval, 0);

    CSRW(mtval, 0x5A5A5A5Au);
    last_cause = 0xFFFFFFFFu; last_tval = 0xFFFFFFFFu;
    __asm__ volatile ("ebreak" ::: "memory", "t0", "t1");
    check("ebreak cause", last_cause, 3);
    check("ebreak mtval", last_tval, 0);

#if TEST_ILLEGAL
    /* Illegal opcode: mtval should hold the instruction word. */
    last_cause = 0xFFFFFFFFu; last_tval = 0;
    __asm__ volatile (".word 0xFFFFFFFF" ::: "memory", "t0", "t1");
    check("illegal cause", last_cause, 2);
    check("illegal mtval", last_tval, 0xFFFFFFFFu);

    /* csrr t2, 0x7C0 (unimplemented CSR), written as a raw word */
    last_cause = 0xFFFFFFFFu; last_tval = 0;
    __asm__ volatile (".word 0x7C0023F3" ::: "memory", "t0", "t1", "t2");
    check("bad CSR cause", last_cause, 2);
    check("bad CSR mtval", last_tval, 0x7C0023F3u);

    /* csrw mhartid, zero (write to a read-only CSR) */
    last_cause = 0xFFFFFFFFu; last_tval = 0;
    __asm__ volatile (".word 0xF1401073" ::: "memory", "t0", "t1");
    check("RO write cause", last_cause, 2);
    check("RO write mtval", last_tval, 0xF1401073u);

    /* csrr (rs1 = x0) of a read-only CSR must NOT trap... */
    uint32_t n0 = trap_count;
    CSRR(mhartid, t);
    check("csrr mhartid no trap", trap_count, n0);

    /* ...but csrrs with rs1 != x0 attempts a write, so it must trap. */
    last_cause = 0xFFFFFFFFu;
    __asm__ volatile ("li t3, 1\n\tcsrrs t2, mhartid, t3"
                      ::: "memory", "t0", "t1", "t2", "t3");
    check("csrrs RO rs1!=0 traps", last_cause, 2);
#endif
}

int main(void)
{
    delay();
    for (;;) {
        run_tests();
        uart_puts(fails ? "RESULT: FAIL " : "RESULT: ALL PASS ");
        put_dec2(total - fails); uart_putc('/'); put_dec2(total);
        uart_puts("\r\n");
        delay();
    }
}
