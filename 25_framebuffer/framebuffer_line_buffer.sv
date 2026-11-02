
module framebuffer_line_buffer #(
    parameter int LINE_WIDTH = 360,
    parameter int ADDR_WIDTH = 9
) (
    // Independent clock domains
    input  logic                  wr_clk,
    input  logic                  rd_clk,

    input  logic                  wr_rst,
    input  logic                  rd_rst,

    // Write interface: framebuffer controller
    input  logic                  wr_en,
    input  logic                  wr_bank,
    input  logic [ADDR_WIDTH-1:0] wr_addr,
    input  logic [7:0]            wr_data,

    // Read interface: HDMI scanout
    input  logic                  rd_en,
    input  logic                  rd_bank,
    input  logic [ADDR_WIDTH-1:0] rd_addr,
    output logic [7:0]            rd_data
);

    // Two independent line-buffer banks
    logic [7:0] buffer_a [0:LINE_WIDTH-1];
    logic [7:0] buffer_b [0:LINE_WIDTH-1];

    // Write side: clk_main
    always_ff @(posedge wr_clk) begin
        if (!wr_rst && wr_en && (wr_addr < LINE_WIDTH)) begin
            if (!wr_bank)
                buffer_a[wr_addr] <= wr_data;
            else
                buffer_b[wr_addr] <= wr_data;
        end
    end

    // Read side: HDMI pixel clock
    always_ff @(posedge rd_clk) begin
        if (rd_rst) begin
            rd_data <= 8'b0;
        end
        else if (rd_en && (rd_addr < LINE_WIDTH)) begin
            if (!rd_bank)
                rd_data <= buffer_a[rd_addr];
            else
                rd_data <= buffer_b[rd_addr];
        end
        else begin
            rd_data <= 8'b0;
        end
    end

endmodule
