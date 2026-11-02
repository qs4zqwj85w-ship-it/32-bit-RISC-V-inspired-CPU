
module framebuffer_line_buffer #(
    parameter int LINE_WIDTH = 360,
    parameter int ADDR_WIDTH = 9
) (
    input  logic                  clk,
    input  logic                  rst,

    // Write interface (framebuffer controller)
    input  logic                  wr_en,
    input  logic                  wr_bank,
    input  logic [ADDR_WIDTH-1:0] wr_addr,
    input  logic [7:0]            wr_data,

    // Read interface (framebuffer scanout)
    input  logic                  rd_en,
    input  logic                  rd_bank,
    input  logic [ADDR_WIDTH-1:0] rd_addr,
    output logic [7:0]            rd_data
);

    // Two independent line-buffer banks.
    logic [7:0] buffer_a [0:LINE_WIDTH-1];
    logic [7:0] buffer_b [0:LINE_WIDTH-1];

    // Synchronous write and read.
    always_ff @(posedge clk) begin

        if (rst) begin
            rd_data <= 8'b0;
        end
        else begin

            // Write selected bank.
            if (wr_en && (wr_addr < LINE_WIDTH)) begin
                if (wr_bank == 1'b0)
                    buffer_a[wr_addr] <= wr_data;
                else
                    buffer_b[wr_addr] <= wr_data;
            end

            // Read selected bank.
            if (rd_en && (rd_addr < LINE_WIDTH)) begin
                if (rd_bank == 1'b0)
                    rd_data <= buffer_a[rd_addr];
                else
                    rd_data <= buffer_b[rd_addr];
            end

        end
    end

endmodule
