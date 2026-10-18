module op_AB_reg (
    input  logic       clk,
    input  logic       reset,
    input logic op_AB_reg_write_enable,
    input logic [31:0] op_AB_reg_in1,
    input logic [31:0] op_AB_reg_in2,

    output logic [31:0] op_AB_reg_out1,
    output logic [31:0] op_AB_reg_out2

);

    logic [31:0] op_AB_reg_registers [1:0];

//reset op_AB register
//clock edge write data

    always_ff @(posedge clk) begin
        if (reset) begin
            op_AB_reg_registers[0] <= 32'd0;
            op_AB_reg_registers[1] <= 32'd0;
        end else if (op_AB_reg_write_enable) begin
            op_AB_reg_registers[0] <= op_AB_reg_in1;
            op_AB_reg_registers[1] <= op_AB_reg_in2;
        end
    end

    assign op_AB_reg_out1 = op_AB_reg_registers[0];
    assign op_AB_reg_out2 = op_AB_reg_registers[1];

endmodule
