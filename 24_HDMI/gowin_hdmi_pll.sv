// our OSER10 apparently requries a fast 135Mhz clock so this block is built to generate that clock speed by multiplying original by 5
// first part is for verilator check, second part is what we actually need on fpga.
module gowin_hdmi_pll (
    input  logic clk_27m,
    input  logic reset,

    output wire clk_135m,
    output wire locked
);

`ifdef VERILATOR

    // Simulation model: nominal 135 MHz output
    timeunit 1ns;
    timeprecision 1ps;

    logic sim_clk_135m = 1'b0;
    logic sim_locked = 1'b0;
    logic [3:0] lock_counter = 4'd0;

    // 135 MHz = approximately 7.408 ns period
    // Half-period = 3.704 ns
    initial begin
        sim_clk_135m = 1'b0;

        forever begin
            #3.704;

            if (reset)
                sim_clk_135m = 1'b0;
            else
                sim_clk_135m = ~sim_clk_135m;
        end
    end

    // Simulate PLL lock acquisition
    always_ff @(posedge clk_27m or posedge reset) begin
        if (reset) begin
            lock_counter <= 4'd0;
            sim_locked <= 1'b0;
        end else if (!sim_locked) begin
            if (lock_counter == 4'd9)
                sim_locked <= 1'b1;
            else
                lock_counter <= lock_counter + 1'b1;
        end
    end

    assign clk_135m = sim_clk_135m;
    assign locked = sim_locked;

`else

    // Actual Gowin PLL hardware
    wire gw_gnd = 1'b0;

    wire clkoutp_unused;
    wire clkoutd_unused;
    wire clkoutd3_unused;

    rPLL rpll_inst (
        .CLKOUT(clk_135m),
        .LOCK(locked),
        .CLKOUTP(clkoutp_unused),
        .CLKOUTD(clkoutd_unused),
        .CLKOUTD3(clkoutd3_unused),

        .RESET(reset),
        .RESET_P(gw_gnd),
        .CLKIN(clk_27m),
        .CLKFB(gw_gnd),

        .FBDSEL({6{gw_gnd}}),
        .IDSEL({6{gw_gnd}}),
        .ODSEL({6{gw_gnd}}),
        .PSDA({4{gw_gnd}}),
        .DUTYDA({4{gw_gnd}}),
        .FDLY({4{gw_gnd}})
    );

    // 27 MHz input -> 135 MHz output
    defparam rpll_inst.FBDIV_SEL = 4;
    defparam rpll_inst.IDIV_SEL = 0;
    defparam rpll_inst.ODIV_SEL = 8;

    defparam rpll_inst.FCLKIN = "27";
    defparam rpll_inst.DEVICE = "GW2A-18C";

    defparam rpll_inst.DYN_IDIV_SEL = "false";
    defparam rpll_inst.DYN_FBDIV_SEL = "false";
    defparam rpll_inst.DYN_ODIV_SEL = "false";

    defparam rpll_inst.PSDA_SEL = "1010";
    defparam rpll_inst.DYN_DA_EN = "false";
    defparam rpll_inst.DUTYDA_SEL = "1000";

    defparam rpll_inst.CLKOUT_FT_DIR = 1'b1;
    defparam rpll_inst.CLKOUTP_FT_DIR = 1'b1;
    defparam rpll_inst.CLKOUT_DLY_STEP = 0;
    defparam rpll_inst.CLKOUTP_DLY_STEP = 0;

    defparam rpll_inst.CLKFB_SEL = "internal";

    defparam rpll_inst.CLKOUT_BYPASS = "false";
    defparam rpll_inst.CLKOUTP_BYPASS = "false";
    defparam rpll_inst.CLKOUTD_BYPASS = "false";

    defparam rpll_inst.DYN_SDIV_SEL = 2;
    defparam rpll_inst.CLKOUTD_SRC = "CLKOUT";
    defparam rpll_inst.CLKOUTD3_SRC = "CLKOUT";

`endif

endmodule
