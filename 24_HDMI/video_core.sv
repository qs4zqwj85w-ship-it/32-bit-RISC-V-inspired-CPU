module video_core (
    input  logic       clk_pixel,
    input  logic       rst,

    output logic       hsync,
    output logic       vsync,

    output logic [7:0] red,
    output logic [7:0] green,
    output logic [7:0] blue,
    output logic active_video
);
logic [9:0] pixel_x;
logic [9:0] pixel_y;

video_timing video_timing_inst (
    .clk_pixel   (clk_pixel),
    .rst         (rst),
    .pixel_x     (pixel_x),
    .pixel_y     (pixel_y),
    .hsync       (hsync),
    .vsync       (vsync),
    .active_video(active_video)
);

video_pattern video_pattern_inst (
    .pixel_x     (pixel_x),
    .pixel_y     (pixel_y),
    .active_video(active_video),
    .r           (red),
    .g           (green),
    .b           (blue)
);


endmodule
