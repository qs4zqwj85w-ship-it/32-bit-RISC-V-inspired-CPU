
`timescale 1ns/1ps

module imm_gen_tb;

    logic [31:0] instr;
    logic [2:0]  imm_type;
    logic [31:0] imm;

    imm_gen dut (
        .instr    (instr),
        .imm_type (imm_type),
        .imm      (imm)
    );

    // Reusable immediate-generator test
    task automatic check_imm(
        input logic [2:0]  fmt,
        input logic [31:0] instruction,
        input logic [31:0] expected
    );
        begin
            imm_type = fmt;
            instr = instruction;

            #1; // Allow combinational logic to settle

            if (imm !== expected)
                $fatal(1,
                    "FAIL: type=%b instr=%h expected=%h got=%h",
                    fmt, instruction, expected, imm);

            $display("PASS: type=%b instr=%h imm=%h",
                     fmt, instruction, imm);
        end
    endtask

    initial begin
        $display("Starting Immediate Generator Tests...");

        // I-type: positive, negative, and minimum 12-bit immediate
        check_imm(3'b000, 32'h02A00000, 32'd42);
        check_imm(3'b000, 32'hFFF00000, 32'hFFFFFFFF);
        check_imm(3'b000, 32'h80000000, 32'hFFFFF800);

        // S-type: positive and negative split immediates
        check_imm(3'b001,
                  {7'b0000001, 13'b0, 5'b01010, 7'b0},
                  32'd42);

        check_imm(3'b001,
                  {7'h7F, 13'b0, 5'b10100, 7'b0},
                  32'hFFFFFFF4); // -12

        // B-type: test both scattered fields and sign extension
        check_imm(3'b010,
                  {1'b0, 6'b010101, 13'b0,
                   4'b1110, 1'b1, 7'b0},
                  32'h00000ABC);

        check_imm(3'b010,
                  {1'b1, 6'b111111, 13'b0,
                   4'b1110, 1'b1, 7'b0},
                  32'hFFFFFFFC); // -4

        // U-type: low 12 bits must always become zero
        check_imm(3'b011, 32'hABCDE123, 32'hABCDE000);
        check_imm(3'b011, 32'h80000ABC, 32'h80000000);

        // J-type: test scattered fields and negative offset
        check_imm(3'b100,
                  {1'b0, 10'h3FF, 1'b1, 8'h00, 12'h000},
                  32'h00000FFE);

        check_imm(3'b100,
                  {1'b1, 10'h3FF, 1'b1, 8'hFF, 12'h000},
                  32'hFFFFFFFE); // -2

        // Unsupported selector should return zero
        check_imm(3'b101, 32'hFFFFFFFF, 32'd0);

        $display("SUCCESS: All immediate generator tests passed!");
        $finish;
    end

endmodule
