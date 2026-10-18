module CPU_halfword_tb;

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
        // PROGRAM: SH, LH, LHU
        // Instructions stored little-endian
        // =========================================

        // Address 0: addi x1, x0, 256
        // x1 = data memory address 256
        // Machine code: 0x10000093
        dut.memory_inst.memory[0] = 8'h93;
        dut.memory_inst.memory[1] = 8'h00;
        dut.memory_inst.memory[2] = 8'h00;
        dut.memory_inst.memory[3] = 8'h10;

        // Address 4: lui x2, 0x8
        // x2 = 0x00008000
        // Machine code: 0x00008137
        dut.memory_inst.memory[4] = 8'h37;
        dut.memory_inst.memory[5] = 8'h81;
        dut.memory_inst.memory[6] = 8'h00;
        dut.memory_inst.memory[7] = 8'h00;

        // Address 8: addi x2, x2, 1
        // x2 = 0x00008001
        // Machine code: 0x00110113
        dut.memory_inst.memory[8]  = 8'h13;
        dut.memory_inst.memory[9]  = 8'h01;
        dut.memory_inst.memory[10] = 8'h11;
        dut.memory_inst.memory[11] = 8'h00;

        // Address 12: sh x2, 0(x1)
        // Store 0x8001 at byte addresses 256-257
        // Machine code: 0x00209023
        dut.memory_inst.memory[12] = 8'h23;
        dut.memory_inst.memory[13] = 8'h90;
        dut.memory_inst.memory[14] = 8'h20;
        dut.memory_inst.memory[15] = 8'h00;

        // Address 16: lh x10, 0(x1)
        // Expected: 0xFFFF8001
        // Machine code: 0x00009503
        dut.memory_inst.memory[16] = 8'h03;
        dut.memory_inst.memory[17] = 8'h95;
        dut.memory_inst.memory[18] = 8'h00;
        dut.memory_inst.memory[19] = 8'h00;

        // Address 20: lhu x11, 0(x1)
        // Expected: 0x00008001
        // Machine code: 0x0000D583
        dut.memory_inst.memory[20] = 8'h83;
        dut.memory_inst.memory[21] = 8'hD5;
        dut.memory_inst.memory[22] = 8'h00;
        dut.memory_inst.memory[23] = 8'h00;

        // Address 24: sub x12, x11, x10
        // 0x00008001 - 0xFFFF8001 = 0x00010000
        // Machine code: 0x40A58633
        dut.memory_inst.memory[24] = 8'h33;
        dut.memory_inst.memory[25] = 8'h86;
        dut.memory_inst.memory[26] = 8'hA5;
        dut.memory_inst.memory[27] = 8'h40;

        // Address 28: jal x0, 0
        // Loop forever after the program finishes
        // Machine code: 0x0000006F
        dut.memory_inst.memory[28] = 8'h6F;
        dut.memory_inst.memory[29] = 8'h00;
        dut.memory_inst.memory[30] = 8'h00;
        dut.memory_inst.memory[31] = 8'h00;

        // =========================================
        // SEED NEIGHBORING BYTES
        // Verify SH doesn't overwrite adjacent bytes
        // =========================================
        dut.memory_inst.memory[255] = 8'hA5;
        dut.memory_inst.memory[258] = 8'h5A;
        dut.memory_inst.memory[259] = 8'hC3;


        // =========================================
        // RELEASE RESET
        // =========================================
        repeat (2) @(posedge clk);

        @(negedge clk);
        reset = 1'b0;

        $display("\nCPU started: testing SH, LH, and LHU.");

        // =========================================
        // TEST 1: Wait for the program to execute
        // =========================================
        repeat (100) @(posedge clk);
        #1;

        // =========================================
        // TEST 2: Verify SH stored the right bytes
        // =========================================
        if (dut.memory_inst.memory[256] !== 8'h01 ||
            dut.memory_inst.memory[257] !== 8'h80)
            $fatal(1, "FAIL: SH did not store 0x8001 correctly");

        $display("PASS: SH stored 0x8001 at address 256");


        // =========================================
        // TEST 3: Verify neighboring bytes unchanged
        // =========================================
        if (dut.memory_inst.memory[255] !== 8'hA5 ||
            dut.memory_inst.memory[258] !== 8'h5A ||
            dut.memory_inst.memory[259] !== 8'hC3)
            $fatal(1, "FAIL: SH modified neighboring bytes");

        $display("PASS: SH preserved neighboring bytes");


        // =========================================
        // TEST 4: Verify signed and unsigned loads
        // LH  should return 0xFFFF8001
        // LHU should return 0x00008001
        // Their difference should be 65536
        // =========================================
        if (result !== 32'd65536)
            $fatal(
                1,
                "FAIL: Expected 65536, got %0d (0x%08h)",
                result, result
            );

        $display("PASS: LH/LHU sign extension verified");
        $display("Final result = %0d (0x%08h)", result, result);

        $display("\nALL CPU HALFWORD TESTS PASSED!");
        $finish;
    end

endmodule

