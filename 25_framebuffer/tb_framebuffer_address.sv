module tb_framebuffer_address;

    logic [9:0] pixel_x;
    logic [9:0] pixel_y;
    logic       active_video;

    logic       pixel_valid;
    logic [31:0] pixel_byte_addr;
    logic [31:0] aligned_word_addr;
    logic [1:0]  byte_lane;

    integer tests_passed = 0;
    integer tests_failed = 0;

    framebuffer_address dut (
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .active_video(active_video),
        .pixel_valid(pixel_valid),
        .pixel_byte_addr(pixel_byte_addr),
        .aligned_word_addr(aligned_word_addr),
        .byte_lane(byte_lane)
    );

    task automatic check_pixel(
        input logic [9:0] x,
        input logic [9:0] y,
        input logic       active,
        input logic       expected_valid,
        input logic [31:0] expected_addr
    );
        begin
            pixel_x = x;
            pixel_y = y;
            active_video = active;

            #1;

            if (
                pixel_valid !== expected_valid ||
                (expected_valid &&
                 pixel_byte_addr !== expected_addr)
            ) begin
                $display(
                    "FAIL: x=%0d y=%0d active=%b",
                    x, y, active
                );
                $display(
                    "  Expected valid=%b addr=%h",
                    expected_valid, expected_addr
                );
                $display(
                    "  Actual   valid=%b addr=%h",
                    pixel_valid, pixel_byte_addr
                );
                tests_failed++;
            end
            else begin
                $display(
                    "PASS: x=%0d y=%0d addr=%h",
                    x, y, pixel_byte_addr
                );
                tests_passed++;
            end
        end
    endtask

    initial begin
        $display("=== Framebuffer Address Test ===");

        // Origin
        check_pixel(
            0, 0, 1'b1, 1'b1, 32'h0010_0000
        );

        // Horizontal scaling
        check_pixel(
            1, 0, 1'b1, 1'b1, 32'h0010_0000
        );

        check_pixel(
            2, 0, 1'b1, 1'b1, 32'h0010_0001
        );

        check_pixel(
            8, 0, 1'b1, 1'b1, 32'h0010_0004
        );

        // Vertical scaling
        check_pixel(
            0, 1, 1'b1, 1'b1, 32'h0010_0000
        );

        check_pixel(
            0, 2, 1'b1, 1'b1, 32'h0010_0168
        );

        // Bottom-right corner
        check_pixel(
            719, 479, 1'b1, 1'b1, 32'h0011_517F
        );

        // Outside active display
        check_pixel(
            720, 100, 1'b1, 1'b0, 32'h0010_0000
        );

        check_pixel(
            100, 480, 1'b1, 1'b0, 32'h0010_0000
        );

        // Active video disabled
        check_pixel(
            100, 100, 1'b0, 1'b0, 32'h0010_0000
        );

        // Check byte lane and aligned address
        pixel_x = 10;
        pixel_y = 0;
        active_video = 1'b1;
        #1;

        if (
            aligned_word_addr !== 32'h0010_0004 ||
            byte_lane !== 2'b01
        ) begin
            $display("FAIL: byte lane selection");
            $display(
                "  aligned=%h lane=%b",
                aligned_word_addr, byte_lane
            );
            tests_failed++;
        end
        else begin
            $display("PASS: byte lane selection");
            tests_passed++;
        end

        $display("==============================");
        $display("Passed: %0d", tests_passed);
        $display("Failed: %0d", tests_failed);
        $display("==============================");

        if (tests_failed != 0)
            $fatal(1, "Framebuffer address tests failed");

        $finish;
    end

endmodule
