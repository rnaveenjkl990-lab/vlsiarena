#ifndef VLSI_CODESIGN_REGS_H
#define VLSI_CODESIGN_REGS_H
#include <stdint.h>

/* Generated from the active VLSI Arena task register-map contract. */

/* UART0: 0x00000000, size 0x00000010 */
#define UART0_STATUS_ADDR UINT32_C(0x00000000)
#define UART0_STATUS_TX_READY_LSB 0u
#define UART0_STATUS_TX_READY_MASK (UINT32_C(0x00000001) << 0u)
#define UART0_TXDATA_ADDR UINT32_C(0x00000004)
#define UART0_TXDATA_DATA_LSB 0u
#define UART0_TXDATA_DATA_MASK (UINT32_C(0x000000ff) << 0u)

#endif
