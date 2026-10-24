// This testbench is abit too complicated for me so LLM was used to help with this one


module tb_m_division;

    localparam logic [2:0] OP_DIV  = 3'b100;
    localparam logic [2:0] OP_DIVU = 3'b101;
    localparam logic [2:0] OP_REM  = 3'b110;
    localparam logic [2:0] OP_REMU = 3'b111;

    logic        clk = 1'b0;
    logic        reset_n = 1'b0;
    logic        start = 1'b0;
    logic [31:0] dividend = 32'b0;
    logic [31:0] divisor = 32'b0;
    logic [2:0]  operation = 3'b0;

    logic        busy;
    logic        ready;
    logic        done;
    logic [31:0] result;

    integer tests_passed = 0;
    integer tests_failed = 0;

    always #5 clk = ~clk;

    m_division dut (
        .clk       (clk),
        .reset_n   (reset_n),
        .start     (start),
        .dividend  (dividend),
        .divisor   (divisor),
        .operation (operation),
        .busy      (busy),
        .ready     (ready),
        .done      (done),
        .result    (result)
    );

    task automatic check_case(
        input logic [2:0]  op,
        input logic [31:0] a,
        input logic [31:0] b,
        input logic [31:0] expected,
        input string       test_name
    );
        integer cycles;
        begin
            // Drive requests away from the active clock edge.
            @(negedge clk);
            while (ready !== 1'b1)
                @(negedge clk);

            operation = op;
            dividend  = a;
            divisor   = b;
            start     = 1'b1;

            // The next rising edge accepts the request.
            @(negedge clk);
            start = 1'b0;

            // Normal operations take 32 iterations plus finalization.
            // Division by zero takes the fast path.
            cycles = 0;
            while ((done !== 1'b1) && (cycles < 40)) begin
                @(posedge clk);
                #1;
                cycles = cycles + 1;
            end

            if (done !== 1'b1) begin
                tests_failed = tests_failed + 1;
                $error("TIMEOUT: %s op=%03b a=%08h b=%08h busy=%b ready=%b",
                       test_name, op, a, b, busy, ready);
            end else if (result !== expected) begin
                tests_failed = tests_failed + 1;
                $error("FAIL: %s op=%03b a=%08h b=%08h expected=%08h got=%08h",
                       test_name, op, a, b, expected, result);
            end else begin
                tests_passed = tests_passed + 1;
                $display("PASS: %-30s op=%03b a=%08h b=%08h result=%08h (%0d cycles)",
                         test_name, op, a, b, result, cycles);
            end

            // done should be a one-cycle pulse; the unit should be idle now.
            @(posedge clk);
            #1;
            if (done !== 1'b0 || ready !== 1'b1 || busy !== 1'b0) begin
                tests_failed = tests_failed + 1;
                $error("Handshake error after %s: done=%b ready=%b busy=%b",
                       test_name, done, ready, busy);
            end
        end
    endtask

    initial begin
        #23 reset_n = 1'b1;

        // Signed DIV: ordinary signs, truncation toward zero, and extremes.
        check_case(OP_DIV, 32'd10,         32'd3,          32'd3,          "DIV 10 / 3");
        check_case(OP_DIV, -32'sd10,       32'd3,          -32'sd3,        "DIV -10 / 3");
        check_case(OP_DIV, 32'd10,         -32'sd3,        -32'sd3,        "DIV 10 / -3");
        check_case(OP_DIV, -32'sd10,       -32'sd3,        32'd3,          "DIV -10 / -3");
        check_case(OP_DIV, -32'sd7,        32'd2,          -32'sd3,        "DIV -7 / 2 truncates toward zero");
        check_case(OP_DIV, 32'h8000_0000,   32'd1,          32'h8000_0000,  "DIV INT_MIN / 1");
        check_case(OP_DIV, 32'h8000_0000,   32'd2,          32'hC000_0000,  "DIV INT_MIN / 2");
        check_case(OP_DIV, 32'h7FFF_FFFF,   32'hFFFF_FFFF,  32'h8000_0001,  "DIV INT_MAX / -1");
        check_case(OP_DIV, 32'h8000_0000,   32'hFFFF_FFFF,  32'h8000_0000,  "DIV INT_MIN / -1 overflow");
        check_case(OP_DIV, 32'h8000_0000,   32'b0,          32'hFFFF_FFFF,  "DIV negative / zero");

        // Unsigned DIVU: high-bit-set values and largest operands.
        check_case(OP_DIVU, 32'd10,         32'd3,          32'd3,          "DIVU 10 / 3");
        check_case(OP_DIVU, 32'hFFFF_FFFF,  32'd2,          32'h7FFF_FFFF,  "DIVU UINT_MAX / 2");
        check_case(OP_DIVU, 32'hFFFF_FFFF,  32'hFFFF_FFFE,  32'd1,          "DIVU UINT_MAX / UINT_MAX-1");
        check_case(OP_DIVU, 32'h8000_0000,  32'd2,          32'h4000_0000,  "DIVU high-bit operand / 2");
        check_case(OP_DIVU, 32'hFFFF_FFFF,  32'hFFFF_FFFF,  32'd1,          "DIVU UINT_MAX / UINT_MAX");
        check_case(OP_DIVU, 32'h1234_5678,  32'b0,          32'hFFFF_FFFF,  "DIVU positive / zero");

        // Signed REM: remainder follows the dividend's sign.
        check_case(OP_REM, 32'd10,          32'd3,          32'd1,          "REM 10 % 3");
        check_case(OP_REM, -32'sd10,        32'd3,          -32'sd1,        "REM -10 % 3");
        check_case(OP_REM, 32'd10,          -32'sd3,        32'd1,          "REM 10 % -3");
        check_case(OP_REM, -32'sd10,        -32'sd3,        -32'sd1,        "REM -10 % -3");
        check_case(OP_REM, -32'sd7,         32'd2,          -32'sd1,        "REM -7 % 2");
        check_case(OP_REM, 32'h8000_0000,   32'hFFFF_FFFF,  32'd0,          "REM INT_MIN % -1 overflow");
        check_case(OP_REM, 32'h8000_0000,   32'b0,          32'h8000_0000,  "REM negative / zero");

        // Unsigned REMU: ordinary, high-bit-set, and extreme values.
        check_case(OP_REMU, 32'd10,         32'd3,          32'd1,          "REMU 10 % 3");
        check_case(OP_REMU, 32'hFFFF_FFFF,  32'd2,          32'd1,          "REMU UINT_MAX % 2");
        check_case(OP_REMU, 32'hFFFF_FFFF,  32'hFFFF_FFFE,  32'd1,          "REMU UINT_MAX % UINT_MAX-1");
        check_case(OP_REMU, 32'h8000_0000,  32'd3,          32'd2,          "REMU 0x80000000 % 3");
        check_case(OP_REMU, 32'hFFFF_FFFF,  32'd1,          32'd0,          "REMU UINT_MAX % 1");
        check_case(OP_REMU, 32'hFFFF_FFFF,  32'b0,          32'hFFFF_FFFF,  "REMU UINT_MAX / zero");

        $display("");
        $display("Division test summary: %0d passed, %0d failed", tests_passed, tests_failed);

        if (tests_failed != 0)
            $fatal(1, "m_division testbench failed");
        else
            $display("All m_division directed tests passed.");

        $finish;
    end

endmodule
