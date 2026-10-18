module mux2_32_tb;

    logic        sel;
    logic [31:0] in0;
    logic [31:0] in1;
    logic [31:0] out;

    mux2_32 dut (
        .in0(in0),
        .in1(in1),
        .sel(sel),
        .out(out)
    );

    initial begin
        // Initialize inputs
        in0 = 32'hAAAAAAAA;
        in1 = 32'hBBBBBBBB;
        sel = 1'b0;

        // =========================================
        // TEST 1: Select in0
        // =========================================
        $display("\nTEST 1: Select in0");

        sel = 1'b0;
        #1;

        if (out !== in0)
            $fatal(1, "FAIL: MUX2_32 did not select in0");

        $display("PASS: Selected in0 = %08h", out);


        // =========================================
        // TEST 2: Select in1
        // =========================================
        $display("\nTEST 2: Select in1");

        sel = 1'b1;
        #1;

        if (out !== in1)
            $fatal(1, "FAIL: MUX2_32 did not select in1");

        $display("PASS: Selected in1 = %08h", out);


        $display("\nALL MUX2_32 TESTS PASSED!");
        $finish;
    end

endmodule
