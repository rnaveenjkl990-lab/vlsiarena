#include <stdint.h>
#include <stddef.h>
#include "codesign_hal.h"
#include "codesign_regs.h"

#define UART_STATUS_ADDR   UART0_STATUS_ADDR
#define UART_TXDATA_ADDR   UART0_TXDATA_ADDR
#define UART_TX_READY_MASK UART0_STATUS_TX_READY_MASK

#ifdef __cplusplus
extern "C" {
#endif

int firmware_send(const uint8_t *bytes, unsigned count, unsigned poll_limit) {
    // Parameter validation: count == 0 must succeed immediately
    if (count == 0) {
        return 0;
    }
    // Reject NULL pointer if there are bytes to send
    if (bytes == NULL) {
        return -1;
    }

    for (unsigned i = 0; i < count; i++) {
        unsigned attempts = 0;
        // Poll STATUS until TX_READY is asserted
        while ((mmio_read32(UART_STATUS_ADDR) & UART_TX_READY_MASK) == 0) {
            attempts++;
            if (attempts >= poll_limit) {
                return -1;
            }
        }
        // Write current byte to TXDATA
        mmio_write32(UART_TXDATA_ADDR, (uint32_t)bytes[i]);
    }

    // Wait for the final byte's stop bit to complete
    unsigned attempts = 0;
    while ((mmio_read32(UART_STATUS_ADDR) & UART_TX_READY_MASK) == 0) {
        attempts++;
        if (attempts >= poll_limit) {
            return -1;
        }
    }

    return 0;
}

#ifdef __cplusplus
}
#endif