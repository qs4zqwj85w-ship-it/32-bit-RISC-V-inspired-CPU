
module sdram_service #(
    parameter integer FREQ = 27_000_000,
    parameter integer REFRESH_INTERVAL_US = 15
) (
    // Clock and reset
    input  wire        clk,
    input  wire        clk_sdram,
    input  wire        resetn,

    // CPU client
    input  wire        cpu_req,
    output reg         cpu_ready,
    input  wire        cpu_we,
    input  wire [22:0] cpu_addr,
    input  wire [7:0]  cpu_wdata,
    output reg         cpu_done,
    output reg  [31:0] cpu_rdata,

    // Framebuffer client (read-only)
    input  wire        fb_req,
    output reg         fb_ready,
    input  wire [22:0] fb_addr,
    output reg         fb_done,
    output reg  [31:0] fb_rdata,

    // Physical SDRAM interface
    inout  wire [31:0] SDRAM_DQ,
    output wire [10:0] SDRAM_A,
    output wire [1:0]  SDRAM_BA,
    output wire        SDRAM_nCS,
    output wire        SDRAM_nWE,
    output wire        SDRAM_nRAS,
    output wire        SDRAM_nCAS,
    output wire        SDRAM_CLK,
    output wire        SDRAM_CKE,
    output wire [3:0]  SDRAM_DQM
);

    // ------------------------------------------------------------
    // Refresh timer
    // ------------------------------------------------------------

    localparam integer REFRESH_INTERVAL_CYCLES =
        (FREQ * REFRESH_INTERVAL_US) / 1_000_000;

    reg [31:0] refresh_counter;

    wire refresh_due =
        (refresh_counter >= REFRESH_INTERVAL_CYCLES);

    // ------------------------------------------------------------
    // Physical SDRAM controller interface
    // ------------------------------------------------------------

    reg        sdram_rd;
    reg        sdram_wr;
    reg        sdram_refresh;
    reg [22:0] sdram_addr;
    reg [7:0]  sdram_din;

    wire [7:0]  sdram_dout;
    wire [31:0] sdram_dout32;
    wire        sdram_data_ready;
    wire        sdram_busy;

    sdram #(
        .FREQ(FREQ)
    ) sdram_inst (
        .SDRAM_DQ(SDRAM_DQ),
        .SDRAM_A(SDRAM_A),
        .SDRAM_BA(SDRAM_BA),
        .SDRAM_nCS(SDRAM_nCS),
        .SDRAM_nWE(SDRAM_nWE),
        .SDRAM_nRAS(SDRAM_nRAS),
        .SDRAM_nCAS(SDRAM_nCAS),
        .SDRAM_CLK(SDRAM_CLK),
        .SDRAM_CKE(SDRAM_CKE),
        .SDRAM_DQM(SDRAM_DQM),

        .clk(clk),
        .clk_sdram(clk_sdram),
        .resetn(resetn),

        .rd(sdram_rd),
        .wr(sdram_wr),
        .refresh(sdram_refresh),
        .addr(sdram_addr),
        .din(sdram_din),

        .dout(sdram_dout),
        .dout32(sdram_dout32),
        .data_ready(sdram_data_ready),
        .busy(sdram_busy)
    );

    // ------------------------------------------------------------
    // Transaction registers
    // ------------------------------------------------------------

    reg        transaction_we;
    reg [22:0] transaction_addr;
    reg [7:0]  transaction_wdata;

    // Identifies which client owns the active transaction.
    reg transaction_owner_fb;

    // Temporary read-data register.
    reg [31:0] transaction_rdata;

    // ------------------------------------------------------------
    // FSM
    // ------------------------------------------------------------

    localparam [3:0]
        ST_INIT             = 4'd0,
        ST_IDLE             = 4'd1,
        ST_ISSUE            = 4'd2,
        ST_WAIT_BUSY_HIGH   = 4'd3,
        ST_WAIT_READ        = 4'd4,
        ST_WAIT_BUSY_LOW    = 4'd5,
        ST_ISSUE_REFRESH    = 4'd6,
        ST_WAIT_REFRESH_HIGH= 4'd7,
        ST_WAIT_REFRESH_LOW = 4'd8;

    reg [3:0] state;

    // ------------------------------------------------------------
    // Main sequential logic
    // ------------------------------------------------------------

    always @(posedge clk) begin
        if (!resetn) begin
            state <= ST_INIT;

            cpu_ready <= 1'b0;
            cpu_done  <= 1'b0;
            cpu_rdata <= 32'b0;

            fb_ready <= 1'b0;
            fb_done  <= 1'b0;
            fb_rdata <= 32'b0;

            sdram_rd      <= 1'b0;
            sdram_wr      <= 1'b0;
            sdram_refresh <= 1'b0;
            sdram_addr    <= 23'b0;
            sdram_din     <= 8'b0;

            transaction_we       <= 1'b0;
            transaction_addr    <= 23'b0;
            transaction_wdata   <= 8'b0;
            transaction_owner_fb<= 1'b0;
            transaction_rdata   <= 32'b0;

            refresh_counter <= 32'b0;
        end else begin

            // Default: all client responses are one-cycle pulses.
            cpu_ready <= 1'b0;
            cpu_done  <= 1'b0;

            fb_ready <= 1'b0;
            fb_done  <= 1'b0;

            // Default: physical SDRAM commands are one-cycle pulses.
            sdram_rd      <= 1'b0;
            sdram_wr      <= 1'b0;
            sdram_refresh <= 1'b0;

            // Refresh timer.
            if (refresh_counter < REFRESH_INTERVAL_CYCLES)
                refresh_counter <= refresh_counter + 1'b1;

            case (state)

                // Wait until the physical SDRAM controller finishes
                // its power-on initialization.
                ST_INIT: begin
                    if (!sdram_busy)
                        state <= ST_IDLE;
                end

                // Select the next operation.
                ST_IDLE: begin

                    // Refresh takes priority over memory requests.
                    if (refresh_due) begin
                        state <= ST_ISSUE_REFRESH;
                    end

                    // Framebuffer has priority over CPU.
                    else if (fb_req) begin
                        transaction_we        <= 1'b0;
                        transaction_addr     <= fb_addr;
                        transaction_wdata    <= 8'b0;
                        transaction_owner_fb <= 1'b1;

                        fb_ready <= 1'b1;
                        state <= ST_ISSUE;
                    end

                    // CPU request if framebuffer is not waiting.
                    else if (cpu_req) begin
                        transaction_we        <= cpu_we;
                        transaction_addr     <= cpu_addr;
                        transaction_wdata    <= cpu_wdata;
                        transaction_owner_fb <= 1'b0;

                        cpu_ready <= 1'b1;
                        state <= ST_ISSUE;
                    end
                end

                // Send the selected transaction to the SDRAM controller.
                ST_ISSUE: begin
                    sdram_addr <= transaction_addr;
                    sdram_din  <= transaction_wdata;

                    if (transaction_we)
                        sdram_wr <= 1'b1;
                    else
                        sdram_rd <= 1'b1;

                    state <= ST_WAIT_BUSY_HIGH;
                end

                // Wait until the controller acknowledges the command
                // by asserting busy.
                ST_WAIT_BUSY_HIGH: begin
                    if (sdram_busy) begin
                        if (transaction_we)
                            state <= ST_WAIT_BUSY_LOW;
                        else
                            state <= ST_WAIT_READ;
                    end
                end

                // Read data becomes available when data_ready is high.
                ST_WAIT_READ: begin
                    if (sdram_data_ready) begin
                        transaction_rdata <= sdram_dout32;
                        state <= ST_WAIT_BUSY_LOW;
                    end
                end

                // Wait until the physical controller finishes.
                ST_WAIT_BUSY_LOW: begin
                    if (!sdram_busy) begin

                        if (transaction_owner_fb) begin
                            if (!transaction_we)
                                fb_rdata <= transaction_rdata;

                            fb_done <= 1'b1;
                        end else begin
                            if (!transaction_we)
                                cpu_rdata <= transaction_rdata;

                            cpu_done <= 1'b1;
                        end

                        state <= ST_IDLE;
                    end
                end

                // Issue an auto-refresh command.
                ST_ISSUE_REFRESH: begin
                    sdram_refresh <= 1'b1;
                    refresh_counter <= 32'b0;

                    state <= ST_WAIT_REFRESH_HIGH;
                end

                // Wait until the controller starts refreshing.
                ST_WAIT_REFRESH_HIGH: begin
                    if (sdram_busy)
                        state <= ST_WAIT_REFRESH_LOW;
                end

                // Wait for refresh to finish.
                ST_WAIT_REFRESH_LOW: begin
                    if (!sdram_busy)
                        state <= ST_IDLE;
                end

                default: begin
                    state <= ST_INIT;
                end

            endcase
        end
    end

endmodule
