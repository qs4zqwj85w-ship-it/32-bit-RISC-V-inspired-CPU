module cpu_fpga_top (
    input  logic clk_27m,
    output logic led0_n,
    output logic uart_tx,

    output wire O_sdram_clk,
    output wire O_sdram_cke,
    output wire O_sdram_cs_n,
    output wire O_sdram_cas_n,
    output wire O_sdram_ras_n,
    output wire O_sdram_wen_n,
    inout  wire [31:0] IO_sdram_dq,
    output wire [10:0] O_sdram_addr,
    output wire [1:0] O_sdram_ba,
    output wire [3:0] O_sdram_dqm
);

    // Startup reset
    logic [5:0] startup_counter = 6'd0;
    logic reset;

    always_ff @(posedge clk_main) begin
        if (pll_lock) begin
            startup_counter <= 6'd0;
        end 
        else if (startup_counter != 6'd63) begin
            startup_counter <= startup_counter + 1'b1;
        end
    end

    assign reset = (startup_counter != 6'd63);

    // UART, driven by the CPU
    logic       cpu_uart_wr;
    logic [7:0] cpu_uart_data;
    logic       uart_busy;

    uart_transmitter uart_inst (
        .clk     (clk_main),
        .rst     (reset),
        .data_in (cpu_uart_data),
        .start   (cpu_uart_wr && !uart_busy),
        .tx      (uart_tx),
        .busy    (uart_busy)
    );

    // RV32I CPU
    logic [31:0] cpu_result;

    CPU cpu_inst (
        .clk          (clk_main),
        .reset        (reset),
        .result       (cpu_result),
        .uart_wr_en   (cpu_uart_wr),
        .uart_wr_data (cpu_uart_data),
        .uart_busy    (uart_busy),
        .clk_sdram  (clk_sdram),
        .SDRAM_DQ   (IO_sdram_dq),
        .SDRAM_A    (O_sdram_addr),
        .SDRAM_BA   (O_sdram_ba),
        .SDRAM_nCS  (O_sdram_cs_n),
        .SDRAM_nWE  (O_sdram_wen_n),
        .SDRAM_nRAS (O_sdram_ras_n),
        .SDRAM_nCAS (O_sdram_cas_n),
        .SDRAM_CLK  (O_sdram_clk),
        .SDRAM_CKE  (O_sdram_cke),
        .SDRAM_DQM  (O_sdram_dqm)
    );

// SDRAM 
    logic clk_main;
    logic clk_sdram;
    logic pll_lock;

    Gowin_rPLL pll_inst (
        .clkout  (clk_main),
        .clkoutp (clk_sdram),
        .lock    (pll_lock),
        .reset   (1'b0),
        .clkin   (clk_27m)
    );

    

    // Sticky LED: lights once the CPU's result register has been 12
    logic result_seen = 1'b0;

    always_ff @(posedge clk_main) begin
        if (reset)
            result_seen <= 1'b0;
        else if (cpu_result == 32'd12)
            result_seen <= 1'b1;
    end

    assign led0_n = result_seen ? 1'b0 : 1'b1;

endmodule