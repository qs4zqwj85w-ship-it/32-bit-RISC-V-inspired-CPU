//This test test 5 things, All 256 input bytes. All four control symbols. 
//Running-disparity behavior across consecutive active pixels. Reset and blanking behavior.
//The three DC-balancing branches (zero, same-sign, opposite-sign).
//This test bench have the all byte input exaustion test so I sued AI to generate the loop for that.
module tb_tmds_encoder;

logic clk_pixel;
logic rst;
logic video_active;
logic [1:0] control;
logic [7:0] data;
logic [9:0] tmds;

integer reference_disparity;

integer case_a_count;
integer case_b_count;
integer case_c_count;

integer i;
integer errors;

// ============================================================
// DUT
// ============================================================

tmds_encoder dut (
    .clk_pixel   (clk_pixel),
    .rst         (rst),
    .video_active(video_active),
    .control     (control),
    .data        (data),
    .tmds        (tmds)
);

// ============================================================
// Clock
// ============================================================

initial clk_pixel = 1'b0;
always #5 clk_pixel = ~clk_pixel;

// ============================================================
// Independent reference model
// ============================================================

task automatic reference_encode (
    input logic       active,
    input logic [1:0] ctrl,
    input logic [7:0] d,
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

        if (!active) begin
            case (ctrl)
                2'b00: expected = 10'b1101010100;
                2'b01: expected = 10'b0010101011;
                2'b10: expected = 10'b0101010100;
                2'b11: expected = 10'b1010101011;
            endcase

            reference_disparity = 0;
        end
        else begin

            // Stage 1: Transition minimization

            input_ones = $countones(d);
            use_xnor = (input_ones > 4) ||
                       ((input_ones == 4) && !d[0]);

            qm = 9'b0;
            qm[0] = d[0];

            for (k = 1; k < 8; k = k + 1) begin
                qm[k] = qm[k-1] ^ d[k] ^ use_xnor;
            end

            qm[8] = !use_xnor;

            // Stage 2: DC balancing

            output_ones = $countones(qm[7:0]);
            balance = 2 * output_ones - 8;

            if ((reference_disparity == 0) || (balance == 0)) begin

                case_a_count = case_a_count + 1;

                if (qm[8]) begin
                    expected = {2'b01, qm[7:0]};
                    reference_disparity =
                        reference_disparity + balance;
                end
                else begin
                    expected = {2'b10, ~qm[7:0]};
                    reference_disparity =
                        reference_disparity - balance;
                end

            end
            else if (
                ((reference_disparity > 0) && (balance > 0)) ||
                ((reference_disparity < 0) && (balance < 0))
            ) begin

                case_b_count = case_b_count + 1;

                expected = {1'b1, qm[8], ~qm[7:0]};

                reference_disparity =
                    reference_disparity - balance +
                    (qm[8] ? 2 : 0);

            end
            else begin

                case_c_count = case_c_count + 1;

                expected = {1'b0, qm[8], qm[7:0]};

                reference_disparity =
                    reference_disparity + balance -
                    (qm[8] ? 0 : 2);

            end
        end
    end

endtask

// ============================================================
// Apply one input and compare output
// ============================================================

task automatic check_pixel (
    input logic       active,
    input logic [1:0] ctrl,
    input logic [7:0] d
);

    logic [9:0] expected;

    begin
        @(negedge clk_pixel);

        video_active = active;
        control = ctrl;
        data = d;

        reference_encode(active, ctrl, d, expected);

        @(posedge clk_pixel);
        #1;

        if (tmds !== expected) begin
            $display("ERROR at input data = %h", d);
            $display("  video_active = %b", active);
            $display("  control      = %b", ctrl);
            $display("  expected     = %b", expected);
            $display("  actual       = %b", tmds);
            $display("  ref disparity = %0d", reference_disparity);
            errors = errors + 1;
            $fatal(1, "TMDS encoder mismatch");
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
        video_active = 1'b0;
        control = 2'b00;
        data = 8'b0;

        reference_disparity = 0;

        @(posedge clk_pixel);
        #1;

        if (tmds !== 10'b1101010100)
            $fatal(1, "Reset output symbol incorrect");

        @(negedge clk_pixel);
        rst = 1'b0;
    end

endtask

// ============================================================
// Main test
// ============================================================

initial begin

    rst = 1'b0;
    video_active = 1'b0;
    control = 2'b00;
    data = 8'b0;

    reference_disparity = 0;

    case_a_count = 0;
    case_b_count = 0;
    case_c_count = 0;

    errors = 0;

    $display("--------------------------------");
    $display("Starting TMDS encoder test");
    $display("--------------------------------");

    // --------------------------------------------------------
    // Test 1: Reset
    // --------------------------------------------------------

    $display("Test 1: Reset");
    reset_dut();

    // --------------------------------------------------------
    // Test 2: All four control symbols
    // --------------------------------------------------------

    $display("Test 2: Control symbols");

    for (i = 0; i < 4; i = i + 1)
        check_pixel(1'b0, i[1:0], 8'h00);

    // --------------------------------------------------------
    // Test 3: All 256 possible data values
    // --------------------------------------------------------

    $display("Test 3: Exhaustive 8-bit data test");

    for (i = 0; i < 256; i = i + 1)
        check_pixel(1'b1, 2'b00, i[7:0]);

    // --------------------------------------------------------
    // Test 4: Different data sequences
    // --------------------------------------------------------

    $display("Test 4: Extended data sequences");

    for (i = 0; i < 4096; i = i + 1) begin

        // Periodically insert blanking periods.
        if ((i % 37) == 0) begin
            check_pixel(1'b0, i[1:0], 8'h00);
        end
        else begin
            check_pixel(
                1'b1,
                2'b00,
                ((i * 37) ^ (i >> 2) ^ (i * 13)) & 8'hFF
            );
        end

    end

    // --------------------------------------------------------
    // Test 5: Reset during operation
    // --------------------------------------------------------

    $display("Test 5: Reset during operation");

    check_pixel(1'b1, 2'b00, 8'hFF);
    check_pixel(1'b1, 2'b00, 8'h00);

    reset_dut();

    check_pixel(1'b1, 2'b00, 8'hA5);
    check_pixel(1'b0, 2'b11, 8'h00);

    // --------------------------------------------------------
    // Results
    // --------------------------------------------------------

    $display("--------------------------------");
    $display("ALL TESTS PASSED");
    $display("Case A executions: %0d", case_a_count);
    $display("Case B executions: %0d", case_b_count);
    $display("Case C executions: %0d", case_c_count);
    $display("--------------------------------");

    if (case_a_count == 0 ||
        case_b_count == 0 ||
        case_c_count == 0)
        $fatal(1, "Not all DC balancing cases were exercised");

    $finish;

end

endmodule
