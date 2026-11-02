module tmds_video_core (
    input  logic       clk_pixel,
    input  logic       rst,

    output logic [9:0] tmds_red,
    output logic [9:0] tmds_green,
    output logic [9:0] tmds_blue

    input  logic [7:0] line_buffer_data,
    input  logic       display_bank,

    output logic       line_buffer_rd_en,
    output logic       line_buffer_bank,
    output logic [8:0] line_buffer_addr
);

logic       hsync;
logic       vsync;
logic       active_video;

logic [7:0] red;
logic [7:0] green;
logic [7:0] blue;

video_core video_core_inst (
    .clk_pixel   (clk_pixel),
    .rst         (rst),
    .hsync       (hsync),
    .vsync       (vsync),
    .red         (red),
    .green       (green),
    .blue        (blue),
    .active_video(active_video)
);

tmds_encoder tmds_red_encoder (
    .clk_pixel   (clk_pixel),
    .rst         (rst),
    .video_active(active_video),
    .control     (2'b00),
    .data        (red),
    .tmds        (tmds_red)
);

tmds_encoder tmds_green_encoder (
    .clk_pixel   (clk_pixel),
    .rst         (rst),
    .video_active(active_video),
    .control     (2'b00),
    .data        (green),
    .tmds        (tmds_green)
);

tmds_encoder tmds_blue_encoder (
    .clk_pixel   (clk_pixel),
    .rst         (rst),
    .video_active(active_video),
    .control     ({vsync, hsync}),
    .data        (blue),
    .tmds        (tmds_blue)
);


endmodule
