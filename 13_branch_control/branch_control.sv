module branch_control (
    input logic [2:0] branch_type,
    input logic [31:0] operand_a,
    input logic [31:0] operand_b,

    output logic branch_taken
);

    always_comb begin
        case (branch_type)
            3'b000: branch_taken = 1'b0; // Never
            3'b001: branch_taken = (operand_a == operand_b); // BEQ
            3'b010: branch_taken = (operand_a != operand_b); // BNE
            3'b011: branch_taken = ($signed(operand_a) < $signed(operand_b)); // BLT
            3'b100: branch_taken = ($signed(operand_a) >= $signed(operand_b)); // BGE
            3'b101: branch_taken = (operand_a < operand_b); // BLTU
            3'b110: branch_taken = (operand_a >= operand_b); // BGEU
            default: branch_taken = 1'b0;
        endcase
    end

endmodule
