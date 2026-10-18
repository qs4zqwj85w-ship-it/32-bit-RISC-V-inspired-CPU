module instruction_reg (
    input  logic       clk,
    input  logic       reset,
    input logic ir_write_enable,
    input logic [31:0] instruction_in,

    output logic [31:0] instruction_out

);

    logic [31:0] instruction_registers;

//reset instruction register
//clock edge write data

    always_ff @(posedge clk) begin
        if (reset)
            instruction_registers <= 32'd0;
        else if (ir_write_enable)
            instruction_registers <= instruction_in;
    end

    assign instruction_out = instruction_registers;

endmodule
