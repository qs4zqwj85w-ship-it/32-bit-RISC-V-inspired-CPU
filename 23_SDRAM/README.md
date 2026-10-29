# Standalone Tang Nano 20K SDRAM smoke test

This folder has a separate test top and build flow; it does not modify the CPU top or CPU build script.

Required files in this folder:
- `sdram.v`: NESTang SDRAM controller from the `sdram-tang-nano-20k-os-example` fork.
- `gowin_rpll.v`: the fork's `Gowin_rPLL` source.
- `sdram_test_top.sv`: standalone smoke test, writes and reads back eight bytes across two words.
- `sdram_test.cst`: standalone pin constraints.
- `build_sdram_test.sh`: synthesize, place/route, package, and flash only this test design.

Expected result on the board:
- LED0 on: all eight byte read-back checks passed.
- LED1 on: at least one read-back check failed.
- Neither LED lit while initialization/testing is in progress.

The controller's stock interface is byte-wide for writes. This test intentionally verifies the four byte lanes and two word addresses before any CPU integration.

this is ai generate test for my sanity purpose to prove the controller is working
