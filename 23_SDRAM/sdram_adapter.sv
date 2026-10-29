// CPU-facing memory adapter for the NESTang Tang Nano 20K SDRAM controller.
//
// CPU-side contract:
//   - Present req/we/addr/wdata/access_size/load_unsigned.
//   - Keep req asserted until req_ready is observed high at a rising edge.
//   - After acceptance, wait for done. rdata is valid with done and remains
//     stable until the next completed read.
//   - Only issue requests whose byte address is in SDRAM_BASE..SDRAM_LAST.
//
// The stock controller accepts one byte per write. SH/SW are therefore split
// into two/four byte writes here. The controller itself is intentionally kept
// unchanged.

module sdram_adapter #(
    parameter integer FREQ_HZ = 27_000_000,
    parameter logic [31:0] SDRAM_BASE = 32'h0000_1000
) (
    input  wire        clk,
    input  wire        clk_sdram,
    input  wire        reset,          // active-high system reset

    // CPU-side request/response interface
    input  wire        req,
    output wire        req_ready,
    input  wire        we,             // 0 = read, 1 = write
    input  wire [31:0] addr,           // CPU byte address
    input  wire [31:0] wdata,
    input  wire [1:0]  access_size,    // 00 byte, 01 halfword, 10 word
    input  wire        load_unsigned,
    output reg  [31:0] rdata,
    output reg         done,           // one-cycle completion pulse

    // Physical SDRAM connections. The top-level wrapper should connect these
    // to the Tang Nano 20K's magic O_sdram_*/IO_sdram_* port names.
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

    localparam integer REFRESH_INTERVAL = (FREQ_HZ / 1_000_000) * 15;

    localparam [2:0] ST_IDLE            = 3'd0;
    localparam [2:0] ST_WAIT_CONTROLLER = 3'd1;
    localparam [2:0] ST_WAIT_BUSY_HIGH  = 3'd2;
    localparam [2:0] ST_WAIT_BUSY_LOW   = 3'd3;

    reg [2:0] state;

    // One-entry request buffer. req_ready stays high while a refresh command
    // is in flight, so a CPU request can be accepted and held until refresh ends.
    reg        request_active;
    reg        req_we_q;
    reg [31:0] req_addr_q;
    reg [31:0] req_wdata_q;
    reg [1:0]  req_size_q;
    reg        req_unsigned_q;
    reg [2:0]  byte_count_q;   // 0 means unsupported/misaligned store; else 1, 2, or 4
    reg [2:0]  byte_index_q;

    // Low-level controller command/data signals.
    reg  [22:0] ctrl_addr;
    reg  [7:0]  ctrl_din;
    reg         ctrl_rd;
    reg         ctrl_wr;
    reg         ctrl_refresh;
    wire [7:0]  ctrl_dout;
    wire [31:0] ctrl_dout32;
    wire        ctrl_data_ready;
    wire        ctrl_busy;

    reg         operation_is_refresh;
    reg         read_captured;
    reg [31:0]  read_word_q;

    // Periodic refresh request. The counter reaches 404 on a 27 MHz clock,
    // resulting in one refresh request every 405 clocks (~15 us).
    reg [15:0] refresh_counter;
    reg        refresh_pending;

    // req_ready is an acceptance handshake, not the controller's busy signal.
    // The adapter can accept one request even while the SDRAM controller is
    // running a refresh; it will execute the request once the controller is free.
    assign req_ready = !request_active && !done;

    // Format the captured 32-bit word exactly like memory_subword.sv:
    // byte/halfword operations shift by the byte offset; LW returns the whole
    // stored word. Naturally aligned halfword/word stores are supported.
    reg [31:0] shifted_read_word;
    reg [31:0] formatted_read_data;

    always @* begin
        shifted_read_word = read_word_q >> {req_addr_q[1:0], 3'b000};
        formatted_read_data = 32'b0;

        case (req_size_q)
            2'b00: begin // LB / LBU
                if (req_unsigned_q)
                    formatted_read_data = {24'b0, shifted_read_word[7:0]};
                else
                    formatted_read_data = {
                        {24{shifted_read_word[7]}}, shifted_read_word[7:0]
                    };
            end

            2'b01: begin // LH / LHU
                if (req_unsigned_q)
                    formatted_read_data = {16'b0, shifted_read_word[15:0]};
                else
                    formatted_read_data = {
                        {16{shifted_read_word[15]}}, shifted_read_word[15:0]
                    };
            end

            2'b10: begin // LW / instruction fetch
                formatted_read_data = read_word_q;
            end

            default: formatted_read_data = 32'b0;
        endcase
    end

    sdram #(.FREQ(FREQ_HZ)) sdram_controller (
        .SDRAM_DQ   (SDRAM_DQ),
        .SDRAM_A    (SDRAM_A),
        .SDRAM_BA   (SDRAM_BA),
        .SDRAM_nCS  (SDRAM_nCS),
        .SDRAM_nWE  (SDRAM_nWE),
        .SDRAM_nRAS (SDRAM_nRAS),
        .SDRAM_nCAS (SDRAM_nCAS),
        .SDRAM_CLK  (SDRAM_CLK),
        .SDRAM_CKE  (SDRAM_CKE),
        .SDRAM_DQM  (SDRAM_DQM),
        .clk        (clk),
        .clk_sdram  (clk_sdram),
        .resetn     (!reset),
        .rd         (ctrl_rd),
        .wr         (ctrl_wr),
        .refresh    (ctrl_refresh),
        .addr       (ctrl_addr),
        .din        (ctrl_din),
        .dout       (ctrl_dout),
        .dout32     (ctrl_dout32),
        .data_ready (ctrl_data_ready),
        .busy       (ctrl_busy)
    );

    always @(posedge clk) begin
        if (reset) begin
            state                 <= ST_IDLE;
            request_active        <= 1'b0;
            req_we_q              <= 1'b0;
            req_addr_q            <= 32'b0;
            req_wdata_q           <= 32'b0;
            req_size_q            <= 2'b10;
            req_unsigned_q        <= 1'b0;
            byte_count_q          <= 3'd0;
            byte_index_q          <= 3'd0;
            ctrl_addr             <= 23'b0;
            ctrl_din              <= 8'b0;
            ctrl_rd               <= 1'b0;
            ctrl_wr               <= 1'b0;
            ctrl_refresh          <= 1'b0;
            operation_is_refresh  <= 1'b0;
            read_captured         <= 1'b0;
            read_word_q           <= 32'b0;
            rdata                 <= 32'b0;
            done                  <= 1'b0;
            refresh_counter       <= 16'b0;
            refresh_pending       <= 1'b0;
        end else begin
            // These are command pulses. The controller samples them on a later
            // rising edge, by which time ctrl_addr/ctrl_din are already stable.
            ctrl_rd      <= 1'b0;
            ctrl_wr      <= 1'b0;
            ctrl_refresh <= 1'b0;
            done         <= 1'b0;

            // Keep one refresh pending until it can be issued. The SDRAM
            // controller itself has its own ~200 us power-up initialization.
            if (!refresh_pending) begin
                if (refresh_counter >= REFRESH_INTERVAL - 1) begin
                    refresh_counter <= 16'b0;
                    refresh_pending <= 1'b1;
                end else begin
                    refresh_counter <= refresh_counter + 1'b1;
                end
            end

            // Accept and latch the CPU request exactly once. Requests may be
            // accepted during refresh, then wait in the request buffer.
            if (req && req_ready) begin
                request_active <= 1'b1;
                req_we_q       <= we;
                req_addr_q     <= addr;
                req_wdata_q    <= wdata;
                req_size_q     <= access_size;
                req_unsigned_q <= load_unsigned;
                byte_index_q   <= 3'd0;
                read_captured  <= 1'b0;

                if (!we) begin
                    byte_count_q <= 3'd1; // one controller read returns the full 32-bit word
                end else begin
                    case (access_size)
                        2'b00: byte_count_q <= 3'd1; // SB
                        2'b01: byte_count_q <= addr[0] ? 3'd0 : 3'd2; // SH alignment
                        2'b10: byte_count_q <= (addr[1:0] == 2'b00) ? 3'd4 : 3'd0; // SW alignment
                        default: byte_count_q <= 3'd0;
                    endcase
                end
            end

            case (state)
                ST_IDLE: begin
                    if (request_active) begin
                        state <= ST_WAIT_CONTROLLER;
                    end else if (refresh_pending && !ctrl_busy) begin
                        // No CPU request is active, so service the refresh.
                        ctrl_refresh         <= 1'b1;
                        refresh_pending      <= 1'b0;
                        refresh_counter      <= 16'b0;
                        operation_is_refresh <= 1'b1;
                        state                <= ST_WAIT_BUSY_HIGH;
                    end
                end

                ST_WAIT_CONTROLLER: begin
                    // Match memory_subword's behavior for misaligned SH/SW:
                    // suppress the store rather than touching SDRAM.
                    if (request_active && req_we_q && (byte_count_q == 3'd0)) begin
                        done           <= 1'b1;
                        request_active <= 1'b0;
                        state          <= ST_IDLE;
                    end else if (!ctrl_busy) begin
                        // Refresh between bytes if one became due during a
                        // multi-byte store. The CPU request remains buffered.
                        if (refresh_pending) begin
                            ctrl_refresh         <= 1'b1;
                            refresh_pending      <= 1'b0;
                            refresh_counter      <= 16'b0;
                            operation_is_refresh <= 1'b1;
                            state                <= ST_WAIT_BUSY_HIGH;
                        end else if (req_we_q) begin
                            ctrl_addr <= (req_addr_q - SDRAM_BASE) + byte_index_q;
                            ctrl_din  <= req_wdata_q >> (byte_index_q * 8);
                            ctrl_wr   <= 1'b1;
                            operation_is_refresh <= 1'b0;
                            state     <= ST_WAIT_BUSY_HIGH;
                        end else begin
                            ctrl_addr <= req_addr_q - SDRAM_BASE;
                            ctrl_rd   <= 1'b1;
                            operation_is_refresh <= 1'b0;
                            state     <= ST_WAIT_BUSY_HIGH;
                        end
                    end
                end

                ST_WAIT_BUSY_HIGH: begin
                    // First observe busy rising to prove the controller accepted
                    // the one-cycle rd/wr/refresh command.
                    if (ctrl_busy)
                        state <= ST_WAIT_BUSY_LOW;
                end

                ST_WAIT_BUSY_LOW: begin
                    // dout32 is a live bus; capture it only during data_ready.
                    if (!operation_is_refresh && !req_we_q && ctrl_data_ready) begin
                        read_word_q  <= ctrl_dout32;
                        read_captured <= 1'b1;
                    end

                    if (!ctrl_busy) begin
                        if (operation_is_refresh) begin
                            operation_is_refresh <= 1'b0;
                            if (request_active)
                                state <= ST_WAIT_CONTROLLER;
                            else
                                state <= ST_IDLE;
                        end else if (req_we_q) begin
                            if ((byte_index_q + 1'b1) < byte_count_q) begin
                                byte_index_q <= byte_index_q + 1'b1;
                                state <= ST_WAIT_CONTROLLER;
                            end else begin
                                done           <= 1'b1;
                                request_active <= 1'b0;
                                state          <= ST_IDLE;
                            end
                        end else if (read_captured) begin
                            rdata          <= formatted_read_data;
                            done           <= 1'b1;
                            request_active <= 1'b0;
                            state          <= ST_IDLE;
                        end
                        // If busy falls before we have observed data_ready,
                        // remain here until the read data has been captured.
                    end
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
