module tb_gowin_hdmi_pll;

    timeunit 1ns;
    timeprecision 1ps;

    logic clk_27m = 1'b0;
    logic reset = 1'b1;

    wire clk_135m;
    wire locked;

    real start_time;
    real end_time;
    real measured_period;

    // Expected periods
    localparam real EXPECTED_INPUT_PERIOD  = 37.037;
    localparam real EXPECTED_OUTPUT_PERIOD = 7.407;

    // Allow 0.02 ns measurement tolerance
    localparam real TOLERANCE = 0.02;

    gowin_hdmi_pll dut (
        .clk_27m(clk_27m),
        .reset(reset),
        .clk_135m(clk_135m),
        .locked(locked)
    );

    // Generate approximately 27 MHz input clock
    always #18.519 clk_27m = ~clk_27m;

    initial begin
        $display("------------------------------------");
        $display(" Gowin HDMI PLL Testbench");
        $display("------------------------------------");

        // Release reset
        repeat (3) @(posedge clk_27m);
        @(negedge clk_27m);
        reset = 1'b0;

        // Wait for PLL lock
        repeat (100) @(posedge clk_27m);

        if (locked !== 1'b1)
            $fatal(1, "FAIL: PLL did not lock");

        $display("PASS: PLL locked");

        // --------------------------------
        // Measure 27 MHz input clock
        // --------------------------------

        @(posedge clk_27m);
        start_time = $realtime;

        repeat (10) @(posedge clk_27m);
        end_time = $realtime;

        measured_period = (end_time - start_time) / 10.0;

        $display("");
        $display("Input clock:");
        $display("Measured period: %.3f ns", measured_period);
        $display("Expected period: %.3f ns", EXPECTED_INPUT_PERIOD);

        if ((measured_period < EXPECTED_INPUT_PERIOD - TOLERANCE) ||
            (measured_period > EXPECTED_INPUT_PERIOD + TOLERANCE))
            $fatal(1, "FAIL: Input clock frequency incorrect");

        $display("PASS: Input clock is approximately 27 MHz");

        // --------------------------------
        // Measure 135 MHz PLL output
        // --------------------------------

        @(posedge clk_135m);
        start_time = $realtime;

        repeat (20) @(posedge clk_135m);
        end_time = $realtime;

        measured_period = (end_time - start_time) / 20.0;

        $display("");
        $display("PLL output clock:");
        $display("Measured period: %.3f ns", measured_period);
        $display("Expected period: %.3f ns", EXPECTED_OUTPUT_PERIOD);

        if ((measured_period < EXPECTED_OUTPUT_PERIOD - TOLERANCE) ||
            (measured_period > EXPECTED_OUTPUT_PERIOD + TOLERANCE))
            $fatal(1, "FAIL: PLL output frequency incorrect");

        $display("PASS: PLL output is approximately 135 MHz");

        // --------------------------------
        // Test reset behavior
        // --------------------------------

        reset = 1'b1;
        #1;

        if (locked !== 1'b0)
            $fatal(1, "FAIL: PLL lock did not clear during reset");

        $display("PASS: Reset clears PLL lock");

        $display("");
        $display("------------------------------------");
        $display(" ALL PLL TESTS PASSED");
        $display("------------------------------------");

        $finish;
    end

endmodule
