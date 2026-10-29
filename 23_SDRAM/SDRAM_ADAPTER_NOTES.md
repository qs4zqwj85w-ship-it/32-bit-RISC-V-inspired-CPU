# SDRAM adapter (pre-CPU integration)

`sdram_adapter.sv` wraps the stock `sdram.v` controller and presents a CPU-style
request/response interface. The controller source is not modified.

## CPU-side interface

- `req`: request valid. Hold until a rising edge where `req_ready` is high.
- `req_ready`: the adapter can accept one request. It may remain high while a
  refresh command is running because the request is buffered.
- `we`: 0=read, 1=write.
- `addr`: full CPU byte address. The default SDRAM base is `0x00001000`.
- `wdata`: store value in the low bits, as in the current memory_subword module.
- `access_size`: 0=byte, 1=halfword, 2=word.
- `load_unsigned`: unsigned extension for LB/LH variants.
- `done`: one-cycle completion pulse.
- `rdata`: returned load value; valid during `done` and then held.

Only send addresses from `0x00001000` through `0x00800FFF`. The adapter converts
these to offsets 0 through 0x7FFFFF. It does not perform address decoding for
BRAM or memory-mapped I/O; the CPU subsystem will do that.

## Internal behavior

- Captures each accepted request in registers so CPU signals can change while
  the SDRAM operation is in flight.
- Waits for controller `busy` to fall before issuing commands.
- Pulses `rd`/`wr`/`refresh`, then observes `busy` rise and fall.
- Captures `dout32` only during `data_ready`.
- Writes SB as one byte, SH as two byte writes, SW as four byte writes.
- Suppresses misaligned SH/SW stores, matching `memory_subword.sv`.
- Refreshes at approximately 15 us intervals at 27 MHz.

## Test

`build_sdram_adapter_test.sh` builds and flashes `sdram_adapter_test_top.sv`.
Use the same `sdram.v`, `gowin_rpll.v`, and `sdram_test.cst` from the already
working standalone SDRAM controller test. LED0 on means the adapter read/write
checks passed; LED1 on means one failed. The test top does not modify the CPU
build or source files.
