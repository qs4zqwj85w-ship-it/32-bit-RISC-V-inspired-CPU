
module tb_tmds_video_core;

logic clk_pixel;
logic rst;

logic [9:0] tmds_red;
logic [9:0] tmds_green;
logic [9:0] tmds_blue;

integer x;
integer y;
integer errors;

integer red_disparity;
integer green_disparity;
integer blue_disparity;

integer red_case_a, red_case_b, red_case_c;
integer green_case_a, green_case_b, green_case_c;
integer blue_case_a, blue_case_b, blue_case_c;

logic active;
logic hsync;
logic vsync;

logic [7:0] red_data;
logic [7:0] green_data;
logic [7:0] blue_data;

logic [9:0] expected_red;
logic [9:0] expected_green;
logic [9:0] expected_blue;

// ============================================================
// DUT
// ============================================================

tmds_video_core dut (
    .clk_pixel (clk_pixel),
    .rst       (rst),
    .tmds_red  (tmds_red),
    .tmds_green(tmds_green),
    .tmds_blue (tmds_blue)
);

// ============================================================
// Clock
// ============================================================

initial clk_pixel = 1'b0;
always #5 clk_pixel = ~clk_pixel;

// ============================================================
// Independent TMDS reference model
// ============================================================

task automatic reference_encode (
    input logic       video_active,
    input logic [1:0] control,
    input logic [7:0] data,
    inout integer     disparity,
    inout integer     case_a,
    inout integer     case_b,
    inout integer     case_c,
    output logic [9:0] expected
);

    logic [8:0] qm;
    logic use_xnor;

    integer input_ones;
    integer output_ones;
    integer balance;
    integer k;

    begin
        expected = 10'b0;

        if (!video_active) begin
            case (control)
                2'b00: expected = 10'b1101010100;
                2'b01: expected = 10'b0010101011;
                2'b10: expected = 10'b0101010100;
                2'b11: expected = 10'b1010101011;
            endcase

            disparity = 0;
        end
        else begin
            input_ones = $countones(data);

            use_xnor = (input_ones > 4) ||
                       ((input_ones == 4) && !data[0]);

            qm = 9'b0;
            qm[0] = data[0];

            for (k = 1; k < 8; k = k + 1)
                qm[k] = qm[k-1] ^ data[k] ^ use_xnor;

            qm[8] = !use_xnor;

            output_ones = $countones(qm[7:0]);
            balance = 2 * output_ones - 8;

            if ((disparity == 0) || (balance == 0)) begin
                case_a = case_a + 1;

                if (qm[8]) begin
                    expected = {2'b01, qm[7:0]};
                    disparity = disparity + balance;
                end
                else begin
                    expected = {2'b10, ~qm[7:0]};
                    disparity = disparity - balance;
                end
            end
            else if (
                ((disparity > 0) && (balance > 0)) ||
                ((disparity < 0) && (balance < 0))
            ) begin
                case_b = case_b + 1;

                expected = {1'b1, qm[8], ~qm[7:0]};

                disparity = disparity - balance +
                            (qm[8] ? 2 : 0);
            end
            else begin
                case_c = case_c + 1;

                expected = {1'b0, qm[8], qm[7:0]};

                disparity = disparity + balance -
                            (qm[8] ? 0 : 2);
            end
        end
    end

endtask

// ============================================================
// Generate expected video signals
// ============================================================

task automatic calculate_video;

    begin
        active = (x < 720 && y < 480);

        hsync = !(x >= 736 && x <= 797);
        vsync = !(y >= 489 && y <= 494);

        red_data = 8'h00;
        green_data = 8'h00;
        blue_data = 8'h00;

        if (active) begin
            if (x < 213) begin
                red_data = 8'hFF;
            end
            else if (x < 426) begin
                green_data = 8'hFF;
            end
            else begin
                blue_data = 8'hFF;
            end
        end
    end

endtask

// ============================================================
// Compare all three channels
// ============================================================

task automatic check_pixel;

    begin
        calculate_video();

        reference_encode(
            active, 2'b00, red_data,
            red_disparity,
            red_case_a, red_case_b, red_case_c,
            expected_red
        );

        reference_encode(
            active, 2'b00, green_data,
            green_disparity,
            green_case_a, green_case_b, green_case_c,
            expected_green
        );

        reference_encode(
            active, {vsync, hsync}, blue_data,
            blue_disparity,
            blue_case_a, blue_case_b, blue_case_c,
            expected_blue
        );

        @(posedge clk_pixel);
        #1;

        if (tmds_red !== expected_red ||
            tmds_green !== expected_green ||
            tmds_blue !== expected_blue) begin

            $display("ERROR at pixel (%0d, %0d)", x, y);
            $display("Active video: %b", active);

            $display("RED:   expected=%b actual=%b",
                     expected_red, tmds_red);

            $display("GREEN: expected=%b actual=%b",
                     expected_green, tmds_green);

            $display("BLUE:  expected=%b actual=%b",
                     expected_blue, tmds_blue);

            errors = errors + 1;
            $fatal(1, "TMDS video core mismatch");
        end

        // Advance expected pixel position.
        if (x == 857) begin
            x = 0;

            if (y == 524)
                y = 0;
            else
                y = y + 1;
        end
        else begin
            x = x + 1;
        end
    end

endtask

// ============================================================
// Reset
// ============================================================

task automatic reset_dut;

    begin
        @(negedge clk_pixel);

        rst = 1'b1;

        red_disparity = 0;
        green_disparity = 0;
        blue_disparity = 0;

        x = 0;
        y = 0;

        @(posedge clk_pixel);
        #1;

        if (tmds_red !== 10'b1101010100 ||
            tmds_green !== 10'b1101010100 ||
            tmds_blue !== 10'b1101010100)
            $fatal(1, "Reset output symbols incorrect");

        @(negedge clk_pixel);
        rst = 1'b0;
    end

endtask

// ============================================================
// Main test
// ============================================================

integer i;

initial begin

    rst = 1'b0;

    x = 0;
    y = 0;

    errors = 0;

    red_disparity = 0;
    green_disparity = 0;
    blue_disparity = 0;

    red_case_a = 0;
    red_case_b = 0;
    red_case_c = 0;

    green_case_a = 0;
    green_case_b = 0;
    green_case_c = 0;

    blue_case_a = 0;
    blue_case_b = 0;
    blue_case_c = 0;

    $display("--------------------------------");
    $display("Starting TMDS video core test");
    $display("--------------------------------");

    // Test 1: Reset

    $display("Test 1: Reset");
    reset_dut();

    // Test 2: Initial pixels

    $display("Test 2: Initial video pixels");

    for (i = 0; i < 1000; i = i + 1) begin
        check_pixel();
    end

    // Test 3: Full video frame

    $display("Test 3: Full 480p frame");

    for (i = 0; i < (858 * 525) - 1000; i = i + 1) begin
        check_pixel();
    end

    // Test 4: Reset during operation

    $display("Test 4: Reset during operation");

    reset_dut();

    for (i = 0; i < 100; i = i + 1) begin
        check_pixel();
    end 

    // Results

    $display("--------------------------------");
    $display("ALL TESTS PASSED");
    $display("Pixels checked: %0d", 858 * 525);
    $display("--------------------------------");

    $display("RED disparity cases:   A=%0d B=%0d C=%0d",
             red_case_a, red_case_b, red_case_c);

    $display("GREEN disparity cases: A=%0d B=%0d C=%0d",
             green_case_a, green_case_b, green_case_c);

    $display("BLUE disparity cases:  A=%0d B=%0d C=%0d",
             blue_case_a, blue_case_b, blue_case_c);

    $finish;

end

endmodule
