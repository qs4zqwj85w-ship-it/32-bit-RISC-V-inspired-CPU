module CPU_subword_tb;

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
        // PROGRAM: SB, LB, LBU
        // Instructions stored little-endian
        // =========================================

        // Address 0: addi x1, x0, 256
        // Machine code: 0x10000093
        dut.memory_inst.memory[0] = 8'h93;
        dut.memory_inst.memory[1] = 8'h00;
        dut.memory_inst.memory[2] = 8'h00;
        dut.memory_inst.memory[3] = 8'h10;

        // Address 4: addi x2, x0, -2
        // Machine code: 0xFFE00113
        dut.memory_inst.memory[4] = 8'h13;
        dut.memory_inst.memory[5] = 8'h01;
        dut.memory_inst.memory[6] = 8'hE0;
        dut.memory_inst.memory[7] = 8'hFF;

        // Address 8: sb x2, 0(x1)
        // Machine code: 0x00208023
        dut.memory_inst.memory[8]  = 8'h23;
        dut.memory_inst.memory[9]  = 8'h80;
        dut.memory_inst.memory[10] = 8'h20;
        dut.memory_inst.memory[11] = 8'h00;

        // Address 12: lb x10, 0(x1)
        // Machine code: 0x00008503
        dut.memory_inst.memory[12] = 8'h03;
        dut.memory_inst.memory[13] = 8'h85;
        dut.memory_inst.memory[14] = 8'h00;
        dut.memory_inst.memory[15] = 8'h00;

        // Address 16: lbu x11, 0(x1)
        // Machine code: 0x0000C583
        dut.memory_inst.memory[16] = 8'h83;
        dut.memory_inst.memory[17] = 8'hC5;
        dut.memory_inst.memory[18] = 8'h00;
        dut.memory_inst.memory[19] = 8'h00;

        // Address 20: sub x12, x11, x10
        // Machine code: 0x40A58633
        dut.memory_inst.memory[20] = 8'h33;
        dut.memory_inst.memory[21] = 8'h86;
        dut.memory_inst.memory[22] = 8'hA5;
        dut.memory_inst.memory[23] = 8'h40;

        // Address 24: jal x0, 0
        // Machine code: 0x0000006F
        dut.memory_inst.memory[24] = 8'h6F;
        dut.memory_inst.memory[25] = 8'h00;
        dut.memory_inst.memory[26] = 8'h00;
        dut.memory_inst.memory[27] = 8'h00;


        // =========================================
        // RELEASE RESET
        // =========================================
        repeat (2) @(posedge clk);

        @(negedge clk);
        reset = 1'b0;

        $display("\nCPU started: testing SB, LB, and LBU.");


        // =========================================
        // TEST 1: Wait for the program to execute
        // =========================================
        repeat (80) @(posedge clk);
        #1;

        // =========================================
        // TEST 2: Verify byte store
        // =========================================
        if (dut.memory_inst.memory[256] !== 8'hFE)
            $fatal(1, "FAIL: SB did not write FE to address 256");

        $display("PASS: SB wrote FE to address 256");


        // =========================================
        // TEST 3: Verify neighboring bytes unchanged
        // =========================================
        if (dut.memory_inst.memory[257] !== 8'h00 ||
            dut.memory_inst.memory[258] !== 8'h00 ||
            dut.memory_inst.memory[259] !== 8'h00)
            $fatal(1, "FAIL: SB modified neighboring bytes");

        $display("PASS: SB preserved neighboring bytes");


        // =========================================
        // TEST 4: Verify signed/unsigned loads
        // =========================================
        // LB should produce FFFFFFFE.
        // LBU should produce 000000FE.
        // Subtracting them gives 256.
        if (result !== 32'd256)
            $fatal(
                1,
                "FAIL: Expected result 256, got %0d (0x%08h)",
                result, result
            );

        $display("PASS: LB/LBU results verified through SUB");
        $display("Final result = %0d (0x%08h)", result, result);

        $display("\nALL CPU SUBWORD TESTS PASSED!");
        $finish;
    end

endmodule
