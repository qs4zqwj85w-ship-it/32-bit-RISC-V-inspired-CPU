// video_pattern: a cartoon of the cream teddy bear with a woven bow tie and a
// raised paw, standing in front of a pebble beach, surf, sea and cloudy sky.
// 640x480 frame.
//
// Same ports and same always_comb structure as before (defaults first, then
// the active_video check, then an if / else-if chain that picks the colour).
// Only the shapes and colours changed.
//
// Shapes: every circle is "distance^2 from centre < radius^2", so there is no
// square root. The bear is symmetric about x = 250, so we mirror x about that
// line (ax) and describe one side; ears, eyes, smile arcs and bow-tie wings
// each need one description for both sides. The beach, surf and sea are
// diagonal bands (like the tilted photo): u = y + 0.625*x is constant along
// each band edge, and it only needs adders and shifts.
// The if / else-if chain is ordered top layer first: the first match wins.
module video_pattern (
    input  logic [9:0] pixel_x,
    input  logic [9:0] pixel_y,
    input  logic       active_video,

    output logic [7:0] r,
    output logic [7:0] g,
    output logic [7:0] b
);

    // ---------------------------------------------------------------
    // Helpers
    // ---------------------------------------------------------------
    // Squared distance between (px,py) and (cx,cy). Largest case is
    // 639^2 + 479^2 < 2^20, so 20 bits is enough.
    function automatic logic [19:0] dist2(
        input logic [9:0] px, input logic [9:0] py,
        input logic [9:0] cx, input logic [9:0] cy
    );
        logic [9:0] dx, dy;
        begin
            dx    = (px >= cx) ? (px - cx) : (cx - px);
            dy    = (py >= cy) ? (py - cy) : (cy - py);
            dist2 = dx * dx + dy * dy;
        end
    endfunction

    // Horizontal distance from the bear's centre line (x = 250).
    wire [9:0] ax = (pixel_x >= 10'd250) ? (pixel_x - 10'd250)
                                         : (10'd250 - pixel_x);

    // Diagonal coordinate for the scene: y + x/2 + x/8 (= y + 0.625 x).
    wire [10:0] u = {1'b0, pixel_y} + {2'b00, pixel_x[9:1]} + {4'b0000, pixel_x[9:3]};

    // Wavy surf edge: a 0..7 triangle wave along x, period 64 pixels.
    wire [2:0]  surf_wave  = pixel_x[5] ? ~pixel_x[4:2] : pixel_x[4:2];
    wire [10:0] foam_end = 11'd617 + {7'b0000000, surf_wave, 1'b0};   // 617 .. 631

    // Cheap pebble speckle: a fixed bit pattern from pixel_x / pixel_y.
    wire speck = pixel_x[1] ^ pixel_y[2] ^ (pixel_x[3] & pixel_y[1])
               ^ (pixel_x[4] & pixel_y[3]) ^ (pixel_x[2] & pixel_y[4]);

    // ---------------------------------------------------------------
    // Shape centres. For the mirrored shapes x is the offset from the centre
    // line (ax); everything else uses real pixel coordinates.
    // ---------------------------------------------------------------
    wire [19:0] d2_head   = dist2(ax,      pixel_y, 10'd0,   10'd262);
    wire [19:0] d2_ear    = dist2(ax,      pixel_y, 10'd88,  10'd165);
    wire [19:0] d2_eye    = dist2(ax,      pixel_y, 10'd44,  10'd238);
    wire [19:0] d2_muzzle = dist2(ax,      pixel_y, 10'd0,   10'd292);
    wire [19:0] d2_smile  = dist2(ax,      pixel_y, 10'd17,  10'd308);
    wire [19:0] d2_wing   = dist2(ax,      pixel_y, 10'd50,  10'd395);
    wire [19:0] d2_body   = dist2(pixel_x, pixel_y, 10'd250, 10'd560);
    wire [19:0] d2_arm    = dist2(pixel_x, pixel_y, 10'd360, 10'd410);
    wire [19:0] d2_paw    = dist2(pixel_x, pixel_y, 10'd395, 10'd345);
    wire [19:0] d2_cloud1 = dist2(pixel_x, pixel_y, 10'd90,  10'd62);
    wire [19:0] d2_cloud2 = dist2(pixel_x, pixel_y, 10'd140, 10'd80);
    wire [19:0] d2_cloud3 = dist2(pixel_x, pixel_y, 10'd520, 10'd70);

    // Radii squared. "OUT" is the outer edge, "IN" the inner edge of an outline.
    localparam [19:0] R2_HEAD_OUT = 20'd112 * 20'd112;
    localparam [19:0] R2_HEAD_IN  = 20'd108 * 20'd108;
    localparam [19:0] R2_EAR_OUT  = 20'd42  * 20'd42;
    localparam [19:0] R2_EAR_IN   = 20'd38  * 20'd38;
    localparam [19:0] R2_EAR_PINK = 20'd24  * 20'd24;
    localparam [19:0] R2_EYE      = 20'd11  * 20'd11;
    localparam [19:0] R2_MUZZLE   = 20'd54  * 20'd54;
    localparam [19:0] R2_SMILE_O  = 20'd17  * 20'd17;
    localparam [19:0] R2_SMILE_I  = 20'd14  * 20'd14;
    localparam [19:0] R2_WING_OUT = 20'd30  * 20'd30;
    localparam [19:0] R2_WING_IN  = 20'd27  * 20'd27;
    localparam [19:0] R2_BODY_OUT = 20'd190 * 20'd190;
    localparam [19:0] R2_BODY_IN  = 20'd186 * 20'd186;
    localparam [19:0] R2_ARM_OUT  = 20'd52  * 20'd52;
    localparam [19:0] R2_ARM_IN   = 20'd48  * 20'd48;
    localparam [19:0] R2_PAW_OUT  = 20'd44  * 20'd44;
    localparam [19:0] R2_PAW_IN   = 20'd40  * 20'd40;
    localparam [19:0] R2_CLOUD1   = 20'd42  * 20'd42;
    localparam [19:0] R2_CLOUD2   = 20'd32  * 20'd32;
    localparam [19:0] R2_CLOUD3   = 20'd38  * 20'd38;

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
            // 3. If active, pick the colour of the topmost shape at this pixel
            // 4. Assign RGB as {r, g, b} = 24'hRRGGBB

            // --- face details (topmost) ---
            if (d2_eye < R2_EYE)
                {r, g, b} = 24'h0B0B10;                       // eyes
            else if (pixel_y >= 10'd270 && pixel_y < 10'd292 &&
                     ax < ((10'd292 - pixel_y) >> 1) + 10'd5)
                {r, g, b} = 24'h8B5646;                       // brown nose (downward triangle)
            else if (ax < 10'd2 && pixel_y >= 10'd292 && pixel_y < 10'd308)
                {r, g, b} = 24'h6B3A2E;                       // line below the nose
            else if (pixel_y >= 10'd308 && d2_smile < R2_SMILE_O && d2_smile >= R2_SMILE_I)
                {r, g, b} = 24'h6B3A2E;                       // stitched smile (two lower arcs)

            // --- bow tie ---
            else if (ax < 10'd13 && pixel_y >= 10'd380 && pixel_y < 10'd410)
                {r, g, b} = 24'h9C8C77;                       // knot
            else if (d2_wing < R2_WING_OUT && d2_wing >= R2_WING_IN)
                {r, g, b} = 24'h9C8C77;                       // wing edge
            else if (d2_wing < R2_WING_OUT)
                {r, g, b} = 24'hB5A58F;                       // woven wings

            // --- head ---
            else if (d2_muzzle < R2_MUZZLE)
                {r, g, b} = 24'hF8F0E6;                       // lighter muzzle
            else if (d2_head < R2_HEAD_OUT && d2_head >= R2_HEAD_IN)
                {r, g, b} = 24'hC8B5A2;                       // head edge
            else if (d2_head < R2_HEAD_OUT)
                {r, g, b} = 24'hF1E6DB;                       // cream fur

            // --- ears (hidden where the head covers them) ---
            else if (d2_ear < R2_EAR_PINK)
                {r, g, b} = 24'hE3CFBF;                       // inner ear
            else if (d2_ear < R2_EAR_IN)
                {r, g, b} = 24'hF1E6DB;                       // ear fur
            else if (d2_ear < R2_EAR_OUT)
                {r, g, b} = 24'hC8B5A2;                       // ear edge

            // --- raised paw, arm, body ---
            else if (d2_paw < R2_PAW_OUT && d2_paw >= R2_PAW_IN)
                {r, g, b} = 24'hC8B5A2;
            else if (d2_paw < R2_PAW_OUT)
                {r, g, b} = 24'hF1E6DB;
            else if (d2_arm < R2_ARM_OUT && d2_arm >= R2_ARM_IN)
                {r, g, b} = 24'hC8B5A2;
            else if (d2_arm < R2_ARM_OUT)
                {r, g, b} = 24'hF1E6DB;
            else if (d2_body < R2_BODY_OUT && d2_body >= R2_BODY_IN)
                {r, g, b} = 24'hC8B5A2;
            else if (d2_body < R2_BODY_OUT)
                {r, g, b} = 24'hF1E6DB;

            // --- clouds ---
            else if (d2_cloud1 < R2_CLOUD1 || d2_cloud2 < R2_CLOUD2 || d2_cloud3 < R2_CLOUD3)
                {r, g, b} = 24'hF4F7FA;

            // --- sky, sea, surf, pebbles, wet stones (diagonal bands) ---
            else if (u < 11'd575) begin
                if      (pixel_y < 10'd120) {r, g, b} = 24'h3F7FC6;   // sky, top
                else if (pixel_y < 10'd240) {r, g, b} = 24'h5E96D2;
                else if (pixel_y < 10'd360) {r, g, b} = 24'h7FB0DC;
                else                        {r, g, b} = 24'hA3CBE8;   // sky, near horizon
            end
            else if (u < 11'd590)
                {r, g, b} = 24'h5B8FAE;                       // sea, light edge at the horizon
            else if (u < 11'd605)
                {r, g, b} = 24'h3E6880;                       // sea
            else if (u < foam_end)
                {r, g, b} = 24'hEAF4FA;                       // white surf
            else if (u < 11'd735)
                {r, g, b} = speck ? 24'h9A9A97 : 24'h70706E;  // pebble beach
            else
                {r, g, b} = 24'h2B3947;                       // wet dark stones
        end
    end

endmodule
