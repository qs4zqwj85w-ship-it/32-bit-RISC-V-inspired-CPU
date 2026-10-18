set -e
rm -f cpu.json pnr.json cpu.fs
FILES=$(find . -name "*.sv" ! -path "./old/*" ! -name "*tb*" ! -name "*test*" ! -name "memory_4k.sv" ! -name "full_memory.sv" | tr '\n' ' ')
yosys -p "read_verilog -sv $FILES; synth_gowin -top cpu_fpga_top -json cpu.json" > synth.log 2>&1
nextpnr-himbaechel --json cpu.json --write pnr.json \
  --device GW2AR-LV18QN88C8/I7 --vopt family=GW2A-18C --vopt cst=cpu_fpga_top.cst
gowin_pack -d GW2A-18C -o cpu.fs pnr.json
openFPGALoader -b tangnano20k cpu.fs
