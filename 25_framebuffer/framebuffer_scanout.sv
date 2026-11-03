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
    output logic [7:0] blue,

    // Indicates completion of reading one framebuffer row
    output logic       read_complete
);

    logic [8:0] framebuffer_x;

    // Pipeline signals
    logic pixel_valid_d;
    logic final_pixel_d;

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

            final_pixel_d <= 1'b0;
            read_complete <= 1'b0;

            red   <= 8'b0;
            green <= 8'b0;
            blue  <= 8'b0;

        end
        else begin

            // Pipeline BRAM read validity.
            pixel_valid_d <= line_buffer_rd_en;
            pixel_valid   <= pixel_valid_d;

            // Identify and pipeline the final pixel of a framebuffer row.
            final_pixel_d <=
                line_buffer_rd_en &&
                (pixel_x == 10'd719) &&
                pixel_y[0];

            // Default: completion is a one-cycle pulse.
            read_complete <= 1'b0;

            if (pixel_valid_d) begin

                // Expand RGB332 channels to RGB888.
                red <= {
                    line_buffer_data[7:5],
                    line_buffer_data[7:5],
                    line_buffer_data[7:6]
                };

                green <= {
                    line_buffer_data[4:2],
                    line_buffer_data[4:2],
                    line_buffer_data[4:3]
                };

                blue <= {
                    line_buffer_data[1:0],
                    line_buffer_data[1:0],
                    line_buffer_data[1:0],
                    line_buffer_data[1:0]
                };

                // The final pixel has reached the output stage.
                if (final_pixel_d) begin
                    read_complete <= 1'b1;
                end

            end
            else begin

                red   <= 8'b0;
                green <= 8'b0;
                blue  <= 8'b0;

            end

        end
    end

endmodule
