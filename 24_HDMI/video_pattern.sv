module video_pattern (
    input  logic [9:0] pixel_x,
    input  logic [9:0] pixel_y,
    input  logic       active_video,

    output logic [7:0] r,
    output logic [7:0] g,
    output logic [7:0] b
);

always_comb begin
    // 1. Default assignments to prevent latches
    r = 8'h00;
    g = 8'h00;
    b = 8'h00;

    // 2. Check active_video
    if (!active_video) begin
        // If inactive, output black (0, 0, 0)
        r = 8'h00;
        g = 8'h00;
        b = 8'h00;
    end else begin
        // 3. If active, determine the color using pixel_x
        // 4. Assign the appropriate RGB values (Example: 3-column color bars)
        if (pixel_x < 213) begin
            r = 8'hFF; // Red zone
            g = 8'h00;
            b = 8'h00;
        end else if (pixel_x < 426) begin
            r = 8'h00; // Green zone
            g = 8'hFF;
            b = 8'h00;
        end else begin
            r = 8'h00; // Blue zone
            g = 8'h00;
            b = 8'hFF;
        end
    end
end


endmodule
