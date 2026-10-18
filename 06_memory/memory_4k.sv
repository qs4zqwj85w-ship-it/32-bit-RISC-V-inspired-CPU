//Note, appaently verilator hates unused signals so i gotta use address valid
// just to validate and use the signals.

module memory_4k (
    input logic clk,
    input  logic [31:0] address ,
    input  logic [31:0] write_data_in,
    input logic write_enable,

    output logic [31:0] read_data_out
);

    logic [7:0] memory [0:4095];
    logic [9:0] word_index;

    logic address_valid;

    assign word_index = address[11:2];

    assign address_valid =
        (address[31:12] == 20'd0) &&
        (address[1:0] == 2'b00);

    always_ff @(posedge clk) begin
        if (write_enable && address_valid) begin 
            memory[{word_index, 2'b00}] <= write_data_in[7:0];
            memory[{word_index, 2'b01}] <= write_data_in[15:8];
            memory[{word_index, 2'b10}] <= write_data_in[23:16];
            memory[{word_index, 2'b11}] <= write_data_in[31:24];
        end
    end

    // Read Logic
    assign read_data_out = address_valid
    ? {memory[{word_index, 2'b11}],
       memory[{word_index, 2'b10}],
       memory[{word_index, 2'b01}],
       memory[{word_index, 2'b00}]}
    : 32'b0;







endmodule

