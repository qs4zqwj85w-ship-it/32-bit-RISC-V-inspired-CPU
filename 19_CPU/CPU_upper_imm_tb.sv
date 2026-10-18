module CPU_upper_imm_tb;

    logic clk, reset;
    logic [31:0] result;

    CPU dut (
        .clk(clk),
        .reset(reset),
        .result(result)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

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

        // Address 0: lui x1,0x12345
        // Expected x1 = 0x12345000
        put_instruction(0, 32'h123450B7);

        // Address 4: auipc x2,0x00002
        // Expected x2 = PC(4) + 0x00002000 = 0x00002004
        put_instruction(4, 32'h00002117);

        // Address 8: lui x3,0xFFFFF
        // Expected x3 = 0xFFFFF000
        put_instruction(8, 32'hFFFFF1B7);

        // Address 12: auipc x4,0xFFFFF
        // Expected x4 = PC(12) + 0xFFFFF000 = 0xFFFFF00C
        put_instruction(12, 32'hFFFFF217);

        // Final debug marker.
        put_instruction(16, 32'h06300513); // addi x10,x0,99
        put_instruction(20, 32'h0000006F); // jal x0,0 (loop)

        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 1'b0;

        repeat (80) @(posedge clk);
        #1;

        if (dut.regfile_inst.registers[1] !== 32'h12345000)
            $fatal(1, "FAIL: LUI positive upper immediate");

        if (dut.regfile_inst.registers[2] !== 32'h00002004)
            $fatal(1, "FAIL: AUIPC positive upper immediate");

        if (dut.regfile_inst.registers[3] !== 32'hFFFFF000)
            $fatal(1, "FAIL: LUI all-ones upper immediate");

        if (dut.regfile_inst.registers[4] !== 32'hFFFFF00C)
            $fatal(1, "FAIL: AUIPC wraparound / PC-relative result");

        if (result !== 32'd99)
            $fatal(1, "FAIL: Final marker result, got %08h", result);

        $display("PASS: LUI");
        $display("PASS: AUIPC");
        $display("PASS: PC-relative address calculation");
        $display("ALL CPU UPPER-IMMEDIATE TESTS PASSED!");

        $finish;
    end

endmodule
