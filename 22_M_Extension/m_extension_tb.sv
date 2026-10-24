module m_extension_tb;

    logic [31:0] operand_a;
    logic [31:0] operand_b;
    logic [2:0]  operation;
    logic [31:0] result;

    integer failures = 0;
    integer tests = 0;

    m_extension dut (
        .operand_a(operand_a),
        .operand_b(operand_b),
        .operation(operation),
        .result(result)
    );

    task automatic check_result(
        input logic [31:0] a,
        input logic [31:0] b,
        input logic [2:0]  op,
        input logic [31:0] expected,
        input string       test_name
    );
        begin
            operand_a = a;
            operand_b = b;
            operation = op;

            // Allow combinational logic to settle.
            #1;
            tests = tests + 1;

            if (result !== expected) begin
                $display(
                    "FAIL: %s | A=%h B=%h op=%b expected=%h got=%h",
                    test_name, a, b, op, expected, result
                );
                failures = failures + 1;
            end else begin
                $display(
                    "PASS: %s | result=%h",
                    test_name, result
                );
            end
        end
    endtask

    initial begin
        // A = -1 signed, or 4294967295 unsigned.
        // B = 2.

        check_result(
            32'hFFFFFFFF, 32'h00000002,
            3'b000, 32'hFFFFFFFE, "MUL"
        );

        check_result(
            32'hFFFFFFFF, 32'h00000002,
            3'b001, 32'hFFFFFFFF, "MULH"
        );

        check_result(
            32'hFFFFFFFF, 32'h00000002,
            3'b010, 32'hFFFFFFFF, "MULHSU"
        );

        check_result(
            32'hFFFFFFFF, 32'h00000002,
            3'b011, 32'h00000001, "MULHU"
        );

        // A = -2147483648 signed, B = 2.

        check_result(
            32'h80000000, 32'h00000002,
            3'b001, 32'hFFFFFFFF, "MULH: signed minimum"
        );

        check_result(
            32'h80000000, 32'h00000002,
            3'b011, 32'h00000001, "MULHU: same bits, unsigned"
        );

        // A is signed; B is unsigned.
        check_result(
            32'h80000000, 32'hFFFFFFFF,
            3'b010, 32'h80000000, "MULHSU: mixed signedness"
        );

        $display("");
        $display("Tests run: %0d", tests);
        $display("Failures:  %0d", failures);

        if (failures != 0)
            $fatal(1, "M-extension multiplier tests FAILED");
        else begin
            $display("All multiplier tests PASSED!");
            $finish;
        end
    end

endmodule
