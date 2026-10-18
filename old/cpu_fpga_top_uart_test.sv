
module cpu_fpga_top (
    input  logic clk_27m,
    output logic led0_n,
    output logic uart_tx
);

    // =====================================================
    // 1. Startup reset
    // =====================================================

    logic [5:0] startup_counter = 6'd0;
    logic reset;

    always_ff @(posedge clk_27m) begin
        if (startup_counter != 6'd63)
            startup_counter <= startup_counter + 1'b1;
    end

    assign reset = (startup_counter != 6'd63);


    // =====================================================
    // 2. Temporary UART test: send "UART OK" repeatedly
    // =====================================================

localparam logic [28:0] UART_START_DELAY_CYCLES = 29'd26_999_999; // ~1 s


    logic [28:0] uart_startup_delay = 29'd0;

    logic       uart_busy;
    logic       uart_start;
    logic [7:0] uart_data;
    logic [3:0] uart_msg_index;

    // ASCII characters: UART OK followed by CR/LF.
    always_comb begin
        case (uart_msg_index)
            4'd0:    uart_data = 8'h55; // U
            4'd1:    uart_data = 8'h41; // A
            4'd2:    uart_data = 8'h52; // R
            4'd3:    uart_data = 8'h54; // T
            4'd4:    uart_data = 8'h20; // Space
            4'd5:    uart_data = 8'h4F; // O
            4'd6:    uart_data = 8'h4B; // K
            4'd7:    uart_data = 8'h0D; // Carriage return
            4'd8:    uart_data = 8'h0A; // Line feed
            default: uart_data = 8'h00;
        endcase
    end

    // Start only after the delay, and only when UART is ready.
    assign uart_start =
        !reset &&
        (uart_startup_delay == UART_START_DELAY_CYCLES) &&
        (uart_msg_index < 4'd9) &&
        !uart_busy;

    always_ff @(posedge clk_27m) begin
        if (reset) begin
            uart_startup_delay <= 29'd0;
            uart_msg_index     <= 4'd0;
        end else begin
            // Count up to the startup delay, then hold.
            if (uart_startup_delay < UART_START_DELAY_CYCLES)
                uart_startup_delay <= uart_startup_delay + 1'b1;

            // Advance only when the transmitter accepts a character.
            // Once index reaches 9, no more characters are sent.
            if (uart_start)
                uart_msg_index <= uart_msg_index + 1'b1;
            // inside the else branch, after the existing code:
            if (uart_msg_index == 4'd9 && !uart_busy) begin
                uart_msg_index     <= 4'd0;
                uart_startup_delay <= 29'd0;
            end
        end
    end

    uart_transmitter uart_test_inst (
        .clk     (clk_27m),
        .rst     (reset),
        .data_in (uart_data),
        .start   (uart_start),
        .tx      (uart_tx),
        .busy    (uart_busy)
    );


    // =====================================================
    // 3. RV32I CPU
    // =====================================================

    logic [31:0] cpu_result;

    CPU cpu_inst (
        .clk    (clk_27m),
        .reset  (reset),
        .result (cpu_result)
    );


    // =====================================================
    // 4. Sticky LED result monitor
    // =====================================================

    logic result_seen = 1'b0;

    always_ff @(posedge clk_27m) begin
        if (reset)
            result_seen <= 1'b0;
        else if (cpu_result == 32'd12)
            result_seen <= 1'b1;
    end

    // LED is active-low.
    assign led0_n = result_seen ? 1'b0 : 1'b1;

endmodule

