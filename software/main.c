#define UART_DATA (*(volatile unsigned int *)0x10000000u)
#define UART_STAT (*(volatile unsigned int *)0x10000004u)

static void uart_putc(char c) {
    while (UART_STAT & 1) ;
    UART_DATA = (unsigned char)c;
}

static void uart_puts(const char *s) {
    while (*s) uart_putc(*s++);
}

int main(void) {
    for (;;) {
        uart_puts("Hello from my RISC-V CPU!\r\n");
        for (volatile int i = 0; i < 1000000; i++) ;
    }
}
