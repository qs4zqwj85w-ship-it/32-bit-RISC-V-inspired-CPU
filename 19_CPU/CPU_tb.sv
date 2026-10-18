// End to end TB are still above my level, below is LLM generated

module CPU_tb;

    logic        clk;
    logic        reset;
    logic [31:0] result;

    // Instantiate the CPU
    CPU dut (
        .clk(clk),
        .reset(reset),
        .result(result)
    );

    // 10-time-unit clock
    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        // =========================================
        // INITIALIZATION
        // =========================================
        reset = 1'b1;

        // Let memory's own initialization finish first
        #1;

        // =========================================
        // LOAD PROGRAM INTO SHARED MEMORY
        // Each array entry stores one byte.
        // Instructions are stored little-endian.
        // =========================================

        // Address 0: addi x1, x0, 5
        // Machine code: 0x00500093
        dut.memory_inst.memory[0] = 8'h93;
        dut.memory_inst.memory[1] = 8'h00;
        dut.memory_inst.memory[2] = 8'h50;
        dut.memory_inst.memory[3] = 8'h00;

        // Address 4: addi x2, x0, 7
        // Machine code: 0x00700113
        dut.memory_inst.memory[4] = 8'h13;
        dut.memory_inst.memory[5] = 8'h01;
        dut.memory_inst.memory[6] = 8'h70;
        dut.memory_inst.memory[7] = 8'h00;

        // Address 8: add x10, x1, x2
        // Machine code: 0x00208533
        dut.memory_inst.memory[8]  = 8'h33;
        dut.memory_inst.memory[9]  = 8'h85;
        dut.memory_inst.memory[10] = 8'h20;
        dut.memory_inst.memory[11] = 8'h00;

        // Address 12: jal x0, 0
        // Machine code: 0x0000006F
        // Loop here after computing the result.
        dut.memory_inst.memory[12] = 8'h6F;
        dut.memory_inst.memory[13] = 8'h00;
        dut.memory_inst.memory[14] = 8'h00;
        dut.memory_inst.memory[15] = 8'h00;


        // =========================================
        // RELEASE RESET
        // =========================================
        repeat (2) @(posedge clk);

        @(negedge clk);
        reset = 1'b0;

        $display("\nCPU started. Waiting for result = 12...");


        // =========================================
        // TEST 1: EXECUTE A COMPLETE PROGRAM
        // =========================================

        for (int cycle = 0; cycle < 100; cycle++) begin
            @(posedge clk);
            #1;

            if (result === 32'd12) begin
                $display("\nTEST 1 PASSED!");
                $display("  x1 = 5");
                $display("  x2 = 7");
                $display("  x10 = x1 + x2 = %0d", result);
                $display("  CPU executed the program successfully.");

                $finish;
            end
        end

        // The expected result never appeared
        $fatal(
            1,
            "CPU TEST FAILED: Expected result 12, got %08h after 100 cycles",
            result
        );

    end

endmodule
