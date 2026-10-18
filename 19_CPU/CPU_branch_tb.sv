module CPU_branch_tb;

    logic clk, reset;
    logic [31:0] result;

    CPU dut (
        .clk(clk),
        .reset(reset),
        .result(result)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Write one 32-bit instruction into byte-addressable memory.
    task automatic put_instruction(
        input integer addr,
        input logic [31:0] instruction
    );
        begin
            dut.memory_inst.memory[addr]   = instruction[7:0];
            dut.memory_inst.memory[addr+1] = instruction[15:8];
            dut.memory_inst.memory[addr+2] = instruction[23:16];
            dut.memory_inst.memory[addr+3] = instruction[31:24];
        end
    endtask

    initial begin
        reset = 1'b1;
        #1;

        // Initialize two equal operands.
        put_instruction(0,  32'h00500093); // addi x1,x0,5
        put_instruction(4,  32'h00500113); // addi x2,x0,5

        // Initialize registers used to detect wrong paths.
        put_instruction(8,  32'h00000193); // addi x3,x0,0
        put_instruction(12, 32'h00000293); // addi x5,x0,0
        put_instruction(16, 32'h00000313); // addi x6,x0,0
        put_instruction(20, 32'h00000393); // addi x7,x0,0
        put_instruction(24, 32'h00000413); // addi x8,x0,0

        // BEQ: equal, taken. Skip the x3=99 instruction.
        put_instruction(28, 32'h00208463); // beq x1,x2,+8
        put_instruction(32, 32'h06300193); // addi x3,x0,99 (must skip)

        // BNE: equal, not taken. Execute x4=2.
        put_instruction(36, 32'h00209463); // bne x1,x2,+8
        put_instruction(40, 32'h00200213); // addi x4,x0,2

        // Change operands to signed -1 and 1.
        put_instruction(44, 32'hFFF00093); // addi x1,x0,-1
        put_instruction(48, 32'h00100113); // addi x2,x0,1

        // BLT: signed -1 < 1, taken. Skip x5=99.
        put_instruction(52, 32'h0020C463); // blt x1,x2,+8
        put_instruction(56, 32'h06300293); // addi x5,x0,99 (must skip)

        // BGE: signed -1 >= 1, false. Execute x6=4.
        put_instruction(60, 32'h0020D463); // bge x1,x2,+8
        put_instruction(64, 32'h00400313); // addi x6,x0,4

        // BLTU: unsigned 0xFFFFFFFF < 1, false.
        put_instruction(68, 32'h0020E463); // bltu x1,x2,+8
        put_instruction(72, 32'h00500393); // addi x7,x0,5

        // BGEU: unsigned 0xFFFFFFFF >= 1, taken.
        // Skip the x8=99 instruction.
        put_instruction(76, 32'h0020F463); // bgeu x1,x2,+8
        put_instruction(80, 32'h06300413); // addi x8,x0,99 (must skip)

        put_instruction(84, 32'h02A00513); // addi x10,x0,42
        put_instruction(88, 32'h0000006F); // jal x0,0 (loop)

        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 1'b0;

        // Allow the program to execute.
        repeat (180) @(posedge clk);
        #1;

        // Check the branch-skipped paths.
        if (dut.regfile_inst.registers[3] !== 32'd0)
            $fatal(1, "FAIL: BEQ did not skip its wrong path");

        if (dut.regfile_inst.registers[5] !== 32'd0)
            $fatal(1, "FAIL: BLT did not skip its wrong path");

        if (dut.regfile_inst.registers[8] !== 32'd0)
            $fatal(1, "FAIL: BGEU did not skip its wrong path");

        // Check fall-through behavior.
        if (dut.regfile_inst.registers[4] !== 32'd2)
            $fatal(1, "FAIL: BNE not-taken path");

        if (dut.regfile_inst.registers[6] !== 32'd4)
            $fatal(1, "FAIL: BGE not-taken path");

        if (dut.regfile_inst.registers[7] !== 32'd5)
            $fatal(1, "FAIL: BLTU not-taken path");

        if (result !== 32'd42)
            $fatal(1, "FAIL: Expected 42, got %08h", result);

        $display("PASS: all six branch conditions");
        $display("PASS: taken and not-taken paths");
        $display("ALL CPU BRANCH TESTS PASSED!");

        $finish;
    end

endmodule
