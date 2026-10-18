module alu_out_reg (
    input  logic       clk,
    input  logic       reset,
    input logic alu_out_reg_write_enable,
    input logic [31:0] alu_out_reg_in,

    output logic [31:0] alu_out_reg_out

);

    logic [31:0] alu_out_reg_registers;

//reset alu out register
//clock edge write data

    always_ff @(posedge clk) begin
        if (reset)
            alu_out_reg_registers <= 32'd0;
        else if (alu_out_reg_write_enable)
            alu_out_reg_registers <= alu_out_reg_in;
    end

    assign alu_out_reg_out = alu_out_reg_registers;

endmodule
