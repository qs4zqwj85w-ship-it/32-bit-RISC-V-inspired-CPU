module cpu_fpga_top (
    input  logic clk_27m,
    output logic led0_n,
    output logic uart_tx
);

    // Startup reset
    logic [5:0] startup_counter = 6'd0;
    logic reset;

    always_ff @(posedge clk_27m) begin
        if (startup_counter != 6'd63)
            startup_counter <= startup_counter + 1'b1;
    end

    assign reset = (startup_counter != 6'd63);

    // UART, driven by the CPU
    logic       cpu_uart_wr;
    logic [7:0] cpu_uart_data;
    logic       uart_busy;

    uart_transmitter uart_inst (
        .clk     (clk_27m),
        .rst     (reset),
        .data_in (cpu_uart_data),
        .start   (cpu_uart_wr && !uart_busy),
        .tx      (uart_tx),
        .busy    (uart_busy)
    );

    // RV32I CPU
    logic [31:0] cpu_result;

    CPU cpu_inst (
        .clk          (clk_27m),
        .reset        (reset),
        .result       (cpu_result),
        .uart_wr_en   (cpu_uart_wr),
        .uart_wr_data (cpu_uart_data),
        .uart_busy    (uart_busy)
    );

    // Sticky LED: lights once the CPU's result register has been 12
    logic result_seen = 1'b0;

    always_ff @(posedge clk_27m) begin
        if (reset)
            result_seen <= 1'b0;
        else if (cpu_result == 32'd12)
            result_seen <= 1'b1;
    end

    assign led0_n = result_seen ? 1'b0 : 1'b1;

endmodule