
module memory_subword #(
    parameter INIT_FILE = ""
) (
    input  logic        clk,
    input  logic [31:0] address,
    input  logic [31:0] write_data_in,
    input  logic        read_enable,
    input  logic        write_enable,
    input  logic [1:0]  access_size,
    input  logic        load_unsigned,
    output logic [31:0] read_data_out
);

    // 4 KiB memory: 1024 words x 32 bits.
    // Intended for Gowin block-RAM inference.
    (* ram_style = "block" *)
    logic [31:0] memory [0:1023];

    logic [9:0]  word_addr;
    logic [3:0]  byte_write_enable;
    logic [31:0] shifted_write_data;

    // Registered synchronous-read output and metadata.
    logic [31:0] read_word_q;
    logic [1:0]  read_offset_q;
    logic [1:0]  read_size_q;
    logic        read_unsigned_q;

    logic [31:0] shifted_read_word;

    assign word_addr = address[11:2];

    // Initialize the memory image. INIT_FILE is a
    // 32-bit-word hex file, not the old byte-per-line file.
    initial begin
        if (INIT_FILE != "")
            $readmemh(INIT_FILE, memory);

        read_word_q     = 32'h00000000;
        read_offset_q   = 2'b00;
        read_size_q     = 2'b10;
        read_unsigned_q = 1'b0;
    end

    // Generate byte-lane write enables.
    // Naturally aligned halfword and word stores are supported.
    always_comb begin
        byte_write_enable = 4'b0000;
        shifted_write_data =
            write_data_in << {address[1:0], 3'b000};

        if (write_enable) begin
            case (access_size)
                2'b00: begin // SB
                    byte_write_enable =
                        4'b0001 << address[1:0];
                end

                2'b01: begin // SH: offsets 0 or 2
                    if (!address[0])
                        byte_write_enable =
                            4'b0011 << address[1:0];
                end

                2'b10: begin // SW: word-aligned
                    if (address[1:0] == 2'b00)
                        byte_write_enable = 4'b1111;
                end

                default: begin
                    byte_write_enable = 4'b0000;
                end
            endcase
        end
    end

    // Single-port synchronous memory:
    // a cycle performs either a write or a read.
    always_ff @(posedge clk) begin
        if (write_enable) begin
            for (integer lane = 0; lane < 4; lane = lane + 1) begin
                if (byte_write_enable[lane]) begin
                    memory[word_addr][lane*8 +: 8]
                        <= shifted_write_data[lane*8 +: 8];
                end
            end
        end
        else if (read_enable) begin
            read_word_q     <= memory[word_addr];
            read_offset_q   <= address[1:0];
            read_size_q     <= access_size;
            read_unsigned_q <= load_unsigned;
        end
    end

    // Subword selection is combinational, but the underlying
    // word came from the synchronous RAM read above.
    always_comb begin
        shifted_read_word =
            read_word_q >> {read_offset_q, 3'b000};

        case (read_size_q)
            2'b00: begin // LB / LBU
                if (read_unsigned_q)
                    read_data_out =
                        {24'b0, shifted_read_word[7:0]};
                else
                    read_data_out = {
                        {24{shifted_read_word[7]}},
                        shifted_read_word[7:0]
                    };
            end

            2'b01: begin // LH / LHU
                if (read_unsigned_q)
                    read_data_out =
                        {16'b0, shifted_read_word[15:0]};
                else
                    read_data_out = {
                        {16{shifted_read_word[15]}},
                        shifted_read_word[15:0]
                    };
            end

            2'b10: begin // LW / instruction fetch
                read_data_out = read_word_q;
            end

            default: begin
                read_data_out = 32'b0;
            end
        endcase
    end

endmodule
