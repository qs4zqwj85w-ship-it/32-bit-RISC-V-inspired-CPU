module CPU_jump_tb;

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

        put_instruction(0,  32'h00000193); // addi x3,x0,0
        put_instruction(4,  32'h00000213); // addi x4,x0,0
        put_instruction(8,  32'h00000393); // addi x7,x0,0

        // JAL: return address = 12, target = 16.
        put_instruction(12, 32'h008002EF); // jal x5,+8
        put_instruction(16, 32'h06300193); // addi x3,x0,99 (must skip)

        // Verify JAL's link address.
        put_instruction(20, 32'h00028093); // addi x1,x5,0
        put_instruction(24, 32'h01000113); // addi x2,x0,16
        put_instruction(28, 32'h00208463); // beq x1,x2,+8
        put_instruction(32, 32'h06300213); // addi x4,x0,99 (must skip)

        // JALR at address 36:
        // return address = 40; target = 45 & ~1 = 44.
        put_instruction(36, 32'h02D00367); // jalr x6,45(x0)
        put_instruction(40, 32'h06300393); // addi x7,x0,99 (must skip)

        // Verify JALR's link address.
        put_instruction(44, 32'h00030093); // addi x1,x6,0
        put_instruction(48, 32'h02800113); // addi x2,x0,40
        put_instruction(52, 32'h00208463); // beq x1,x2,+8
        put_instruction(56, 32'h06200213); // addi x4,x0,98 (must skip)

        put_instruction(60, 32'h04D00513); // addi x10,x0,77
        put_instruction(64, 32'h0000006F); // jal x0,0 (loop)

        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 1'b0;

        repeat (180) @(posedge clk);
        #1;

        // JAL should preserve the return address 16.
        if (dut.regfile_inst.registers[5] !== 32'd16)
            $fatal(1, "FAIL: JAL link address, expected 16, got %0d",
           dut.regfile_inst.registers[5]);

        // JAL must skip the wrong-path instruction.
        if (dut.regfile_inst.registers[3] !== 32'd0)
            $fatal(1, "FAIL: JAL target");

        // JALR should preserve the return address 40.
        if (dut.regfile_inst.registers[6] !== 32'd40)
            $fatal(1, "FAIL: JALR link address");

        // Both branches checking the link addresses should have skipped
        // the writes that set x4 to 99 or 98.
        if (dut.regfile_inst.registers[4] !== 32'd0)
            $fatal(1, "FAIL: Jump link verification branch");

        // JALR should skip the instruction at 40 and land at 44.
        if (dut.regfile_inst.registers[7] !== 32'd0)
            $fatal(1, "FAIL: JALR target alignment or control flow");

        if (result !== 32'd77)
            $fatal(1, "FAIL: Expected 77, got %08h", result);

        $display("PASS: JAL target and return address");
        $display("PASS: JALR bit-0 clearing, target, and return address");
        $display("ALL CPU JUMP TESTS PASSED!");

        $finish;
    end

endmodule
