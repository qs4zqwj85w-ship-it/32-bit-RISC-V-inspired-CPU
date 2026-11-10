# HDMI / DVI-compatible video subsystem

The 24_HDMI/ directory implements a standalone 720×480 active-pixel test video pipeline for the Tang Nano 20K. It is integrated into 19_CPU/cpu_fpga_top.sv, but it is not yet connected to CPU memory or a framebuffer.

## Current output

- 720×480 active pixels; horizontal total 858 and vertical total 525.
- 27 MHz pixel clock, approximately 59.94 Hz frame rate.
- Three vertical RGB bars: red, green, and blue. This simple pattern was chosen to prove all three color channels are being driven.
- DVI-compatible TMDS video over the board's HDMI-shaped connector. No audio or HDMI InfoFrames are generated.

480-line video was chosen as a first target because, as I put it, **“I thought flappy bird with 480 be kinda sick.”**

## Pipeline

1. video_timing.sv generates pixel coordinates, sync, and active-video timing.
2. video_pattern.sv generates the RGB bars and outputs black during blanking. // This is no longer true as we moved on to connecting CPU output onto the SDRAM and now image pixels are stored in certain registers in the SDRAM and the HDMI output reads them
3. video_core.sv combines timing and pattern generation.
4. Three tmds_encoder.sv instances encode red, green, and blue into 10-bit TMDS symbols. The blue encoder also carries HSync/VSync control symbols during blanking.
5. gowin_hdmi_pll.sv generates a nominal 135 MHz clock (5× 27 MHz) for the three Gowin OSER10 serializers in serializer.sv.
6. differential_output.sv drives the serialized data and pixel clock through Gowin TLVDS_OBUF primitives.

The board's 27 MHz clock drives pixel timing and TMDS encoding directly. HDMI uses its own PLL; the existing CPU/SDRAM PLL was left unchanged.

## Tang Nano 20K pin mapping

The constraints use the DVI/TMDS differential pairs shown in Sipeed's [Tang Nano 20K schematic, revision 3921](https://dl.sipeed.com/fileList/TANG/Nano_20K/2_Schematic/Tang_Nano_20K_3921_Schematics.pdf):

| TMDS signal | P pin | N pin |
|---|---:|---:|
| Clock | 33 | 34 |
| Data 0 (blue) | 35 | 36 |
| Data 1 (green) | 37 | 38 |
| Data 2 (red) | 39 | 40 |

## Build and verification status

**Successfully built and programmed; physical output not tested.** The latest SKIP_FLASH=1 ./build.sh run completed synthesis, place-and-route, and bitstream packing. A subsequent normal ./build.sh run programmed cpu.fs using openFPGALoader; the log reported a 6 MHz JTAG link, SRAM loading at 100%, and DONE / “Build and programming complete.”

A monitor was not available, so no claim is made that a display has locked to the signal or that the expected bars are visible. Serializer bit order/phase, PLL behavior under hardware, differential output behavior, and monitor compatibility still require physical testing. Build/program success alone does not verify those properties.

## Source references

- [Sipeed Tang Nano 20K board wiki](https://wiki.sipeed.com/hardware/en/tang/tang-nano-20k/nano-20k.html)
- [Sipeed Tang Nano 20K schematic, revision 3921](https://dl.sipeed.com/fileList/TANG/Nano_20K/2_Schematic/Tang_Nano_20K_3921_Schematics.pdf)
- [Sipeed Tang Nano 20K examples](https://github.com/sipeed/TangNano-20K-example)
- [Gowin FPGA documentation and resources](https://www.gowinsemi.com/en/support/home/)
