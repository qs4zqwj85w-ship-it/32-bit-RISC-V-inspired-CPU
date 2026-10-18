module alu_input_muxes_tb;

    logic [31:0] pc_out;
    logic [31:0] mar_out;
    logic [31:0] operand_a;
    logic [31:0] operand_b;
    logic [31:0] immediate;

    logic [1:0] alu_a_sel;
    logic [1:0] alu_b_sel;

    logic [31:0] alu_a;
    logic [31:0] alu_b;

    alu_input_muxes dut (
        .pc_out(pc_out),
        .mar_out(mar_out),
        .operand_a(operand_a),
        .operand_b(operand_b),
        .immediate(immediate),
        .alu_a_sel(alu_a_sel),
        .alu_b_sel(alu_b_sel),
        .alu_a(alu_a),
        .alu_b(alu_b)
    );

    // Check both ALU mux outputs
    task automatic check_alu_mux(
        input logic [31:0] pc_val,
        input logic [31:0] mar_val,
        input logic [31:0] operand_a_val,
        input logic [31:0] operand_b_val,
        input logic [31:0] immediate_val,
        input logic [1:0]  a_sel,
        input logic [1:0]  b_sel,
        input logic [31:0] expected_a,
        input logic [31:0] expected_b,
        input string test_name
    );
        begin
            // Drive the actual testbench signals
            pc_out    = pc_val;
            mar_out   = mar_val;
            operand_a = operand_a_val;
            operand_b = operand_b_val;
            immediate = immediate_val;
            alu_a_sel = a_sel;
            alu_b_sel = b_sel;

            // Allow combinational logic to settle
            #1;

            if (alu_a !== expected_a || alu_b !== expected_b)
                $fatal(
                    1,
                    "FAIL: %s | A=%08h expected=%08h B=%08h expected=%08h",
                    test_name, alu_a, expected_a, alu_b, expected_b
                );

            $display("PASS: %s", test_name);
        end
    endtask

    initial begin

        // =========================================
        // TEST 1: ALU A selects PC
        // =========================================
        check_alu_mux(
            32'd10, 32'd11, 32'd12, 32'd13, 32'd14,
            2'b00, 2'b00,
            32'd10, 32'd13,
            "ALU A selects PC"
        );

        // =========================================
        // TEST 2: ALU A selects MAR
        // =========================================
        check_alu_mux(
            32'd10, 32'd11, 32'd12, 32'd13, 32'd14,
            2'b01, 2'b00,
            32'd11, 32'd13,
            "ALU A selects MAR"
        );

        // =========================================
        // TEST 3: ALU A selects Operand A
        // =========================================
        check_alu_mux(
            32'd10, 32'd11, 32'd12, 32'd13, 32'd14,
            2'b10, 2'b00,
            32'd12, 32'd13,
            "ALU A selects Operand A"
        );

        // =========================================
        // TEST 4: ALU A selects zero
        // =========================================
        check_alu_mux(
            32'd10, 32'd11, 32'd12, 32'd13, 32'd14,
            2'b11, 2'b00,
            32'd0, 32'd13,
            "ALU A selects zero"
        );

        // =========================================
        // TEST 5: ALU B selects Operand B
        // =========================================
        check_alu_mux(
            32'd10, 32'd11, 32'd12, 32'd13, 32'd14,
            2'b10, 2'b00,
            32'd12, 32'd13,
            "ALU B selects Operand B"
        );

        // =========================================
        // TEST 6: ALU B selects immediate
        // =========================================
        check_alu_mux(
            32'd10, 32'd11, 32'd12, 32'd13, 32'd14,
            2'b10, 2'b01,
            32'd12, 32'd14,
            "ALU B selects immediate"
        );

        // =========================================
        // TEST 7: ALU B selects constant 4
        // =========================================
        check_alu_mux(
            32'd10, 32'd11, 32'd12, 32'd13, 32'd14,
            2'b10, 2'b10,
            32'd12, 32'd4,
            "ALU B selects constant 4"
        );

        // =========================================
        // TEST 8: ALU B selects zero
        // =========================================
        check_alu_mux(
            32'd10, 32'd11, 32'd12, 32'd13, 32'd14,
            2'b10, 2'b11,
            32'd12, 32'd0,
            "ALU B selects zero"
        );

        $display("\nALL ALU INPUT MUX TESTS PASSED!");
        $finish;
    end

endmodule
