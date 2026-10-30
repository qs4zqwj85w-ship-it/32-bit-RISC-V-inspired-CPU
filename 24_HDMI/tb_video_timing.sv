
module tb_video_timing;

    // Clock and reset
    logic clk_pixel;
    logic rst;

    // DUT outputs
    logic [9:0] pixel_x;
    logic [9:0] pixel_y;
    logic hsync;
    logic vsync;
    logic active_video;

    // Expected timing parameters
    localparam H_TOTAL = 858;
    localparam V_TOTAL = 525;
    localparam FRAME_CYCLES = H_TOTAL * V_TOTAL;

    // Counters for verification
    integer visible_count = 0;
    integer hsync_low_count = 0;
    integer vsync_low_count = 0;

    integer expected_x;
    integer expected_y;

    // Device under test
    video_timing dut (
        .clk_pixel(clk_pixel),
        .rst(rst),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .hsync(hsync),
        .vsync(vsync),
        .active_video(active_video)
    );

    // Simulation clock (10 ns period)
    initial clk_pixel = 0;
    always #5 clk_pixel = ~clk_pixel;

    initial begin

        $display("Starting video timing test...");

        // Apply reset
        rst = 1;
        repeat (2) @(posedge clk_pixel);

        // Release reset on falling edge
        @(negedge clk_pixel);
        rst = 0;

        // Verify one complete frame
        for (integer cycle = 0; cycle < FRAME_CYCLES; cycle++) begin

            // Calculate expected coordinates
            expected_x = cycle % H_TOTAL;
            expected_y = cycle / H_TOTAL;

            // Check pixel coordinates
            if (pixel_x !== expected_x[9:0] || pixel_y !== expected_y[9:0]) begin
                $fatal(1,
                    "Coordinate ERROR at cycle %0d: expected (%0d,%0d), got (%0d,%0d)",
                    cycle, expected_x, expected_y, pixel_x, pixel_y
                );
            end

            // Check horizontal sync
            if (hsync !== !((expected_x >= 736) &&
                            (expected_x <= 797))) begin
                $fatal(1, "HSYNC ERROR at cycle %0d", cycle);
            end

            // Check vertical sync
            if (vsync !== !((expected_y >= 489) &&
                            (expected_y <= 494))) begin
                $fatal(1, "VSYNC ERROR at cycle %0d", cycle);
            end

            // Check active video
            if (active_video !== ((expected_x < 720) &&
                                  (expected_y < 480))) begin
                $fatal(1, "ACTIVE VIDEO ERROR at cycle %0d", cycle);
            end

            // Count visible pixels
            if (active_video)
                visible_count++;

            // Count low sync cycles
            if (!hsync)
                hsync_low_count++;

            if (!vsync)
                vsync_low_count++;

            // Advance to the next pixel
            @(posedge clk_pixel);
            #1;

        end

        // Check total visible pixels
        if (visible_count != 345600)
            $fatal(1, "Visible pixel count ERROR: %0d", visible_count);

        // Check total horizontal sync cycles
        if (hsync_low_count != (62 * 525))
            $fatal(1, "HSYNC count ERROR: %0d", hsync_low_count);

        // Check total vertical sync cycles
        if (vsync_low_count != (6 * 858))
            $fatal(1, "VSYNC count ERROR: %0d", vsync_low_count);

        // Verify frame rollover
        if (pixel_x !== 0 || pixel_y !== 0)
            $fatal(1, "Frame rollover ERROR");

        $display("--------------------------------");
        $display("VIDEO TIMING TEST PASSED!");
        $display("Total frame cycles : %0d", FRAME_CYCLES);
        $display("Visible pixels     : %0d", visible_count);
        $display("HSYNC low cycles   : %0d", hsync_low_count);
        $display("VSYNC low cycles   : %0d", vsync_low_count);
        $display("--------------------------------");

        $finish;
    end

endmodule
