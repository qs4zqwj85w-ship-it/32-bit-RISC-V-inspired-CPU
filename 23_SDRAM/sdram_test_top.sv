// Standalone SDRAM smoke test for the Tang Nano 20K.
// Uses the NESTang SDRAM controller's byte-wide request interface.
// LED0 turns on when every test byte reads back correctly; LED1 turns on on error.

module sdram_test_top (
    input  wire       clk_27m,
    output wire [1:0] led_n,

    // Tang Nano 20K embedded SDRAM pins. Keep these names aligned with the CST.
    output wire       O_sdram_clk,
    output wire       O_sdram_cke,
    output wire       O_sdram_cs_n,
    output wire       O_sdram_cas_n,
    output wire       O_sdram_ras_n,
    output wire       O_sdram_wen_n,
    inout  wire [31:0] IO_sdram_dq,
    output wire [10:0] O_sdram_addr,
    output wire [1:0] O_sdram_ba,
    output wire [3:0] O_sdram_dqm
);

    localparam integer SDRAM_FREQ_HZ = 27_000_000;

    // NESTang's PLL produces the 27 MHz controller clock and phase-shifted SDRAM clock.
    wire clk_main;
    wire clk_sdram;
    wire pll_lock;

    Gowin_rPLL pll_inst (
        .clkout  (clk_main),
        .clkoutp (clk_sdram),
        .lock    (pll_lock),
        .reset   (1'b0),
        .clkin   (clk_27m)
    );

    // Short startup reset; the SDRAM controller performs its own power-up delay.
    reg [6:0] reset_counter = 7'd0;
    wire reset = (reset_counter != 7'd127);

    always @(posedge clk_main) begin
        if (reset_counter != 7'd127)
            reset_counter <= reset_counter + 1'b1;
    end

    localparam [3:0] ST_WAIT_INIT       = 4'd0;
    localparam [3:0] ST_WRITE_CMD       = 4'd1;
    localparam [3:0] ST_WRITE_WAIT_BUSY = 4'd2;
    localparam [3:0] ST_WRITE_WAIT_DONE = 4'd3;
    localparam [3:0] ST_READ_CMD        = 4'd4;
    localparam [3:0] ST_READ_WAIT_BUSY  = 4'd5;
    localparam [3:0] ST_READ_WAIT_DONE  = 4'd6;
    localparam [3:0] ST_PASS            = 4'd7;
    localparam [3:0] ST_FAIL            = 4'd8;

    reg [3:0] state;

    // Controller-side interface.
    reg  [22:0] sdram_addr;
    reg  [7:0]  sdram_din;
    wire [7:0]  sdram_dout;
    wire [31:0] sdram_dout32;
    wire        sdram_busy;
    wire        sdram_data_ready;
    wire        sdram_rd;
    wire        sdram_wr;
    wire        sdram_refresh;

    // We test 8 byte addresses: lanes 0..3 in word 0 and lanes 0..3 in word 0x100.
    // Distinct values make lane mix-ups and address decode errors visible.
    reg [2:0] test_index;

    function [7:0] pattern_for;
        input [2:0] index;
        begin
            case (index)
                3'd0: pattern_for = 8'h3E;
                3'd1: pattern_for = 8'hED;
                3'd2: pattern_for = 8'h5A;
                3'd3: pattern_for = 8'hC3;
                3'd4: pattern_for = 8'hA5;
                3'd5: pattern_for = 8'h69;
                3'd6: pattern_for = 8'h96;
                default: pattern_for = 8'hF0;
            endcase
        end
    endfunction

    wire [22:0] selected_test_addr = test_index[2]
        ? (23'd256 + {21'd0, test_index[1:0]})
        : {21'd0, test_index[1:0]};
    wire [7:0] selected_test_data = pattern_for(test_index);

    // Refresh at least once every approximately 15 us (405 cycles at 27 MHz).
    // If the controller is busy, keep the request pending until it can accept it.
    reg [8:0] refresh_counter;
    reg       refresh_pending;

    assign sdram_refresh = refresh_pending && !sdram_busy && !reset;

    // The test FSM leaves each *_CMD state on the same edge the controller accepts
    // the request, making rd/wr one-cycle pulses rather than level-sensitive commands.
    assign sdram_wr = (state == ST_WRITE_CMD) && !sdram_busy &&
                      !refresh_pending && !reset;
    assign sdram_rd = (state == ST_READ_CMD) && !sdram_busy &&
                      !refresh_pending && !reset;

    sdram #(.FREQ(SDRAM_FREQ_HZ)) sdram_inst (
        .SDRAM_DQ  (IO_sdram_dq),
        .SDRAM_A   (O_sdram_addr),
        .SDRAM_BA  (O_sdram_ba),
        .SDRAM_nCS (O_sdram_cs_n),
        .SDRAM_nWE (O_sdram_wen_n),
        .SDRAM_nRAS(O_sdram_ras_n),
        .SDRAM_nCAS(O_sdram_cas_n),
        .SDRAM_CLK (O_sdram_clk),
        .SDRAM_CKE (O_sdram_cke),
        .SDRAM_DQM (O_sdram_dqm),
        .clk       (clk_main),
        .clk_sdram (clk_sdram),
        .resetn    (!reset),
        .rd        (sdram_rd),
        .wr        (sdram_wr),
        .refresh   (sdram_refresh),
        .addr      (sdram_addr),
        .din       (sdram_din),
        .dout      (sdram_dout),
        .dout32    (sdram_dout32),
        .data_ready(sdram_data_ready),
        .busy      (sdram_busy)
    );


    // The test data and address are held stable for the complete request pulse.
    always @* begin
        sdram_addr = selected_test_addr;
        sdram_din  = selected_test_data;
    end

    always @(posedge clk_main) begin
        if (reset) begin
            refresh_counter <= 9'd0;
            refresh_pending <= 1'b0;
            test_index      <= 3'd0;
            state           <= ST_WAIT_INIT;
        end else begin
            if (sdram_refresh) begin
                refresh_counter <= 9'd0;
                refresh_pending <= 1'b0;
            end else if (!refresh_pending) begin
                if (refresh_counter == 9'd404)
                    refresh_pending <= 1'b1;
                else
                    refresh_counter <= refresh_counter + 1'b1;
            end

            case (state)
                ST_WAIT_INIT: begin
                    if (!sdram_busy) begin
                        test_index <= 3'd0;
                        state <= ST_WRITE_CMD;
                    end
                end

                ST_WRITE_CMD: begin
                    if (!sdram_busy && !refresh_pending)
                        state <= ST_WRITE_WAIT_BUSY;
                end

                ST_WRITE_WAIT_BUSY: begin
                    if (sdram_busy)
                        state <= ST_WRITE_WAIT_DONE;
                end

                ST_WRITE_WAIT_DONE: begin
                    if (!sdram_busy) begin
                        if (test_index == 3'd7) begin
                            test_index <= 3'd0;
                            state <= ST_READ_CMD;
                        end else begin
                            test_index <= test_index + 1'b1;
                            state <= ST_WRITE_CMD;
                        end
                    end
                end

                ST_READ_CMD: begin
                    if (!sdram_busy && !refresh_pending)
                        state <= ST_READ_WAIT_BUSY;
                end

                ST_READ_WAIT_BUSY: begin
                    if (sdram_busy)
                        state <= ST_READ_WAIT_DONE;
                end

                ST_READ_WAIT_DONE: begin
                    if (!sdram_busy) begin
                        if (sdram_dout != pattern_for(test_index)) begin
                            state <= ST_FAIL;
                        end else if (test_index == 3'd7) begin
                            state <= ST_PASS;
                        end else begin
                            test_index <= test_index + 1'b1;
                            state <= ST_READ_CMD;
                        end
                    end
                end

                ST_PASS: state <= ST_PASS;
                ST_FAIL: state <= ST_FAIL;
                default: state <= ST_FAIL;
            endcase
        end
    end

    wire test_pass = (state == ST_PASS);
    wire test_fail = (state == ST_FAIL);

    // The board LEDs are active-low: drive low to illuminate the LED.
    assign led_n[0] = !test_pass;  // LED0 on = all read-back checks passed
    assign led_n[1] = !test_fail;  // LED1 on = read-back mismatch/error

endmodule
