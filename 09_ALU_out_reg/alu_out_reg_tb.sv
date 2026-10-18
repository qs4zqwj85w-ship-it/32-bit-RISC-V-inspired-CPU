module alu_out_reg_tb;

    logic        clk;
    logic        reset;
    logic        alu_out_reg_write_enable;
    logic [31:0] alu_out_reg_in;
    logic [31:0] alu_out_reg_out;

    alu_out_reg dut (
        .clk(clk),
        .reset(reset),
        .alu_out_reg_write_enable(alu_out_reg_write_enable),
        .alu_out_reg_in(alu_out_reg_in),
        .alu_out_reg_out(alu_out_reg_out)
    );

    // 10-time-unit clock
    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        // Initialize inputs
        reset = 1'b0;
        alu_out_reg_write_enable = 1'b0;
        alu_out_reg_in = 32'b0;


        // =========================================
        // TEST 1: Capture an ALU result
        // =========================================
        $display("\nTEST 1: ALU result capture");

        @(negedge clk);
        alu_out_reg_in = 32'h12345678;
        alu_out_reg_write_enable = 1'b1;

        @(posedge clk);
        #1;

        if (alu_out_reg_out !== 32'h12345678)
            $fatal(1, "FAIL: ALU output register did not capture input");

        $display("PASS: Captured ALU result %08h", alu_out_reg_out);


        // =========================================
        // TEST 2: Hold result when write enable = 0
        // =========================================
        $display("\nTEST 2: ALU output register hold");

        @(negedge clk);
        alu_out_reg_in = 32'hDEADBEEF;
        alu_out_reg_write_enable = 1'b0;

        @(posedge clk);
        #1;

        if (alu_out_reg_out !== 32'h12345678)
            $fatal(1, "FAIL: ALU output changed while write disabled");

        $display("PASS: Retained ALU result %08h", alu_out_reg_out);


        // =========================================
        // TEST 3: Reset takes priority over writing
        // =========================================
        $display("\nTEST 3: Reset priority");

        @(negedge clk);
        reset = 1'b1;
        alu_out_reg_write_enable = 1'b1;
        alu_out_reg_in = 32'hCAFEBABE;

        @(posedge clk);
        #1;

        if (alu_out_reg_out !== 32'h00000000)
            $fatal(1, "FAIL: Reset did not clear ALU output register");

        $display("PASS: Reset cleared register to %08h", alu_out_reg_out);


        $display("\nALL ALU OUTPUT REGISTER TESTS PASSED!");
        $finish;
    end

endmodule
