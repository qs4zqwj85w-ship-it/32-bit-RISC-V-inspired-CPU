# SDRAM adapter (CPU-integrated)

sdram_adapter.sv wraps the stock sdram.v controller and presents a CPU-style request/response interface. The controller source is retained rather than rewritten. It is based on [nand2mario's Tang Nano 20K SDRAM controller](https://github.com/nand2mario/sdram-tang-nano-20k); the open-source-toolchain reference fork is [Seyviour's port](https://github.com/Seyviour/sdram-tang-nano-20k-os-example).

## CPU memory map

| Region | CPU byte-address range | Size |
|---|---:|---:|
| On-chip BRAM | 0x00000000–0x00000FFF | 4 KiB |
| External SDRAM | 0x00001000–0x00800FFF | 8 MiB |

The CPU performs address decoding. The adapter expects a CPU byte address in the SDRAM window and subtracts the base 0x00001000 before issuing the controller request. It does not decode BRAM or MMIO.

## CPU-side interface

- req: request valid. Hold until a rising edge where req_ready is high.
- req_ready: the adapter can accept one request; it is an acceptance handshake, not the controller's busy signal.
- we: 0=read, 1=write.
- addr: full CPU byte address within the SDRAM window.
- wdata: store value in the low bits, following the CPU memory-subword convention.
- access_size: 0=byte, 1=halfword, 2=word.
- load_unsigned: unsigned extension for LBU/LHU; otherwise byte/halfword reads are sign-extended.
- done: one-cycle completion pulse.
- rdata: returned load value, valid with done and then held.

## Internal behavior

- Captures each accepted request so CPU-side signals can change while the SDRAM operation is in flight.
- Waits for controller busy to fall before issuing commands, then observes busy rise and fall to confirm command execution.
- Captures the returned 32-bit word when data_ready is asserted.
- Reads use one controller operation; the adapter shifts and extends subword data from the returned word.
- The controller accepts one byte per write. SB uses one byte write, SH uses two, and SW uses four.
- Misaligned SH/SW stores are suppressed, matching memory_subword.sv.
- Periodic refresh requests are scheduled at approximately 15 μs intervals at 27 MHz. A pending refresh can be serviced between bytes of a multi-byte store.
- The adapter buffers one CPU request; it is not a multi-request queue or burst interface.

## Integration and verification

The adapter is instantiated by CPU in 19_CPU/CPU.sv. The CPU FSM waits in SDRAM_WAIT for request completion. The main FPGA wrapper, 19_CPU/cpu_fpga_top.sv, connects the controller to the Tang Nano 20K's special SDRAM port names. The main build includes the adapter, upstream controller, and its PLL source.

The standalone controller and adapter test tops/build scripts remain available for isolated sanity checks. They are not run automatically by the main CPU build. See the [directory README](README.md) for overall integration and source attribution.
