module cpu_fpga_top (
    input  logic clk_27m,
    output logic led0_n,
    output logic led1_n,
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
    logic [7:0] uart_mux_data;
    logic       uart_mux_start;

    uart_transmitter uart_inst (
        .clk     (clk_main),
        .rst     (reset),
        .data_in (uart_mux_data),
        .start (uart_mux_start),
        .tx      (uart_tx),
        .busy    (uart_busy)
    );

    // CPU core and external SDRAM pins
    logic [31:0] cpu_result;
    logic [31:0] dbg_pc;
    logic dbg_sdram_req;
    logic dbg_sdram_req_ready;
    logic dbg_sdram_done;

    CPU cpu_inst (
        .clk          (clk_main),
        .reset        (reset),
        .result       (cpu_result),
        .dbg_pc(dbg_pc),
        .dbg_sdram_req(dbg_sdram_req),
        .dbg_sdram_req_ready(dbg_sdram_req_ready),
        .dbg_sdram_done(dbg_sdram_done),
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

    // Diagnostic-only status. Both LEDs are active-low.
    // LED0 lights after the CPU PC begins advancing; LED1 lights after any SDRAM done pulse.
    logic cpu_started_seen = 1'b0;
    logic sdram_done_seen = 1'b0;

    logic boot_reported, req_reported, accept_reported, done_reported;
    logic req_timeout_reported, done_timeout_reported;
    logic diag_boot_pending, diag_req_pending, diag_accept_pending, diag_done_pending;
    logic diag_req_timeout_pending, diag_done_timeout_pending;
    logic [24:0] req_wait_counter;
    logic [24:0] done_wait_counter;
    logic waiting_for_done;
    logic cpu_uart_pending;
    logic [7:0] cpu_uart_pending_data;

    wire diag_any_pending = diag_boot_pending || diag_req_pending ||
        diag_accept_pending || diag_done_pending ||
        diag_req_timeout_pending || diag_done_timeout_pending;

    // The UART prints single-character breadcrumbs while preserving the C test's
    // normal UART text. Priority order keeps the first-transaction sequence legible:
    // B=CPU PC moved, Q=request, A=accepted, D=done, w=accept timeout, h=done timeout.
    always_comb begin
        uart_mux_data  = cpu_uart_data;
        uart_mux_start = 1'b0;
        if (!uart_busy) begin
            if (diag_boot_pending) begin uart_mux_data = 8'h42; uart_mux_start = 1'b1; end // B
            else if (diag_req_pending) begin uart_mux_data = 8'h51; uart_mux_start = 1'b1; end // Q
            else if (diag_accept_pending) begin uart_mux_data = 8'h41; uart_mux_start = 1'b1; end // A
            else if (diag_done_pending) begin uart_mux_data = 8'h44; uart_mux_start = 1'b1; end // D
            else if (diag_req_timeout_pending) begin uart_mux_data = 8'h77; uart_mux_start = 1'b1; end // w
            else if (diag_done_timeout_pending) begin uart_mux_data = 8'h68; uart_mux_start = 1'b1; end // h
            else if (cpu_uart_pending) begin uart_mux_data = cpu_uart_pending_data; uart_mux_start = 1'b1; end
            else if (cpu_uart_wr) begin uart_mux_data = cpu_uart_data; uart_mux_start = 1'b1; end
        end
    end

    always_ff @(posedge clk_main) begin
        if (reset) begin
            cpu_started_seen <= 1'b0;
            sdram_done_seen <= 1'b0;
            boot_reported <= 1'b0;
            req_reported <= 1'b0;
            accept_reported <= 1'b0;
            done_reported <= 1'b0;
            req_timeout_reported <= 1'b0;
            done_timeout_reported <= 1'b0;
            diag_boot_pending <= 1'b0;
            diag_req_pending <= 1'b0;
            diag_accept_pending <= 1'b0;
            diag_done_pending <= 1'b0;
            diag_req_timeout_pending <= 1'b0;
            diag_done_timeout_pending <= 1'b0;
            req_wait_counter <= 25'd0;
            done_wait_counter <= 25'd0;
            waiting_for_done <= 1'b0;
            cpu_uart_pending <= 1'b0;
            cpu_uart_pending_data <= 8'd0;
        end else begin
            if (dbg_pc != 32'd0) begin
                cpu_started_seen <= 1'b1;
                if (!boot_reported) begin boot_reported <= 1'b1; diag_boot_pending <= 1'b1; end
            end
            if (dbg_sdram_req && !req_reported) begin
                req_reported <= 1'b1;
                diag_req_pending <= 1'b1;
            end
            if (dbg_sdram_req && dbg_sdram_req_ready && !accept_reported) begin
                accept_reported <= 1'b1;
                diag_accept_pending <= 1'b1;
            end
            if (dbg_sdram_done) begin
                sdram_done_seen <= 1'b1;
                if (!done_reported) begin done_reported <= 1'b1; diag_done_pending <= 1'b1; end
            end

            // If req remains asserted without ready for ~1 s, emit lowercase 'w'.
            if (dbg_sdram_req && !dbg_sdram_req_ready) begin
                if (req_wait_counter < 25'd26999999)
                    req_wait_counter <= req_wait_counter + 1'b1;
                else if (!req_timeout_reported) begin
                    req_timeout_reported <= 1'b1;
                    diag_req_timeout_pending <= 1'b1;
                end
            end else begin
                req_wait_counter <= 25'd0;
            end

            // Once accepted, expect done within ~1 s; emit lowercase 'h' if it hangs.
            if (dbg_sdram_req && dbg_sdram_req_ready) begin
                waiting_for_done <= 1'b1;
                done_wait_counter <= 25'd0;
            end
            if (dbg_sdram_done) begin
                waiting_for_done <= 1'b0;
                done_wait_counter <= 25'd0;
            end else if (waiting_for_done) begin
                if (done_wait_counter < 25'd26999999)
                    done_wait_counter <= done_wait_counter + 1'b1;
                else if (!done_timeout_reported) begin
                    done_timeout_reported <= 1'b1;
                    diag_done_timeout_pending <= 1'b1;
                end
            end

            // Preserve a CPU character if a diagnostic breadcrumb wins the UART
            // at the exact cycle the firmware writes a character.
            if (cpu_uart_wr && (uart_busy || diag_any_pending)) begin
                cpu_uart_pending <= 1'b1;
                cpu_uart_pending_data <= cpu_uart_data;
            end

            // Retire exactly the source selected by the UART mux at this idle edge.
            if (!uart_busy) begin
                if (diag_boot_pending) diag_boot_pending <= 1'b0;
                else if (diag_req_pending) diag_req_pending <= 1'b0;
                else if (diag_accept_pending) diag_accept_pending <= 1'b0;
                else if (diag_done_pending) diag_done_pending <= 1'b0;
                else if (diag_req_timeout_pending) diag_req_timeout_pending <= 1'b0;
                else if (diag_done_timeout_pending) diag_done_timeout_pending <= 1'b0;
                else if (cpu_uart_pending) cpu_uart_pending <= 1'b0;
            end
        end
    end

    assign led0_n = cpu_started_seen ? 1'b0 : 1'b1;
    assign led1_n = sdram_done_seen ? 1'b0 : 1'b1;

endmodule
