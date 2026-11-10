
#include <stdint.h>

#define GPIO_INPUT (*(volatile uint32_t *)0x1000001C)
#define UART_DATA  (*(volatile uint32_t *)0x10000000)
#define UART_STATUS (*(volatile uint32_t *)0x10000004)

static void uart_putc(char c)
{
    while (UART_STATUS & 1) {
        // Wait while UART is busy
    }

    UART_DATA = (uint32_t)c;
}

int main(void)
{
    while (1) {
        if (GPIO_INPUT & 1) {
            uart_putc('1');
        } else {
            uart_putc('0');
        }

        uart_putc('\r');
        uart_putc('\n');

        for (volatile uint32_t i = 0; i < 100000; i++);
    }

    return 0;
}
