
module tb_video_pattern;

    logic [9:0] pixel_x;
    logic [9:0] pixel_y;
    logic active_video;

    logic [7:0] r;
    logic [7:0] g;
    logic [7:0] b;

    // Device under test
    video_pattern dut (
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .active_video(active_video),
        .r(r),
        .g(g),
        .b(b)
    );

    // Task to check an RGB output
    task automatic check_pixel(
        input integer x,
        input logic active,
        input logic [7:0] expected_r,
        input logic [7:0] expected_g,
        input logic [7:0] expected_b
    );
        begin
            pixel_x = x[9:0];
            pixel_y = 100;
            active_video = active;

            // Allow combinational logic to settle
            #1;

            if (r !== expected_r ||
                g !== expected_g ||
                b !== expected_b) begin

                $fatal(1,
                    "FAIL: x=%0d active=%b | Expected RGB=(%h,%h,%h), Got=(%h,%h,%h)",
                    x, active,
                    expected_r, expected_g, expected_b,
                    r, g, b
                );
            end

            $display(
                "PASS: x=%0d active=%b RGB=(%h,%h,%h)",
                x, active, r, g, b
            );
        end
    endtask

    initial begin
        $display("Starting video pattern test...");

        // Red region: x = 0 to 212
        check_pixel(0,   1, 8'hFF, 8'h00, 8'h00);
        check_pixel(212, 1, 8'hFF, 8'h00, 8'h00);

        // Green region: x = 213 to 425
        check_pixel(213, 1, 8'h00, 8'hFF, 8'h00);
        check_pixel(425, 1, 8'h00, 8'hFF, 8'h00);

        // Blue region: x = 426 to 719
        check_pixel(426, 1, 8'h00, 8'h00, 8'hFF);
        check_pixel(719, 1, 8'h00, 8'h00, 8'hFF);

        // Outside visible area: should always be black
        check_pixel(0,   0, 8'h00, 8'h00, 8'h00);
        check_pixel(300, 0, 8'h00, 8'h00, 8'h00);
        check_pixel(719, 0, 8'h00, 8'h00, 8'h00);

        $display("--------------------------------");
        $display("VIDEO PATTERN TEST PASSED!");
        $display("--------------------------------");

        $finish;
    end

endmodule
