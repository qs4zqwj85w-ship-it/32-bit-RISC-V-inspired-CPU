
module framebuffer_address #(
    parameter logic [31:0] FB_BASE = 32'h0010_0000
) (
    // Inputs from video timing
    input  logic [9:0] pixel_x,
    input  logic [9:0] pixel_y,
    input  logic       active_video,

    // Framebuffer address outputs
    output logic       pixel_valid,
    output logic [31:0] pixel_byte_addr,
    output logic [31:0] aligned_word_addr,
    output logic [1:0]  byte_lane
);

    logic [7:0]  framebuffer_y;
    logic [8:0]  framebuffer_x;
    logic [31:0] row_offset;

    always_comb begin

        // Convert 720x480 display coordinates
        // into 360x240 framebuffer coordinates.
        framebuffer_x = pixel_x[9:1];
        framebuffer_y = pixel_y[8:1];

        // Calculate framebuffer row offset:
        // framebuffer_y * 360
        //
        // 360 = 256 + 64 + 32 + 8
        row_offset =
            ({24'b0, framebuffer_y} << 8) +
            ({24'b0, framebuffer_y} << 6) +
            ({24'b0, framebuffer_y} << 5) +
            ({24'b0, framebuffer_y} << 3);

        // Check whether the current screen position is visible.
        pixel_valid =
            active_video &&
            (pixel_x < 10'd720) &&
            (pixel_y < 10'd480);

        // Default outputs outside the active display.
        pixel_byte_addr = FB_BASE;

        if (pixel_valid) begin
            pixel_byte_addr =
                FB_BASE + row_offset + {23'b0, framebuffer_x};
        end

        // SDRAM returns a complete 32-bit word.
        // Identify the aligned word and the pixel's byte position.
        aligned_word_addr = {
            pixel_byte_addr[31:2], 2'b00
        };

        byte_lane = pixel_byte_addr[1:0];

    end

endmodule
