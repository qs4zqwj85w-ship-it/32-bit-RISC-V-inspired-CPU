module cpu_fpga_top (
    input  logic clk_27m,
    output logic led0_n
);

    logic [5:0] startup_counter = 6'd0;
    logic reset;

    always_ff @(posedge clk_27m) begin
        if (startup_counter != 6'd63)
            startup_counter <= startup_counter + 1'b1;
    end

    assign reset = (startup_counter != 6'd63);

    logic [31:0] cpu_result;

    CPU cpu_inst (
        .clk(clk_27m),
        .reset(reset),
        .result(cpu_result)
    );

    assign led0_n = (cpu_result == 32'd12) ? 1'b0 : 1'b1;

endmodule
