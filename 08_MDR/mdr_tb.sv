module mdr_tb;

    logic        clk;
    logic        reset;
    logic        mdr_write_enable;
    logic [31:0] mdr_in;
    logic [31:0] mdr_out;

    mdr dut (
        .clk(clk),
        .reset(reset),
        .mdr_write_enable(mdr_write_enable),
        .mdr_in(mdr_in),
        .mdr_out(mdr_out)
    );

    // 10-time-unit clock
    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        // Initialize inputs
        reset = 1'b0;
        mdr_write_enable = 1'b0;
        mdr_in = 32'b0;


        // =========================================
        // TEST 1: Capture memory data
        // =========================================
        $display("\nTEST 1: Memory data capture");

        @(negedge clk);
        mdr_in = 32'hDEADBEEF;
        mdr_write_enable = 1'b1;

        @(posedge clk);
        #1;

        if (mdr_out !== 32'hDEADBEEF)
            $fatal(1, "FAIL: MDR did not capture memory data");

        $display("PASS: MDR captured %08h", mdr_out);


        // =========================================
        // TEST 2: Hold data when write enable = 0
        // =========================================
        $display("\nTEST 2: MDR hold");

        @(negedge clk);
        mdr_in = 32'h12345678;
        mdr_write_enable = 1'b0;

        @(posedge clk);
        #1;

        if (mdr_out !== 32'hDEADBEEF)
            $fatal(1, "FAIL: MDR changed while write disabled");

        $display("PASS: MDR retained %08h", mdr_out);


        // =========================================
        // TEST 3: Reset takes priority over writing
        // =========================================
        $display("\nTEST 3: Reset priority");

        @(negedge clk);
        reset = 1'b1;
        mdr_write_enable = 1'b1;
        mdr_in = 32'hCAFEBABE;

        @(posedge clk);
        #1;

        if (mdr_out !== 32'h00000000)
            $fatal(1, "FAIL: Reset did not clear MDR");

        $display("PASS: Reset cleared MDR to %08h", mdr_out);


        $display("\nALL MDR TESTS PASSED!");
        $finish;
    end

endmodule
