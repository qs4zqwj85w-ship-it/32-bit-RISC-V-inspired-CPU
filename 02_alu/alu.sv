//NOTE THIS ALU HAS BEEN UPDATED TO USE ALU CONTROL SIGNAL INSTEAD OF FUNCT3/FUNCT7

module alu (
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [3:0]  alu_ctrl,
    output logic [31:0] result,
    output logic        zero
);

    always_comb begin
        // Default result prevents unintended latches
        result = 32'd0;

        case (alu_ctrl)

            4'd0: result = a + b; // ADD
            4'd1: result = a - b; // SUB
            4'd2: result = a ^ b; // XOR
            4'd3: result = a | b; // OR
            4'd4: result = a & b; // AND

            4'd5: result = a << b[4:0]; // SLL
            4'd6: result = a >> b[4:0]; // SRL
            4'd7: result = $signed(a) >>> b[4:0]; // SRA

            4'd8: result = ($signed(a) < $signed(b))
                          ? 32'd1 : 32'd0; // SLT

            4'd9: result = (a < b)
                          ? 32'd1 : 32'd0; // SLTU

            default: result = 32'd0;

        endcase

        // Assert when the ALU result is zero
        zero = (result == 32'd0);
    end

endmodule
