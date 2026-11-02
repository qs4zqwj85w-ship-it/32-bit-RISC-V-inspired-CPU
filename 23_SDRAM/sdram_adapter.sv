
// CPU-facing memory adapter for the shared SDRAM service.
//
// CPU-side contract:
//   - Present req/we/addr/wdata/access_size/load_unsigned.
//   - Keep req asserted until req_ready is observed high at a rising edge.
//   - After acceptance, wait for done.
//   - rdata is valid with done and remains stable until the next completed read.
//   - Only issue requests whose byte address is in SDRAM_BASE..SDRAM_LAST.
//
// Shared SDRAM service contract:
//   - Adapter asserts mem_req with stable transaction fields.
//   - Service asserts mem_ready when it accepts the transaction.
//   - Adapter deasserts mem_req after acceptance.
//   - Service asserts mem_done when the transaction completes.
//   - mem_rdata is valid when mem_done is asserted.
//   - Reads return an aligned 32-bit word.
//   - Writes write exactly one byte.
//
// The shared service owns the physical SDRAM controller and refresh logic.
// This adapter handles CPU access sizes and converts stores into byte writes.

module sdram_adapter #(
    parameter logic [31:0] SDRAM_BASE = 32'h0000_1000
) (
    input  wire        clk,
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

    // Shared SDRAM service interface
    output reg         mem_req,
    input  wire        mem_ready,
    output reg         mem_we,         // 0 = read, 1 = byte write
    output reg  [22:0] mem_addr,       // byte address relative to SDRAM_BASE
    output reg  [7:0]  mem_wdata,
    input  wire        mem_done,
    input  wire [31:0] mem_rdata
);

    localparam [1:0] ST_IDLE      = 2'd0;
    localparam [1:0] ST_ISSUE     = 2'd1;
    localparam [1:0] ST_WAIT_DONE = 2'd2;

    reg [1:0] state;

    // One-entry CPU request buffer.
    reg        request_active;
    reg        req_we_q;
    reg [31:0] req_addr_q;
    reg [31:0] req_wdata_q;
    reg [1:0]  req_size_q;
    reg        req_unsigned_q;

    // 0 means unsupported/misaligned store; otherwise 1, 2, or 4.
    reg [2:0] byte_count_q;
    reg [2:0] byte_index_q;

    // Format the returned aligned 32-bit word.
    // The shared service returns the complete word containing the
    // requested byte address.
    reg [31:0] shifted_read_word;
    reg [31:0] formatted_read_data;

    always @* begin
        shifted_read_word = mem_rdata >> {req_addr_q[1:0], 3'b000};
        formatted_read_data = 32'b0;

        case (req_size_q)
            2'b00: begin // LB / LBU
                if (req_unsigned_q)
                    formatted_read_data = {
                        24'b0, shifted_read_word[7:0]
                    };
                else
                    formatted_read_data = {
                        {24{shifted_read_word[7]}},
                        shifted_read_word[7:0]
                    };
            end

            2'b01: begin // LH / LHU
                if (req_unsigned_q)
                    formatted_read_data = {
                        16'b0, shifted_read_word[15:0]
                    };
                else
                    formatted_read_data = {
                        {16{shifted_read_word[15]}},
                        shifted_read_word[15:0]
                    };
            end

            2'b10: begin // LW / instruction fetch
                formatted_read_data = mem_rdata;
            end

            default: formatted_read_data = 32'b0;
        endcase
    end

    // CPU-side acceptance handshake.
    // One CPU request can be buffered at a time.
    assign req_ready = !request_active && !done;

    always @(posedge clk) begin
        if (reset) begin
            state          <= ST_IDLE;

            request_active <= 1'b0;
            req_we_q       <= 1'b0;
            req_addr_q     <= 32'b0;
            req_wdata_q    <= 32'b0;
            req_size_q     <= 2'b10;
            req_unsigned_q <= 1'b0;

            byte_count_q   <= 3'd0;
            byte_index_q   <= 3'd0;

            mem_req        <= 1'b0;
            mem_we         <= 1'b0;
            mem_addr       <= 23'b0;
            mem_wdata      <= 8'b0;

            rdata          <= 32'b0;
            done           <= 1'b0;
        end else begin
            // Default: done is a one-cycle pulse.
            done <= 1'b0;

            // Accept and latch a CPU request exactly once.
            if (req && req_ready) begin
                request_active <= 1'b1;

                req_we_q       <= we;
                req_addr_q     <= addr;
                req_wdata_q    <= wdata;
                req_size_q     <= access_size;
                req_unsigned_q <= load_unsigned;

                byte_index_q   <= 3'd0;

                if (!we) begin
                    // One aligned-word read returns the requested data.
                    byte_count_q <= 3'd1;
                end else begin
                    // The physical SDRAM service supports byte writes.
                    // Split larger stores into individual byte writes.
                    case (access_size)
                        2'b00: byte_count_q <= 3'd1; // SB

                        2'b01:
                            byte_count_q <= addr[0]
                                ? 3'd0 : 3'd2;        // SH alignment

                        2'b10:
                            byte_count_q <= (addr[1:0] == 2'b00)
                                ? 3'd4 : 3'd0;        // SW alignment

                        default:
                            byte_count_q <= 3'd0;
                    endcase
                end
            end

            case (state)

                // Wait for a buffered CPU request.
                ST_IDLE: begin
                    mem_req <= 1'b0;

                    if (request_active) begin
                        // Suppress unsupported or misaligned stores.
                        if (req_we_q && (byte_count_q == 3'd0)) begin
                            done           <= 1'b1;
                            request_active <= 1'b0;
                        end else begin
                            // Prepare the first shared-service transaction.
                            mem_addr <=
                                (req_addr_q - SDRAM_BASE) + byte_index_q;

                            if (req_we_q) begin
                                mem_we    <= 1'b1;
                                mem_wdata <=
                                    req_wdata_q >> (byte_index_q * 8);
                            end else begin
                                mem_we    <= 1'b0;
                                mem_wdata <= 8'b0;
                            end

                            mem_req <= 1'b1;
                            state   <= ST_ISSUE;
                        end
                    end
                end

                // Hold the request stable until the service accepts it.
                ST_ISSUE: begin
                    if (mem_ready) begin
                        mem_req <= 1'b0;
                        state   <= ST_WAIT_DONE;
                    end
                end

                // Wait for the accepted memory transaction to complete.
                ST_WAIT_DONE: begin
                    if (mem_done) begin
                        if (req_we_q) begin
                            // More bytes remain in an SH or SW store.
                            if ((byte_index_q + 1'b1) < byte_count_q) begin
                                byte_index_q <= byte_index_q + 1'b1;

                                // Prepare the next byte transaction.
                                mem_addr <=
                                    (req_addr_q - SDRAM_BASE)
                                    + byte_index_q + 1'b1;

                                mem_we <= 1'b1;
                                mem_wdata <=
                                    req_wdata_q >>
                                    ((byte_index_q + 1'b1) * 8);

                                mem_req <= 1'b1;
                                state   <= ST_ISSUE;
                            end else begin
                                // All bytes have been written.
                                done           <= 1'b1;
                                request_active <= 1'b0;
                                state          <= ST_IDLE;
                            end
                        end else begin
                            // Read data is valid alongside mem_done.
                            rdata          <= formatted_read_data;
                            done           <= 1'b1;
                            request_active <= 1'b0;
                            state          <= ST_IDLE;
                        end
                    end
                end

                default: begin
                    state   <= ST_IDLE;
                    mem_req <= 1'b0;
                end

            endcase
        end
    end

endmodule
