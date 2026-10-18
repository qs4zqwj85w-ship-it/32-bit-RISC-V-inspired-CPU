module mux4_32_tb;

    logic [1:0]  sel;
    logic [31:0] out;
    logic [31:0] in0, in1, in2, in3;

    mux4_32 dut (
        .in0(in0),
        .in1(in1),
        .in2(in2),
        .in3(in3),
        .sel(sel),
        .out(out)
    );

    initial begin
        // Initialize inputs
        sel = 2'b00;
        in0 = 32'h11111111;
        in1 = 32'h22222222;
        in2 = 32'h33333333;
        in3 = 32'h44444444;

        // =========================================
        // TEST 1: Select in0
        // =========================================
        $display("\nTEST 1: Select in0");

        sel = 2'b00;
        #1;

        if (out !== in0)
            $fatal(1, "FAIL: MUX4_32 did not select in0");

        $display("PASS: Selected in0 = %08h", out);


        // =========================================
        // TEST 2: Select in1
        // =========================================
        $display("\nTEST 2: Select in1");

        sel = 2'b01;
        #1;

        if (out !== in1)
            $fatal(1, "FAIL: MUX4_32 did not select in1");

        $display("PASS: Selected in1 = %08h", out);


        // =========================================
        // TEST 3: Select in2
        // =========================================
        $display("\nTEST 3: Select in2");

        sel = 2'b10;
        #1;

        if (out !== in2)
            $fatal(1, "FAIL: MUX4_32 did not select in2");

        $display("PASS: Selected in2 = %08h", out);


        // =========================================
        // TEST 4: Select in3
        // =========================================
        $display("\nTEST 4: Select in3");

        sel = 2'b11;
        #1;

        if (out !== in3)
            $fatal(1, "FAIL: MUX4_32 did not select in3");

        $display("PASS: Selected in3 = %08h", out);


        $display("\nALL MUX4_32 TESTS PASSED!");
        $finish;
    end

endmodule
