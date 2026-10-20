#ifndef VLSI_CODESIGN_HAL_H
#define VLSI_CODESIGN_HAL_H
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif

/*
 * These calls are implemented by VLSI Arena's isolated co-simulation bridge.
 * They produce real bus/protocol transactions against the Verilated student
 * RTL and advance simulation only as required by the active adapter.
 */
uint32_t mmio_read32(uint32_t address);
void mmio_write32(uint32_t address, uint32_t value);

#ifdef __cplusplus
}
#endif
#endif
