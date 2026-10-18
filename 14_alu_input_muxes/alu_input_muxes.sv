module alu_input_muxes (
    input logic [31:0] pc_out,
    input logic [31:0] mar_out,
    input logic [31:0] operand_a,
    input logic [31:0] operand_b,
    input logic [31:0] immediate,
    input logic [1:0] alu_a_sel,
    input logic [1:0] alu_b_sel,

    output logic [31:0] alu_a,
    output logic [31:0] alu_b
);

    always_comb begin
        case (alu_a_sel)
            2'b00: alu_a = pc_out;
            2'b01: alu_a = mar_out;
            2'b10: alu_a = operand_a;
            default: alu_a = 32'd0;
        endcase

        case (alu_b_sel)
            2'b00: alu_b = operand_b;
            2'b01: alu_b = immediate;
            2'b10: alu_b = 32'd4;
            2'b11: alu_b = 32'b0;
            default: alu_b = 32'd0;
        endcase
    end






endmodule
