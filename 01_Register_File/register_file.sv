module register_file (
    input  logic       clk,

    input  logic       write_en,
    input  logic [4:0] write_addr,
    input  logic [31:0] write_data,

    input  logic [4:0] read_addr1,
    output logic [31:0] read_data1,

    input  logic [4:0] read_addr2,
    output logic [31:0] read_data2
);

    logic [31:0] registers [0:31];

//clock edge write data
    always_ff @(posedge clk) begin
        if (write_en && write_addr != 5'd0)
            registers[write_addr] <= write_data;
    end
    
    // Ensure register 0 always reads as 0 and read data can be not during clock edge
    assign read_data1 = (read_addr1 != 5'd0) ? registers[read_addr1] : 32'd0;
    assign read_data2 = (read_addr2 != 5'd0) ? registers[read_addr2] : 32'd0;

endmodule
