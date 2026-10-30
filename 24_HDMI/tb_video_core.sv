module tb_video_core;

    logic clk_pixel;
    logic rst;

    logic hsync;
    logic vsync;

    logic [7:0] red;
    logic [7:0] green;
    logic [7:0] blue;

    integer x;
    integer y;
    integer visible_count;
    integer hsync_low_count;
    integer vsync_low_count;

    video_core dut (
        .clk_pixel(clk_pixel),
        .rst(rst),
        .hsync(hsync),
        .vsync(vsync),
        .red(red),
        .green(green),
        .blue(blue)
    );

    // 27 MHz pixel clock (approximately 37.037 ns period)
    initial begin
        clk_pixel = 0;
        forever #18.518 clk_pixel = ~clk_pixel;
    end

    initial begin
        rst = 1;
        visible_count = 0;
        hsync_low_count = 0;
        vsync_low_count = 0;

        // Release reset while DUT is at pixel (0,0)
        repeat (2) @(posedge clk_pixel);
        @(negedge clk_pixel);
        rst = 0;
        #1;

        // Check one complete frame: 858 * 525 pixels
        for (y = 0; y < 525; y = y + 1) begin
            for (x = 0; x < 858; x = x + 1) begin

                // Check current pixel before advancing the clock
                #1;

                // Check RGB output
                if (x < 720 && y < 480) begin
                    visible_count = visible_count + 1;

                    if (x < 213) begin
                        if ({red, green, blue} !== 24'hFF0000)
                            $fatal(1, "Red region error at x=%0d y=%0d | RGB=%h",
                                   x, y, {red, green, blue});
                    end
                    else if (x < 426) begin
                        if ({red, green, blue} !== 24'h00FF00)
                            $fatal(1, "Green region error at x=%0d y=%0d | RGB=%h",
                                   x, y, {red, green, blue});
                    end
                    else begin
                        if ({red, green, blue} !== 24'h0000FF)
                            $fatal(1, "Blue region error at x=%0d y=%0d | RGB=%h",
                                   x, y, {red, green, blue});
                    end
                end
                else begin
                    if ({red, green, blue} !== 24'h000000)
                        $fatal(1, "Blanking region not black at x=%0d y=%0d",
                               x, y);
                end

                // Check horizontal sync (active low: x=736..797)
                if (x >= 736 && x <= 797) begin
                    if (hsync !== 1'b0)
                        $fatal(1, "Hsync error at x=%0d y=%0d", x, y);
                end
                else begin
                    if (hsync !== 1'b1)
                        $fatal(1, "Hsync error at x=%0d y=%0d", x, y);
                end

                // Check vertical sync (active low: y=489..494)
                if (y >= 489 && y <= 494) begin
                    if (vsync !== 1'b0)
                        $fatal(1, "Vsync error at x=%0d y=%0d", x, y);
                end
                else begin
                    if (vsync !== 1'b1)
                        $fatal(1, "Vsync error at x=%0d y=%0d", x, y);
                end

                if (hsync == 1'b0)
                    hsync_low_count = hsync_low_count + 1;

                if (vsync == 1'b0)
                    vsync_low_count = vsync_low_count + 1;

                // Advance to the next pixel
                @(posedge clk_pixel);
                #1;
                @(negedge clk_pixel);
                #1;
            end
        end

        // Final count checks
        if (visible_count != 345600)
            $fatal(1, "Visible pixel count incorrect: %0d", visible_count);

        if (hsync_low_count != 32550)
            $fatal(1, "Hsync low count incorrect: %0d", hsync_low_count);

        if (vsync_low_count != 5148)
            $fatal(1, "Vsync low count incorrect: %0d", vsync_low_count);

        $display("--------------------------------");
        $display("VIDEO CORE TEST PASSED");
        $display("Visible pixels: %0d", visible_count);
        $display("Hsync low cycles: %0d", hsync_low_count);
        $display("Vsync low cycles: %0d", vsync_low_count);
        $display("--------------------------------");

        $finish;
    end

endmodule
