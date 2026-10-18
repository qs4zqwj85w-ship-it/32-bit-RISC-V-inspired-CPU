module op_AB_reg_tb;

    logic        clk;
    logic        reset;
    logic        op_AB_reg_write_enable;
    logic [31:0] op_AB_reg_in1;
    logic [31:0] op_AB_reg_in2;
    logic [31:0] op_AB_reg_out1;
    logic [31:0] op_AB_reg_out2;

    op_AB_reg dut (
        .clk(clk),
        .reset(reset),
        .op_AB_reg_write_enable(op_AB_reg_write_enable),
        .op_AB_reg_in1(op_AB_reg_in1),
        .op_AB_reg_in2(op_AB_reg_in2),
        .op_AB_reg_out1(op_AB_reg_out1),
        .op_AB_reg_out2(op_AB_reg_out2)
    );

    // 10-time-unit clock
    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        // Initialize inputs
        reset = 1'b0;
        op_AB_reg_write_enable = 1'b0;
        op_AB_reg_in1 = 32'b0;
        op_AB_reg_in2 = 32'b0;


        // =========================================
        // TEST 1: Capture a memory address
        // =========================================
        $display("\nTEST 1: OP_AB_REG capture");

        @(negedge clk);
        op_AB_reg_in1 = 32'h00000100;
        op_AB_reg_in2 = 32'h00000101;
        op_AB_reg_write_enable = 1'b1;

        @(posedge clk);
        #1;

        if (op_AB_reg_out1 !== 32'h00000100 || op_AB_reg_out2 !== 32'h00000101)
            $fatal(1, "FAIL: OP_AB_REG did not capture values");

        $display("PASS: OP_AB_REG captured values %08h %08h", op_AB_reg_out1, op_AB_reg_out2);


        // =========================================
        // TEST 2: Hold values when write enable = 0
        // =========================================
        $display("\nTEST 2: OP_AB_REG hold");

        @(negedge clk);
        op_AB_reg_in1 = 32'h00000200;
        op_AB_reg_in2 = 32'h00000201;
        op_AB_reg_write_enable = 1'b0;

        @(posedge clk);
        #1;

        if (op_AB_reg_out1 !== 32'h00000100 || op_AB_reg_out2 !== 32'h00000101)
            $fatal(1, "FAIL: OP_AB_REG changed while write disabled");

        $display("PASS: OP_AB_REG retained values %08h %08h", op_AB_reg_out1, op_AB_reg_out2);


        // =========================================
        // TEST 3: Reset clears the registers
        // =========================================
        $display("\nTEST 3: Reset clears OP_AB_REG");

        @(negedge clk);
        reset = 1'b1;
        op_AB_reg_write_enable = 1'b1;
        op_AB_reg_in1 = 32'h00000300;
        op_AB_reg_in2 = 32'h00000301;

        @(posedge clk);
        #1;

        if (op_AB_reg_out1 !== 32'h00000000 || op_AB_reg_out2 !== 32'h00000000)
            $fatal(1, "FAIL: Reset did not clear OP_AB_REG");

        $display("PASS: Reset cleared OP_AB_REG to %08h %08h", op_AB_reg_out1, op_AB_reg_out2);


        $display("\nALL OP_AB_REG TESTS PASSED!");
        $finish;
    end

endmodule
