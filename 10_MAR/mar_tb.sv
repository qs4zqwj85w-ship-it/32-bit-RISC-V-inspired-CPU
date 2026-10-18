module mar_tb;

    logic        clk;
    logic        reset;
    logic        mar_write_enable;
    logic [31:0] mar_in;
    logic [31:0] mar_out;

    mar dut (
        .clk(clk),
        .reset(reset),
        .mar_write_enable(mar_write_enable),
        .mar_in(mar_in),
        .mar_out(mar_out)
    );

    // 10-time-unit clock
    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        // Initialize inputs
        reset = 1'b0;
        mar_write_enable = 1'b0;
        mar_in = 32'b0;


        // =========================================
        // TEST 1: Capture a memory address
        // =========================================
        $display("\nTEST 1: MAR address capture");

        @(negedge clk);
        mar_in = 32'h00000100;
        mar_write_enable = 1'b1;

        @(posedge clk);
        #1;

        if (mar_out !== 32'h00000100)
            $fatal(1, "FAIL: MAR did not capture address");

        $display("PASS: MAR captured address %08h", mar_out);


        // =========================================
        // TEST 2: Hold address when write enable = 0
        // =========================================
        $display("\nTEST 2: MAR hold");

        @(negedge clk);
        mar_in = 32'h00000200;
        mar_write_enable = 1'b0;

        @(posedge clk);
        #1;

        if (mar_out !== 32'h00000100)
            $fatal(1, "FAIL: MAR changed while write disabled");

        $display("PASS: MAR retained address %08h", mar_out);


        // =========================================
        // TEST 3: Reset takes priority over writing
        // =========================================
        $display("\nTEST 3: Reset priority");

        @(negedge clk);
        reset = 1'b1;
        mar_write_enable = 1'b1;
        mar_in = 32'h00000300;

        @(posedge clk);
        #1;

        if (mar_out !== 32'h00000000)
            $fatal(1, "FAIL: Reset did not clear MAR");

        $display("PASS: Reset cleared MAR to %08h", mar_out);


        $display("\nALL MAR TESTS PASSED!");
        $finish;
    end

endmodule
