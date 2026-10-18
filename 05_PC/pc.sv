module pc (
    input  logic clk,
    input  logic reset,
    input logic pc_enable,
    input logic [31:0] next_pc,

    output logic [31:0] pc_out
);

    always_ff @(posedge clk) begin
        if (reset)            
                pc_out <= 32'd0;
        else
            if (pc_enable)
                pc_out <= next_pc;
            else
                pc_out <= pc_out;
    end

endmodule

