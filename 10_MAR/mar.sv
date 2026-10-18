module mar (
    input  logic       clk,
    input  logic       reset,
    input logic mar_write_enable,
    input logic [31:0] mar_in,

    output logic [31:0] mar_out

);

    logic [31:0] mar_registers;

//reset mar register
//clock edge write data

    always_ff @(posedge clk) begin
        if (reset)
            mar_registers <= 32'd0;
        else if (mar_write_enable)
            mar_registers <= mar_in;
    end

    assign mar_out = mar_registers;

endmodule
