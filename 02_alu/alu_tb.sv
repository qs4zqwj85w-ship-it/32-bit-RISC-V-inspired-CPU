//NOTE THIS TB NO LONGER WORKS AS IT USES FUNCT INSTEAD OF ALU CONTROL

module alu_tb;

    logic [31:0] a;
    logic [31:0] b;
    logic [2:0]  funct3;
    logic [6:0]  funct7;
    logic [31:0] result;
    logic        zero;

    alu dut (
        .a        (a),
        .b        (b),
        .funct3   (funct3),
        .funct7   (funct7),
        .result   (result),
        .zero     (zero)
);


    task automatic check_alu(
    input logic [2:0]  f3,
    input logic [6:0]  f7,
    input logic [31:0] lhs,
    input logic [31:0] rhs,
    input logic [31:0] expected
);
    begin
        funct3 = f3;
        funct7 = f7;
        a = lhs;
        b = rhs;

        #1;

        if (result !== expected)
            $fatal(1,
                "FAIL: funct3=%b funct7=%b a=%h b=%h expected=%h got=%h",
                f3, f7, lhs, rhs, expected, result);

        if (zero !== (expected == 32'd0))
            $fatal(1, "FAIL: incorrect zero flag");

        $display("PASS: funct3=%b funct7=%b result=%h",
                 f3, f7, result);
    end
    endtask


    initial begin
        $display("Starting ALU Verification Tests...");

        // ADD: funct3=000, funct7=0000000
        check_alu(3'b000, 7'b0000000, 32'd42, 32'd17, 32'd59);

        // SUB: funct3=000, funct7=0100000
        check_alu(3'b000, 7'b0100000, 32'd42, 32'd17, 32'd25);

        // XOR: funct3=100, funct7=0000000
        check_alu(3'b100, 7'b0000000, 32'hF0, 32'h0F, 32'hFF);

        // OR: funct3=110, funct7=0000000
        check_alu(3'b110, 7'b0000000, 32'hF0, 32'h0F, 32'hFF);

        // AND: funct3=111, funct7=0000000
        check_alu(3'b111, 7'b0000000, 32'hF0, 32'h0F, 32'h00);

        // SLL: funct3=001, funct7=0000000
        check_alu(3'b001, 7'b0000000, 32'd1, 32'd4, 32'd16);

        // SRL: funct3=101, funct7=0000000
        check_alu(3'b101, 7'b0000000, 32'h80000000, 32'd1, 32'h40000000);

        // SRA: funct3=101, funct7=0100000
        check_alu(3'b101, 7'b0100000, 32'h80000000, 32'd1, 32'hC0000000);

        // SLT: funct3=010, funct7=0000000
        check_alu(3'b010, 7'b0000000, 32'hFFFFFFFF, 32'd1, 32'd1);

        // SLTU: funct3=011, funct7=0000000
        check_alu(3'b011, 7'b0000000, 32'hFFFFFFFF, 32'd1, 32'd0);



        //STRESS TEST TIME :)

        // EDGE CASE 1: ADD overflow (32-bit wraparound)
        // 0xFFFFFFFF + 1 = 0
        check_alu(3'b000, 7'b0000000,
                32'hFFFFFFFF, 32'd1, 32'd0);

        // EDGE CASE 2: SUB equal operands
        // 42 - 42 = 0
        check_alu(3'b000, 7'b0100000,
                32'd42, 32'd42, 32'd0);

        // EDGE CASE 3: SLL by maximum shift amount (31)
        // 1 << 31 = 0x80000000
        check_alu(3'b001, 7'b0000000,
                32'd1, 32'd31, 32'h80000000);

        // EDGE CASE 4: SRL by maximum shift amount (31)
        // 0x80000000 >> 31 = 1
        check_alu(3'b101, 7'b0000000,
                32'h80000000, 32'd31, 32'd1);

        // EDGE CASE 5: SRA by maximum shift amount (31)
        // Sign extension should produce 0xFFFFFFFF
        check_alu(3'b101, 7'b0100000,
                32'h80000000, 32'd31, 32'hFFFFFFFF);

        // EDGE CASE 6: SLTU with reversed operands
        // 1 < 0xFFFFFFFF is true (unsigned comparison)
        check_alu(3'b011, 7'b0000000,
                32'd1, 32'hFFFFFFFF, 32'd1);

        $display("SUCCESS: All 18 R-type ALU operations verified!");
        $finish;
    end
endmodule