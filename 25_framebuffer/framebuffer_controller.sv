
module framebuffer_controller #(
    parameter logic [22:0] FB_BASE_ADDR = 23'h000000,
    parameter integer LINE_BYTES = 360,
    parameter integer WORDS_PER_LINE = 90
) (
    input  logic        clk,
    input  logic        rst,

    // SDRAM service interface
    output logic        fb_req,
    input  logic        fb_ready,
    output logic [22:0] fb_addr,
    input  logic        fb_done,
    input  logic [31:0] fb_rdata,

    // Line-buffer write interface
    output logic        line_wr_en,
    output logic        line_wr_bank,
    output logic [8:0]  line_wr_addr,
    output logic [7:0]  line_wr_data,

    // Display / buffer management
    input  logic        read_complete,
    output logic        display_bank,
    output logic        display_valid
);

    // --------------------------------------------------------
    // FSM states
    // --------------------------------------------------------

    typedef enum logic [2:0] {
        IDLE,
        REQUEST_WORD,
        WAIT_ACCEPT,
        WAIT_DATA,
        WRITE_BYTES,
        WAIT_SWAP
    } state_t;

    state_t state;

    // --------------------------------------------------------
    // Transaction tracking
    // --------------------------------------------------------

    logic [6:0] word_index;       // 0-89
    logic [1:0] byte_index;       // 0-3

    logic [31:0] word_buffer;

    logic [8:0] framebuffer_row;
    logic [22:0] row_base_addr;

    // Bank currently being filled.
    logic fill_bank;

    // Indicates that all 360 bytes have been written.
    logic write_complete;

    logic read_complete_seen;

    // --------------------------------------------------------
    // Address generation
    // --------------------------------------------------------

    // Each word contains four consecutive framebuffer bytes.
    // SDRAM service addresses are byte addresses.
    always_comb begin
        fb_addr = row_base_addr + {word_index, 2'b00};
    end

    // --------------------------------------------------------
    // Main controller FSM
    // --------------------------------------------------------

    always_ff @(posedge clk) begin
        if (rst) begin

            state <= IDLE;

            fb_req <= 1'b0;

            line_wr_en   <= 1'b0;
            line_wr_bank <= 1'b0;
            line_wr_addr <= 9'd0;
            line_wr_data <= 8'd0;

            word_index <= 7'd0;
            byte_index <= 2'd0;

            word_buffer <= 32'd0;

            framebuffer_row <= 9'd0;
            row_base_addr <= FB_BASE_ADDR;

            fill_bank <= 1'b0;

            write_complete <= 1'b0;

            display_bank <= 1'b0;
            display_valid <= 1'b0;
            read_complete_seen <= 1'b0;

        end else begin

            // Default pulse outputs.
            line_wr_en <= 1'b0;
            // Remember that the current display row has finished reading.
            if (display_valid && read_complete)
                read_complete_seen <= 1'b1;

            case (state)

                // ------------------------------------------------
                // Begin fetching a framebuffer word.
                // ------------------------------------------------
                IDLE: begin
                    word_index <= 7'd0;

                    if (!display_valid)
                        fill_bank <= 1'b0;
                    else
                        fill_bank <= ~display_bank;

                    row_base_addr <= FB_BASE_ADDR + framebuffer_row * LINE_BYTES;

                    state <= REQUEST_WORD;
                end

                // ------------------------------------------------
                // Assert request to SDRAM service.
                // ------------------------------------------------
                REQUEST_WORD: begin

                    fb_req <= 1'b1;

                    state <= WAIT_ACCEPT;

                end

                // ------------------------------------------------
                // Hold request until accepted.
                // ------------------------------------------------
                WAIT_ACCEPT: begin

                    if (fb_ready) begin

                        fb_req <= 1'b0;

                        state <= WAIT_DATA;

                    end

                end

                // ------------------------------------------------
                // Wait for returned 32-bit word.
                // ------------------------------------------------
                WAIT_DATA: begin

                    if (fb_done) begin

                        word_buffer <= fb_rdata;

                        byte_index <= 2'd0;

                        state <= WRITE_BYTES;

                    end

                end

                // ------------------------------------------------
                // Write four bytes into the line buffer.
                // ------------------------------------------------
                WRITE_BYTES: begin

                    line_wr_en   <= 1'b1;
                    line_wr_bank <= fill_bank;

                    case (byte_index)

                        2'd0: line_wr_data <= word_buffer[7:0];
                        2'd1: line_wr_data <= word_buffer[15:8];
                        2'd2: line_wr_data <= word_buffer[23:16];
                        2'd3: line_wr_data <= word_buffer[31:24];

                    endcase

                    line_wr_addr <= {word_index, 2'b00} + byte_index;

                    if (byte_index == 2'd3 && word_index == 7'd89) begin
                        byte_index     <= 2'd0;
                        word_index     <= 7'd0;
                        write_complete <= 1'b1;
                        state          <= WAIT_SWAP;
                    end
                    else if (byte_index == 2'd3) begin
                        byte_index <= 2'd0;
                        word_index <= word_index + 1'b1;
                        state <= REQUEST_WORD;
                    end
                    else begin
                        byte_index <= byte_index + 1'b1;
                    end



                end

                // ------------------------------------------------
                // Wait until the current display buffer is free.
                // ------------------------------------------------
                WAIT_SWAP: begin

                    // Startup: first row has been loaded into bank A.
                    if (!display_valid && write_complete) begin

                        display_bank <= 1'b0;
                        display_valid <= 1'b1;
                        write_complete <= 1'b0;
                        read_complete_seen <= 1'b0;

                        framebuffer_row <= framebuffer_row + 1'b1;

                        state <= IDLE;

                    end

                    // Normal operation: both sides have finished.
                    else if (display_valid && write_complete && read_complete_seen) begin

                        display_bank <= ~display_bank;
                        write_complete <= 1'b0;
                        read_complete_seen <= 1'b0;

                        if (framebuffer_row == 9'd239)
                            framebuffer_row <= 9'd0;
                        else
                            framebuffer_row <= framebuffer_row + 1'b1;

                        state <= IDLE;

                    end

                end

                default: begin
                    state <= IDLE;
                    fb_req <= 1'b0;
                end

            endcase

        end
    end

endmodule

