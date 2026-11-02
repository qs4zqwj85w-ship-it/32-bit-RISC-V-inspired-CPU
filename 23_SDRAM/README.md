# Tang Nano 20K SDRAM

This directory contains the standalone SDRAM bring-up tests and the CPU-integrated external-memory path.

## Controller provenance

The low-level sdram.v controller is based on [nand2mario's Tang Nano 20K SDRAM controller](https://github.com/nand2mario/sdram-tang-nano-20k), used by NESTang. The open-source-toolchain reference fork is [Seyviour/sdram-tang-nano-20k-os-example](https://github.com/Seyviour/sdram-tang-nano-20k-os-example), which identifies itself as a fork of the original repository. The controller source is retained; this project adds a CPU-facing adapter and integrates it into the CPU.

The controller source describes the embedded SDRAM as a 64-Mbit, 32-bit-wide device (8 MiB). It uses byte-addressed commands, single-operation reads/writes with auto-precharge, and periodic refresh. Refer to the upstream source for the controller's timing assumptions and implementation details.

## CPU integration

- sdram_adapter.sv wraps the controller with a CPU request/response interface.
- 19_CPU/CPU.sv decodes addresses 0x00001000–0x00800FFF as SDRAM; BRAM remains at 0x00000000–0x00000FFF.
- The adapter subtracts 0x00001000 from the CPU byte address to obtain the controller-relative address.
- Reads fetch a 32-bit SDRAM word; byte and halfword loads are shifted and sign- or zero-extended by the adapter.
- The stock controller writes one byte per operation, so SB, SH, and SW use one, two, or four byte writes. Misaligned SH/SW stores are suppressed.
- The adapter buffers one request and uses req_ready for acceptance and a one-cycle done pulse for completion.
- A periodic refresh scheduler requests refresh at approximately 15 μs intervals at 27 MHz. Refresh can be serviced between bytes of a multi-byte store.
- The CPU FSM includes an SDRAM_WAIT state for external-memory transactions.

The CPU/SDRAM clocking uses the existing system Gowin_rPLL: the main clock drives controller logic and the phase-shifted clock is connected to the SDRAM clock output. The PLL and CPU clock architecture were not changed for HDMI integration.

## Standalone tests

The separate test tops and build scripts remain useful for isolating the controller and adapter from the CPU:

- sdram_test_top.sv and build_sdram_test.sh: original controller smoke test, writing and reading back eight bytes across two words.
- sdram_adapter_test_top.sv and build_sdram_adapter_test.sh: adapter-level read/write checks.

These tests are separate from the main CPU build. They were created as sanity checks before/in addition to CPU integration; they are not part of the normal build.sh flow.

## Board reference

The Tang Nano 20K embedded SDRAM connections use Gowin's special top-level port names (O_sdram_* and IO_sdram_dq). The main CPU top-level preserves those names so the FPGA toolchain connects the design to on-board memory. See the [Sipeed Tang Nano 20K documentation](https://wiki.sipeed.com/hardware/en/tang/tang-nano-20k/nano-20k.html) and [board schematic](https://dl.sipeed.com/fileList/TANG/Nano_20K/2_Schematic/Tang_Nano_20K_3921_Schematics.pdf).

For the request/response protocol and adapter state machine, see [SDRAM adapter notes](SDRAM_ADAPTER_NOTES.md).
