module instruction_reg_tb;

    logic        clk;
    logic        reset;
    logic        ir_write_enable;
    logic [31:0] instruction_in;
    logic [31:0] instruction_out;

    instruction_reg dut (
        .clk(clk),
        .reset(reset),
        .ir_write_enable(ir_write_enable),
        .instruction_in(instruction_in),
        .instruction_out(instruction_out)
    );

    // Generate a 10-time-unit clock
    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        // Initialize inputs
        reset = 1'b0;
        ir_write_enable = 1'b0;
        instruction_in = 32'b0;


        // =========================================
        // TEST 1: Normal instruction write and read
        // =========================================
        $display("\nTEST 1: Instruction write and read");

        @(negedge clk);
        instruction_in = 32'h00C58533;
        ir_write_enable = 1'b1;

        @(posedge clk);
        #1;

        if (instruction_out !== 32'h00C58533)
            $fatal(1, "FAIL: Instruction write/read");

        $display("PASS: Instruction captured: %08h",
                 instruction_out);


        // =========================================
        // TEST 2: Write disabled; instruction holds
        // =========================================
        $display("\nTEST 2: Instruction holds when enable is 0");

        @(negedge clk);
        instruction_in = 32'hDEADBEEF;
        ir_write_enable = 1'b0;

        @(posedge clk);
        #1;

        if (instruction_out !== 32'h00C58533)
            $fatal(1, "FAIL: Instruction changed while write disabled");

        $display("PASS: Previous instruction retained: %08h",
                 instruction_out);


        // =========================================
        // TEST 3: Reset clears the instruction
        // =========================================
        $display("\nTEST 3: Reset clears instruction");

        @(negedge clk);
        reset = 1'b1;
        ir_write_enable = 1'b1;
        instruction_in = 32'hFFFFFFFF;

        @(posedge clk);
        #1;

        if (instruction_out !== 32'h00000000)
            $fatal(1, "FAIL: Reset did not clear instruction");

        $display("PASS: Reset cleared instruction: %08h",
                 instruction_out);


        $display("\nALL INSTRUCTION REGISTER TESTS PASSED!");
        $finish;
    end

endmodule
