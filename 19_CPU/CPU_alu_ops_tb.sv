module CPU_alu_ops_tb;

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

        // Setup operands:
        // x1 = 12, x2 = 3, x11 = -16.
        put_instruction(0,  32'h00C00093); // addi x1,x0,12
        put_instruction(4,  32'h00300113); // addi x2,x0,3
        put_instruction(8,  32'hFF000593); // addi x11,x0,-16

        // Register-register operations.
        put_instruction(12, 32'h002081B3); // add  x3,x1,x2  = 15
        put_instruction(16, 32'h40208233); // sub  x4,x1,x2  = 9
        put_instruction(20, 32'h0020C2B3); // xor  x5,x1,x2  = 15
        put_instruction(24, 32'h0020E333); // or   x6,x1,x2  = 15
        put_instruction(28, 32'h0020F3B3); // and  x7,x1,x2  = 0
        put_instruction(32, 32'h00209433); // sll  x8,x1,x2  = 96
        put_instruction(36, 32'h0020D4B3); // srl  x9,x1,x2  = 1
        put_instruction(40, 32'h4025D533); // sra  x10,x11,x2 = -2
        put_instruction(44, 32'h0015A633); // slt  x12,x11,x1 = 1
        put_instruction(48, 32'h0015B6B3); // sltu x13,x11,x1 = 0

        // Immediate operations.
        put_instruction(52, 32'h00508713); // addi  x14,x1,5  = 17
        put_instruction(56, 32'h00209793); // slli  x15,x1,2  = 48
        put_instruction(60, 32'h0005A813); // slti  x16,x11,0 = 1
        put_instruction(64, 32'h0015B893); // sltiu x17,x11,1 = 0
        put_instruction(68, 32'h0050C913); // xori  x18,x1,5  = 9
        put_instruction(72, 32'h0020D993); // srli  x19,x1,2  = 3
        put_instruction(76, 32'h4025DA13); // srai  x20,x11,2 = -4
        put_instruction(80, 32'h0030EA93); // ori   x21,x1,3  = 15
        put_instruction(84, 32'h00A0FB13); // andi  x22,x1,10 = 8

        // Final debug result marker.
        put_instruction(88, 32'h07B00B93); // addi x23,x0,123
        put_instruction(92, 32'h0000006F); // jal x0,0 (loop)

        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 1'b0;

        repeat (180) @(posedge clk);
        #1;

        // Verify register-register operations.
        if (dut.regfile_inst.registers[3] !== 32'd15)
            $fatal(1, "FAIL: ADD");

        if (dut.regfile_inst.registers[4] !== 32'd9)
            $fatal(1, "FAIL: SUB");

        if (dut.regfile_inst.registers[5] !== 32'd15)
            $fatal(1, "FAIL: XOR");

        if (dut.regfile_inst.registers[6] !== 32'd15)
            $fatal(1, "FAIL: OR");

        if (dut.regfile_inst.registers[7] !== 32'd0)
            $fatal(1, "FAIL: AND");

        if (dut.regfile_inst.registers[8] !== 32'd96)
            $fatal(1, "FAIL: SLL");

        if (dut.regfile_inst.registers[9] !== 32'd1)
            $fatal(1, "FAIL: SRL");

        if (dut.regfile_inst.registers[10] !== 32'hFFFFFFFE)
            $fatal(1, "FAIL: SRA");

        if (dut.regfile_inst.registers[12] !== 32'd1)
            $fatal(1, "FAIL: SLT");

        if (dut.regfile_inst.registers[13] !== 32'd0)
            $fatal(1, "FAIL: SLTU");

        // Verify immediate operations.
        if (dut.regfile_inst.registers[14] !== 32'd17)
            $fatal(1, "FAIL: ADDI");

        if (dut.regfile_inst.registers[15] !== 32'd48)
            $fatal(1, "FAIL: SLLI");

        if (dut.regfile_inst.registers[16] !== 32'd1)
            $fatal(1, "FAIL: SLTI");

        if (dut.regfile_inst.registers[17] !== 32'd0)
            $fatal(1, "FAIL: SLTIU");

        if (dut.regfile_inst.registers[18] !== 32'd9)
            $fatal(1, "FAIL: XORI");

        if (dut.regfile_inst.registers[19] !== 32'd3)
            $fatal(1, "FAIL: SRLI");

        if (dut.regfile_inst.registers[20] !== 32'hFFFFFFFC)
            $fatal(1, "FAIL: SRAI");

        if (dut.regfile_inst.registers[21] !== 32'd15)
            $fatal(1, "FAIL: ORI");

        if (dut.regfile_inst.registers[22] !== 32'd8)
            $fatal(1, "FAIL: ANDI");

        if (result !== 32'd123)
            $fatal(1, "FAIL: Final marker result, got %08h", result);

        $display("PASS: register-register ALU operations");
        $display("PASS: immediate ALU operations");
        $display("PASS: signed and unsigned comparisons");
        $display("ALL CPU ALU TESTS PASSED!");

        $finish;
    end

endmodule
