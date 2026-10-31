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
    output wire [3:0] O_sdram_dqm,

    // HDMI TMDS outputs (with diffrential implementation)
    output wire hdmi_data0_p,
    output wire hdmi_data0_n,
    output wire hdmi_data1_p,
    output wire hdmi_data1_n,
    output wire hdmi_data2_p,
    output wire hdmi_data2_n,
    output wire hdmi_clk_p,
    output wire hdmi_clk_n
);

    // PLL-generated clocks
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

    // Hold the system in reset until the PLL locks, then wait 63 main-clock cycles.
    logic [5:0] startup_counter = 6'd0;
    logic reset;

    always_ff @(posedge clk_main) begin
        if (!pll_lock)
            startup_counter <= 6'd0;
        else if (startup_counter != 6'd63)
            startup_counter <= startup_counter + 1'b1;
    end

    assign reset = !pll_lock || (startup_counter != 6'd63);

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

    // CPU core and external SDRAM pins
    logic [31:0] cpu_result;

    CPU cpu_inst (
        .clk          (clk_main),
        .reset        (reset),
        .result       (cpu_result),
        .uart_wr_en   (cpu_uart_wr),
        .uart_wr_data (cpu_uart_data),
        .uart_busy    (uart_busy),
        .clk_sdram    (clk_sdram),
        .SDRAM_DQ     (IO_sdram_dq),
        .SDRAM_A      (O_sdram_addr),
        .SDRAM_BA     (O_sdram_ba),
        .SDRAM_nCS    (O_sdram_cs_n),
        .SDRAM_nWE    (O_sdram_wen_n),
        .SDRAM_nRAS   (O_sdram_ras_n),
        .SDRAM_nCAS   (O_sdram_cas_n),
        .SDRAM_CLK    (O_sdram_clk),
        .SDRAM_CKE    (O_sdram_cke),
        .SDRAM_DQM    (O_sdram_dqm)
    );

    // ============================================================
    // HDMI subsystem
    // ============================================================

    // HDMI clocks
    logic clk_135m;
    logic hdmi_pll_locked;
    logic hdmi_reset;

    // Generate 135 MHz serializer clock from the board's 27 MHz clock.
    gowin_hdmi_pll hdmi_pll_inst (
        .clk_27m (clk_27m),
        .reset   (1'b0),
        .clk_135m(clk_135m),
        .locked  (hdmi_pll_locked)
    );

    // Keep video logic in reset until the HDMI PLL locks.
    assign hdmi_reset = !hdmi_pll_locked;

    // TMDS-encoded video data
    logic [9:0] tmds_red;
    logic [9:0] tmds_green;
    logic [9:0] tmds_blue;

    tmds_video_core video_inst (
        .clk_pixel  (clk_27m),
        .rst        (hdmi_reset),
        .tmds_red   (tmds_red),
        .tmds_green (tmds_green),
        .tmds_blue  (tmds_blue)
    );

    wire serial_red;
    wire serial_green;
    wire serial_blue;
    wire tmds_clock;

    // Serialize the three TMDS channels.
    tmds_serializer serializer_inst (
        .clk_pixel    (clk_27m),
        .clk_pixel_x5 (clk_135m),
        .rst          (hdmi_reset),

        .tmds_red   (tmds_red),
        .tmds_green (tmds_green),
        .tmds_blue  (tmds_blue),

        .serial_red   (serial_red),
        .serial_green (serial_green),
        .serial_blue  (serial_blue),
        .tmds_clock   (tmds_clock)
    );

    differential_output hdmi_data0_diff (
        .signal_in (serial_blue),
        .signal_p  (hdmi_data0_p),
        .signal_n  (hdmi_data0_n)
    );

    differential_output hdmi_data1_diff (
        .signal_in (serial_green),
        .signal_p  (hdmi_data1_p),
        .signal_n  (hdmi_data1_n)
    );

    differential_output hdmi_data2_diff (
        .signal_in (serial_red),
        .signal_p  (hdmi_data2_p),
        .signal_n  (hdmi_data2_n)
    );

    differential_output hdmi_clock_diff (
        .signal_in (tmds_clock),
        .signal_p  (hdmi_clk_p),
        .signal_n  (hdmi_clk_n)
    );

    // Sticky LED: lights once the CPU's result register has been 12.
    logic result_seen = 1'b0;

    always_ff @(posedge clk_main) begin
        if (reset)
            result_seen <= 1'b0;
        else if (cpu_result == 32'd12)
            result_seen <= 1'b1;
    end

    assign led0_n = result_seen ? 1'b0 : 1'b1;

endmodule
