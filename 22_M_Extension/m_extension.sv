module m_extension(
    input  logic [31:0] operand_a,
    input  logic [31:0] operand_b,
    input  logic [2:0] operation,
    output logic [31:0] result
);
    logic [65:0] temp_result;
    logic signed [32:0] op_a;
    logic signed [32:0] op_b;

    
    // Sign-extend the operands for multiplication (this took some research, very interesting method to implemnet i have to admit)
    always_comb begin
        case (operation)
            3'b000: begin // MUL (Sign doesn't matter for lower half, treat as unsigned)
                op_a = $signed({1'b0, operand_a});
                op_b = $signed({1'b0, operand_b});
            end
            3'b001: begin // MULH (Signed * Signed)
                op_a = $signed({operand_a[31], operand_a});
                op_b = $signed({operand_b[31], operand_b});
            end
            3'b010: begin // MULHSU (Signed * Unsigned)
                op_a = $signed({operand_a[31], operand_a});
                op_b = $signed({1'b0, operand_b});
            end
            3'b011: begin // MULHU (Unsigned * Unsigned)
                op_a = $signed({1'b0, operand_a});
                op_b = $signed({1'b0, operand_b});
            end
            default: begin
                op_a = '0;
                op_b = '0;
            end
        endcase
    end

    assign temp_result = op_a * op_b;


// selection of result
    always_comb begin
        case (operation)
            3'b000:  result = temp_result[31:0];  // Lower half
            3'b001:  result = temp_result[63:32]; // Upper half
            3'b010:  result = temp_result[63:32]; // Upper half
            3'b011:  result = temp_result[63:32]; // Upper half
            default: result = 32'b0;
        endcase
    end

endmodule