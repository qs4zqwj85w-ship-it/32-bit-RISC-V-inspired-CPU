module mdr (
    input  logic       clk,
    input  logic       reset,
    input logic mdr_write_enable,
    input logic [31:0] mdr_in,

    output logic [31:0] mdr_out

);

    logic [31:0] mdr_registers;

//reset mdr register
//clock edge write data

    always_ff @(posedge clk) begin
        if (reset)
            mdr_registers <= 32'd0;
        else if (mdr_write_enable)
            mdr_registers <= mdr_in;
    end

    assign mdr_out = mdr_registers;

endmodule
