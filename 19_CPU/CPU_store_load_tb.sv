module CPU_store_load_tb;

    logic        clk;
    logic        reset;
    logic [31:0] result;

    // =========================================
    // DUT: Top-level CPU
    // =========================================
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

        // Allow memory initialization to finish
        #1;

        // =========================================
        // LOAD PROGRAM INTO MEMORY
        // Little-endian byte order
        // =========================================

        // Address 0: addi x1, x0, 256
        // x1 = 256 (data memory address)
        // Instruction: 0x10000093
        dut.memory_inst.memory[0] = 8'h93;
        dut.memory_inst.memory[1] = 8'h00;
        dut.memory_inst.memory[2] = 8'h00;
        dut.memory_inst.memory[3] = 8'h10;

        // Address 4: addi x2, x0, 42
        // x2 = 42 (value to store)
        // Instruction: 0x02A00113
        dut.memory_inst.memory[4] = 8'h13;
        dut.memory_inst.memory[5] = 8'h01;
        dut.memory_inst.memory[6] = 8'hA0;
        dut.memory_inst.memory[7] = 8'h02;

        // Address 8: addi x3, x0, 99
        // Decoy value: prevents 42 from being
        // the last register-write result before LW.
        // Instruction: 0x06300193
        dut.memory_inst.memory[8]  = 8'h93;
        dut.memory_inst.memory[9]  = 8'h01;
        dut.memory_inst.memory[10] = 8'h30;
        dut.memory_inst.memory[11] = 8'h06;

        // Address 12: sw x2, 0(x1)
        // memory[256..259] = 42
        // Instruction: 0x0020A023
        dut.memory_inst.memory[12] = 8'h23;
        dut.memory_inst.memory[13] = 8'hA0;
        dut.memory_inst.memory[14] = 8'h20;
        dut.memory_inst.memory[15] = 8'h00;

        // Address 16: lw x10, 0(x1)
        // x10 = memory[256]
        // Instruction: 0x0000A503
        dut.memory_inst.memory[16] = 8'h03;
        dut.memory_inst.memory[17] = 8'hA5;
        dut.memory_inst.memory[18] = 8'h00;
        dut.memory_inst.memory[19] = 8'h00;

        // Address 20: jal x0, 0
        // Loop forever after the test program
        // Instruction: 0x0000006F
        dut.memory_inst.memory[20] = 8'h6F;
        dut.memory_inst.memory[21] = 8'h00;
        dut.memory_inst.memory[22] = 8'h00;
        dut.memory_inst.memory[23] = 8'h00;


        // =========================================
        // RELEASE RESET
        // =========================================
        repeat (2) @(posedge clk);

        @(negedge clk);
        reset = 1'b0;

        $display("\nCPU started: testing SW and LW.");


        // =========================================
        // TEST 1: Execute the complete program
        // =========================================
        // Allow enough cycles for all instructions
        // and the final load writeback.
        repeat (60) @(posedge clk);
        #1;

        $display("\nTEST 1: Store/load program");
        $display("Debug result = %0d (0x%08h)", result, result);

        // =========================================
        // TEST 2: Verify SW changed memory correctly
        // =========================================
        if (dut.memory_inst.memory[256] !== 8'h2A ||
            dut.memory_inst.memory[257] !== 8'h00 ||
            dut.memory_inst.memory[258] !== 8'h00 ||
            dut.memory_inst.memory[259] !== 8'h00)
            $fatal(1, "FAIL: SW did not store 42 at address 256");

        $display("PASS: SW stored 42 at address 256");


        // =========================================
        // TEST 3: Verify LW/writeback result
        // =========================================
        if (result !== 32'd42)
            $fatal(1, "FAIL: Expected loaded result 42, got %0d", result);

        $display("PASS: LW read 42 and wrote it back");
        $display("\nALL CPU STORE/LOAD TESTS PASSED!");

        $finish;
    end

endmodule
