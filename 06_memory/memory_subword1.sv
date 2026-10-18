//Note, this is for simulation so file is directly loaded in to memory here

module memory_subword #(
    parameter INIT_FILE = "")
    (
    input  logic        clk,
    input  logic [31:0] address,
    input  logic [31:0] write_data_in,
    input  logic        write_enable,
    input  logic [1:0]  access_size,
    input  logic        load_unsigned,

    output logic [31:0] read_data_out
);

    // Initialize memory and optionally load a program image
    initial begin
        for (integer i = 0; i < 4096; i = i + 1)
            memory[i] = 8'h00;

        if (INIT_FILE != "") begin
            $display("Loading program from %s", INIT_FILE);
            $readmemh(INIT_FILE, memory);
        end
    end

    // 4 KiB of byte-addressable memory
    logic [7:0] memory [0:4095];

    // Byte index within the 4 KiB address range
    logic [11:0] byte_index;
    logic        address_valid;

    assign byte_index = address[11:0];

    // Validate address range and alignment
    always_comb begin
        address_valid = 1'b0;

        if (address[31:12] == 20'd0) begin
            case (access_size)
                2'b00: begin
                    // Byte: any address is valid
                    address_valid = 1'b1;
                end

                2'b01: begin
                    // Halfword: address must be even
                    address_valid = (address[0] == 1'b0);
                end

                2'b10: begin
                    // Word: address must be 4-byte aligned
                    address_valid = (address[1:0] == 2'b00);
                end

                default: begin
                    // Reserved access size
                    address_valid = 1'b0;
                end
            endcase
        end
    end

    // Write Logic
    always_ff @(posedge clk) begin
        if (write_enable && address_valid) begin
            case (access_size)

                2'b00: begin
                    // SB: store one byte
                    memory[byte_index] <= write_data_in[7:0];
                end

                2'b01: begin
                    // SH: store two bytes (little-endian)
                    memory[byte_index]          <= write_data_in[7:0];
                    memory[byte_index + 12'd1]  <= write_data_in[15:8];
                end

                2'b10: begin
                    // SW: store four bytes (little-endian)
                    memory[byte_index]          <= write_data_in[7:0];
                    memory[byte_index + 12'd1]  <= write_data_in[15:8];
                    memory[byte_index + 12'd2]  <= write_data_in[23:16];
                    memory[byte_index + 12'd3]  <= write_data_in[31:24];
                end

                default: begin
                    // Invalid access: no write
                end

            endcase
        end
    end

    // Read Logic
    always_comb begin
        read_data_out = 32'b0;

        if (address_valid) begin
            case (access_size)

                2'b00: begin
                    // LB / LBU: read one byte
                    if (load_unsigned) begin
                        read_data_out = {
                            24'b0,
                            memory[byte_index]
                        };
                    end
                    else begin
                        // Sign-extend the 8-bit value
                        read_data_out = {
                            {24{memory[byte_index][7]}},
                            memory[byte_index]
                        };
                    end
                end

                2'b01: begin
                    // LH / LHU: read two bytes
                    if (load_unsigned) begin
                        read_data_out = {
                            16'b0,
                            memory[byte_index + 12'd1],
                            memory[byte_index]
                        };
                    end
                    else begin
                        // Sign-extend the 16-bit value
                        read_data_out = {
                            {16{memory[byte_index + 12'd1][7]}},
                            memory[byte_index + 12'd1],
                            memory[byte_index]
                        };
                    end
                end

                2'b10: begin
                    // LW: read four bytes
                    read_data_out = {
                        memory[byte_index + 12'd3],
                        memory[byte_index + 12'd2],
                        memory[byte_index + 12'd1],
                        memory[byte_index]
                    };
                end

                default: begin
                    // Invalid access: return zero
                    read_data_out = 32'b0;
                end

            endcase
        end
    end

endmodule
