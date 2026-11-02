
module framebuffer_line_scanout (
    input  logic       clk_pixel,
    input  logic       rst,

    // HDMI timing inputs
    input  logic [9:0] pixel_x,
    input  logic [9:0] pixel_y,
    input  logic       active_video,

    // Current display bank
    input  logic       display_bank,

    // Line-buffer read interface
    output logic       line_buffer_rd_en,
    output logic       line_buffer_bank,
    output logic [8:0] line_buffer_addr,
    input  logic [7:0] line_buffer_data,

    // RGB output
    output logic       pixel_valid,
    output logic [7:0] red,
    output logic [7:0] green,
    output logic [7:0] blue
);

    logic [8:0] framebuffer_x;

    logic [2:0] red_332;
    logic [2:0] green_332;
    logic [1:0] blue_332;

    // Pipeline valid signal to match synchronous BRAM read latency.
    logic pixel_valid_d;

    // Convert HDMI coordinates into framebuffer coordinates.
    always_comb begin

        framebuffer_x = pixel_x[9:1];

        line_buffer_rd_en =
            active_video &&
            (pixel_x < 10'd720) &&
            (pixel_y < 10'd480);

        line_buffer_bank = display_bank;
        line_buffer_addr = framebuffer_x;

    end

    // RGB332 conversion and output alignment.
    always_ff @(posedge clk_pixel) begin

        if (rst) begin
            pixel_valid_d <= 1'b0;
            pixel_valid   <= 1'b0;

            red   <= 8'b0;
            green <= 8'b0;
            blue  <= 8'b0;
        end
        else begin

            pixel_valid_d <= line_buffer_rd_en;
            pixel_valid   <= pixel_valid_d;

            if (pixel_valid_d) begin

                red_332   = line_buffer_data[7:5];
                green_332 = line_buffer_data[4:2];
                blue_332  = line_buffer_data[1:0];

                // Expand RGB332 channels to 8 bits.
                red   <= {red_332, red_332, red_332[2:1]};
                green <= {green_332, green_332, green_332[2:1]};
                blue  <= {blue_332, blue_332, blue_332, blue_332};

            end
            else begin
                red   <= 8'b0;
                green <= 8'b0;
                blue  <= 8'b0;
            end

        end
    end

endmodule
