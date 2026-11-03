module video_core (
    input  logic       clk_pixel,
    input  logic       rst,

    // Line-buffer interface
    input  logic [7:0] line_buffer_data,
    input  logic       display_bank,

    output logic       line_buffer_rd_en,
    output logic       line_buffer_bank,
    output logic [8:0] line_buffer_addr,

    // HDMI timing and RGB
    output logic       hsync,
    output logic       vsync,
    output logic [7:0] red,
    output logic [7:0] green,
    output logic [7:0] blue,
    output logic       active_video,

    // Framebuffer row completion
    output logic       read_complete
);

    logic [9:0] pixel_x;
    logic [9:0] pixel_y;

    logic       raw_hsync;
    logic       raw_vsync;
    logic       raw_active_video;

    // Original video timing generator.
    video_timing video_timing_inst (
        .clk_pixel    (clk_pixel),
        .rst          (rst),
        .pixel_x      (pixel_x),
        .pixel_y      (pixel_y),
        .hsync        (raw_hsync),
        .vsync        (raw_vsync),
        .active_video (raw_active_video)
    );

    // Framebuffer scanout.
    framebuffer_line_scanout framebuffer_line_scanout_inst (
        .clk_pixel          (clk_pixel),
        .rst                (rst),

        .pixel_x            (pixel_x),
        .pixel_y            (pixel_y),
        .active_video       (raw_active_video),

        .display_bank       (display_bank),

        .line_buffer_rd_en  (line_buffer_rd_en),
        .line_buffer_bank   (line_buffer_bank),
        .line_buffer_addr   (line_buffer_addr),
        .line_buffer_data   (line_buffer_data),

        .pixel_valid        (active_video),
        .red                (red),
        .green              (green),
        .blue               (blue),

        .read_complete      (read_complete)
    );

    // Align synchronization signals with scanout latency.
    logic [1:0] hsync_delay;
    logic [1:0] vsync_delay;

    always_ff @(posedge clk_pixel) begin
        if (rst) begin
            hsync_delay <= 2'b0;
            vsync_delay <= 2'b0;
        end
        else begin
            hsync_delay <= {hsync_delay[0], raw_hsync};
            vsync_delay <= {vsync_delay[0], raw_vsync};
        end
    end

    assign hsync = hsync_delay[1];
    assign vsync = vsync_delay[1];

endmodule
