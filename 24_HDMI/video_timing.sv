module video_timing (
    input  logic        clk_pixel,
    input  logic        rst,

    output logic [9:0]  pixel_x,
    output logic [9:0]  pixel_y,
    output logic        hsync,
    output logic        vsync,
    output logic        active_video
);

logic [9:0] x_counter;
logic [9:0] y_counter;

assign pixel_x = x_counter;
assign pixel_y = y_counter;

// logic to go thru each and every pixel
always_ff @(posedge clk_pixel) begin
    if (rst) begin
        x_counter <= 10'd0;
        y_counter <= 10'd0;
    end
    else begin
        if (x_counter == 857) begin
            x_counter <= 10'd0;

            if (y_counter == 524) begin
                y_counter <= 10'd0;
            end
            else begin
                y_counter <= y_counter + 1;
            end
        end
        else begin
            x_counter <= x_counter + 1;
        end
    end
end


// logic for hsync and vsync

assign hsync = !(x_counter >= 736 && x_counter <= 797);
assign vsync = !(y_counter >= 489 && y_counter <= 494);
assign active_video = (x_counter < 720 && y_counter < 480);

endmodule
