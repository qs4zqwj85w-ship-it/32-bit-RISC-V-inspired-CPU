module branch_control_tb;

    logic [2:0]  branch_type;
    logic [31:0] operand_a;
    logic [31:0] operand_b;
    logic        branch_taken;

    branch_control dut (
        .branch_type(branch_type),
        .operand_a(operand_a),
        .operand_b(operand_b),
        .branch_taken(branch_taken)
    );

    // Check one branch-control test
    task automatic check_branch(
        input logic [2:0]  test_type,
        input logic [31:0] test_a,
        input logic [31:0] test_b,
        input logic        expected,
        input string       test_name
    );
        begin
            branch_type = test_type;
            operand_a   = test_a;
            operand_b   = test_b;

            // Allow combinational logic to settle
            #1;

            if (branch_taken !== expected)
                $fatal(
                    1,
                    "FAIL: %s | type=%b A=%08h B=%08h expected=%b got=%b",
                    test_name, test_type, test_a, test_b,
                    expected, branch_taken
                );

            $display("PASS: %s", test_name);
        end
    endtask

    initial begin

        // =========================================
        // TEST 1: No branch
        // =========================================
        check_branch(
            3'b000, 32'd5, 32'd5, 1'b0,
            "No branch"
        );

        // =========================================
        // TEST 2: BEQ - equal operands
        // =========================================
        check_branch(
            3'b001, 32'd5, 32'd5, 1'b1,
            "BEQ: equal"
        );

        // =========================================
        // TEST 3: BNE - different operands
        // =========================================
        check_branch(
            3'b010, 32'd5, 32'd4, 1'b1,
            "BNE: not equal"
        );

        // =========================================
        // TEST 4: BLT - signed comparison
        // -1 < 1 is true
        // =========================================
        check_branch(
            3'b011, 32'hFFFFFFFF, 32'd1, 1'b1,
            "BLT: signed -1 < 1"
        );

        // =========================================
        // TEST 5: BGE - signed comparison
        // 1 >= -1 is true
        // =========================================
        check_branch(
            3'b100, 32'd1, 32'hFFFFFFFF, 1'b1,
            "BGE: signed 1 >= -1"
        );

        // =========================================
        // TEST 6: BLTU - unsigned comparison
        // 4294967295 < 1 is false
        // =========================================
        check_branch(
            3'b101, 32'hFFFFFFFF, 32'd1, 1'b0,
            "BLTU: unsigned max < 1 is false"
        );

        // =========================================
        // TEST 7: BGEU - unsigned comparison
        // 4294967295 >= 1 is true
        // =========================================
        check_branch(
            3'b110, 32'hFFFFFFFF, 32'd1, 1'b1,
            "BGEU: unsigned max >= 1"
        );

        // =========================================
        // TEST 8: Reserved branch encoding
        // =========================================
        check_branch(
            3'b111, 32'd5, 32'd1, 1'b0,
            "Reserved encoding: no branch"
        );

        // =========================================
        // TEST 9: Signed and unsigned differ
        // 0xFFFFFFFF means -1 signed, but 4294967295 unsigned
        // =========================================
        check_branch(
            3'b011, 32'hFFFFFFFF, 32'd1, 1'b1,
            "Signed -1 < 1"
        );

        check_branch(
            3'b101, 32'hFFFFFFFF, 32'd1, 1'b0,
            "Unsigned max < 1 is false"
        );

        $display("\nALL BRANCH CONTROL TESTS PASSED!");
        $finish;
    end

endmodule
