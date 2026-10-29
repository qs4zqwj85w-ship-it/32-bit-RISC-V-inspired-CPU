// Physical smoke test for sdram_adapter.sv. This tests the CPU-facing adapter
// before it is connected to the actual CPU/FSM.
// LED0 on = all read/write checks passed; LED1 on = a check failed.

module sdram_adapter_test_top (
    input  wire        clk_27m,
    output wire [1:0]  led_n,
    output wire        O_sdram_clk,
    output wire        O_sdram_cke,
    output wire        O_sdram_cs_n,
    output wire        O_sdram_cas_n,
    output wire        O_sdram_ras_n,
    output wire        O_sdram_wen_n,
    inout  wire [31:0] IO_sdram_dq,
    output wire [10:0] O_sdram_addr,
    output wire [1:0]  O_sdram_ba,
    output wire [3:0]  O_sdram_dqm
);

    localparam integer SDRAM_FREQ_HZ = 27_000_000;
    localparam [31:0] TEST_BASE = 32'h0000_1000;

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

    reg [6:0] reset_counter = 7'd0;
    wire reset = (reset_counter != 7'd127);

    always @(posedge clk_main) begin
        if (reset_counter != 7'd127)
            reset_counter <= reset_counter + 1'b1;
    end

    reg         req;
    wire        req_ready;
    reg         we;
    reg  [31:0] addr;
    reg  [31:0] wdata;
    reg  [1:0]  access_size;
    reg         load_unsigned;
    wire [31:0] rdata;
    wire        done;

    sdram_adapter #(
        .FREQ_HZ   (SDRAM_FREQ_HZ),
        .SDRAM_BASE(TEST_BASE)
    ) adapter_inst (
        .clk           (clk_main),
        .clk_sdram     (clk_sdram),
        .reset         (reset),
        .req           (req),
        .req_ready     (req_ready),
        .we            (we),
        .addr          (addr),
        .wdata         (wdata),
        .access_size   (access_size),
        .load_unsigned (load_unsigned),
        .rdata          (rdata),
        .done          (done),
        .SDRAM_DQ      (IO_sdram_dq),
        .SDRAM_A       (O_sdram_addr),
        .SDRAM_BA      (O_sdram_ba),
        .SDRAM_nCS     (O_sdram_cs_n),
        .SDRAM_nWE     (O_sdram_wen_n),
        .SDRAM_nRAS    (O_sdram_ras_n),
        .SDRAM_nCAS    (O_sdram_cas_n),
        .SDRAM_CLK     (O_sdram_clk),
        .SDRAM_CKE     (O_sdram_cke),
        .SDRAM_DQM     (O_sdram_dqm)
    );

    localparam [4:0] T_BOOT        = 5'd0;
    localparam [4:0] T_ISSUE_SW0   = 5'd1;
    localparam [4:0] T_WAIT_SW0    = 5'd2;
    localparam [4:0] T_ISSUE_LW0   = 5'd3;
    localparam [4:0] T_WAIT_LW0    = 5'd4;
    localparam [4:0] T_ISSUE_LB    = 5'd5;
    localparam [4:0] T_WAIT_LB     = 5'd6;
    localparam [4:0] T_ISSUE_LBU   = 5'd7;
    localparam [4:0] T_WAIT_LBU    = 5'd8;
    localparam [4:0] T_ISSUE_LH    = 5'd9;
    localparam [4:0] T_WAIT_LH     = 5'd10;
    localparam [4:0] T_ISSUE_LHU   = 5'd11;
    localparam [4:0] T_WAIT_LHU    = 5'd12;
    localparam [4:0] T_ISSUE_SB    = 5'd13;
    localparam [4:0] T_WAIT_SB     = 5'd14;
    localparam [4:0] T_ISSUE_LW1   = 5'd15;
    localparam [4:0] T_WAIT_LW1    = 5'd16;
    localparam [4:0] T_ISSUE_SH    = 5'd17;
    localparam [4:0] T_WAIT_SH     = 5'd18;
    localparam [4:0] T_ISSUE_LW2   = 5'd19;
    localparam [4:0] T_WAIT_LW2    = 5'd20;
    localparam [4:0] T_ISSUE_SW1   = 5'd21;
    localparam [4:0] T_WAIT_SW1    = 5'd22;
    localparam [4:0] T_ISSUE_LW3   = 5'd23;
    localparam [4:0] T_WAIT_LW3    = 5'd24;
    localparam [4:0] T_PASS        = 5'd25;
    localparam [4:0] T_FAIL        = 5'd26;

    reg [4:0] state;

    // Keep the request asserted in an ISSUE state until the adapter accepts it.
    // The test then waits for done before proceeding to the next memory operation.
    always @* begin
        req           = 1'b0;
        we            = 1'b0;
        addr          = TEST_BASE;
        wdata         = 32'b0;
        access_size   = 2'b10;
        load_unsigned = 1'b0;

        case (state)
            T_ISSUE_SW0: begin
                req  = 1'b1; we = 1'b1;
                addr = TEST_BASE; wdata = 32'hC35A_ED3E; access_size = 2'b10;
            end
            T_ISSUE_LW0: begin
                req = 1'b1; addr = TEST_BASE; access_size = 2'b10;
            end
            T_ISSUE_LB: begin
                req = 1'b1; addr = TEST_BASE + 32'd1;
                access_size = 2'b00; load_unsigned = 1'b0;
            end
            T_ISSUE_LBU: begin
                req = 1'b1; addr = TEST_BASE + 32'd1;
                access_size = 2'b00; load_unsigned = 1'b1;
            end
            T_ISSUE_LH: begin
                req = 1'b1; addr = TEST_BASE + 32'd2;
                access_size = 2'b01; load_unsigned = 1'b0;
            end
            T_ISSUE_LHU: begin
                req = 1'b1; addr = TEST_BASE + 32'd2;
                access_size = 2'b01; load_unsigned = 1'b1;
            end
            T_ISSUE_SB: begin
                req = 1'b1; we = 1'b1; addr = TEST_BASE + 32'd2;
                wdata = 32'h0000_0096; access_size = 2'b00;
            end
            T_ISSUE_LW1: begin
                req = 1'b1; addr = TEST_BASE; access_size = 2'b10;
            end
            T_ISSUE_SH: begin
                req = 1'b1; we = 1'b1; addr = TEST_BASE;
                wdata = 32'h0000_1234; access_size = 2'b01;
            end
            T_ISSUE_LW2: begin
                req = 1'b1; addr = TEST_BASE; access_size = 2'b10;
            end
            T_ISSUE_SW1: begin
                req = 1'b1; we = 1'b1; addr = TEST_BASE + 32'h100;
                wdata = 32'hA596_69F0; access_size = 2'b10;
            end
            T_ISSUE_LW3: begin
                req = 1'b1; addr = TEST_BASE + 32'h100; access_size = 2'b10;
            end
            default: begin end
        endcase
    end

    always @(posedge clk_main) begin
        if (reset) begin
            state <= T_BOOT;
        end else begin
            case (state)
                T_BOOT: state <= T_ISSUE_SW0;

                T_ISSUE_SW0: if (req_ready) state <= T_WAIT_SW0;
                T_WAIT_SW0: if (done) state <= T_ISSUE_LW0;

                T_ISSUE_LW0: if (req_ready) state <= T_WAIT_LW0;
                T_WAIT_LW0: if (done) begin
                    if (rdata == 32'hC35A_ED3E) state <= T_ISSUE_LB;
                    else state <= T_FAIL;
                end

                T_ISSUE_LB: if (req_ready) state <= T_WAIT_LB;
                T_WAIT_LB: if (done) begin
                    if (rdata == 32'hFFFF_FFED) state <= T_ISSUE_LBU;
                    else state <= T_FAIL;
                end

                T_ISSUE_LBU: if (req_ready) state <= T_WAIT_LBU;
                T_WAIT_LBU: if (done) begin
                    if (rdata == 32'h0000_00ED) state <= T_ISSUE_LH;
                    else state <= T_FAIL;
                end

                T_ISSUE_LH: if (req_ready) state <= T_WAIT_LH;
                T_WAIT_LH: if (done) begin
                    if (rdata == 32'hFFFF_C35A) state <= T_ISSUE_LHU;
                    else state <= T_FAIL;
                end

                T_ISSUE_LHU: if (req_ready) state <= T_WAIT_LHU;
                T_WAIT_LHU: if (done) begin
                    if (rdata == 32'h0000_C35A) state <= T_ISSUE_SB;
                    else state <= T_FAIL;
                end

                T_ISSUE_SB: if (req_ready) state <= T_WAIT_SB;
                T_WAIT_SB: if (done) state <= T_ISSUE_LW1;

                T_ISSUE_LW1: if (req_ready) state <= T_WAIT_LW1;
                T_WAIT_LW1: if (done) begin
                    if (rdata == 32'hC396_ED3E) state <= T_ISSUE_SH;
                    else state <= T_FAIL;
                end

                T_ISSUE_SH: if (req_ready) state <= T_WAIT_SH;
                T_WAIT_SH: if (done) state <= T_ISSUE_LW2;

                T_ISSUE_LW2: if (req_ready) state <= T_WAIT_LW2;
                T_WAIT_LW2: if (done) begin
                    if (rdata == 32'hC396_1234) state <= T_ISSUE_SW1;
                    else state <= T_FAIL;
                end

                T_ISSUE_SW1: if (req_ready) state <= T_WAIT_SW1;
                T_WAIT_SW1: if (done) state <= T_ISSUE_LW3;

                T_ISSUE_LW3: if (req_ready) state <= T_WAIT_LW3;
                T_WAIT_LW3: if (done) begin
                    if (rdata == 32'hA596_69F0) state <= T_PASS;
                    else state <= T_FAIL;
                end

                T_PASS: state <= T_PASS;
                T_FAIL: state <= T_FAIL;
                default: state <= T_FAIL;
            endcase
        end
    end

    // Board LEDs are active-low.
    assign led_n[0] = (state != T_PASS);
    assign led_n[1] = (state != T_FAIL);

endmodule
