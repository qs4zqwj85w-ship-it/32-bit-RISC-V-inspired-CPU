module tmds_serializer (
    input logic clk_pixel,
    input logic clk_pixel_x5,
    input logic rst,

    input logic [9:0] tmds_red,
    input logic [9:0] tmds_green,
    input logic [9:0] tmds_blue,

    output logic serial_red,
    output logic serial_green,
    output logic serial_blue,
    output logic tmds_clock
);
`ifdef VERILATOR


`else
    OSER10 gwSer0( 
        .Q( serial_red ),
        .D0( tmds_red[ 0 ] ),
        .D1( tmds_red[ 1 ] ),
        .D2( tmds_red[ 2 ] ),
        .D3( tmds_red[ 3 ] ),
        .D4( tmds_red[ 4 ] ),
        .D5( tmds_red[ 5 ] ),
        .D6( tmds_red[ 6 ] ),
        .D7( tmds_red[ 7 ] ),
        .D8( tmds_red[ 8 ] ),
        .D9( tmds_red[ 9 ] ),
        .PCLK( clk_pixel ),
        .FCLK( clk_pixel_x5 ),
        .RESET(rst));

    OSER10 gwSer1( 
        .Q( serial_green ),
        .D0( tmds_green[ 0 ] ),
        .D1( tmds_green[ 1 ] ),
        .D2( tmds_green[ 2 ] ),
        .D3( tmds_green[ 3 ] ),
        .D4( tmds_green[ 4 ] ),
        .D5( tmds_green[ 5 ] ),
        .D6( tmds_green[ 6 ] ),
        .D7( tmds_green[ 7 ] ),
        .D8( tmds_green[ 8 ] ),
        .D9( tmds_green[ 9 ] ),
        .PCLK( clk_pixel ),
        .FCLK( clk_pixel_x5 ),
        .RESET(rst));

    OSER10 gwSer2( 
        .Q( serial_blue ),
        .D0( tmds_blue[ 0 ] ),
        .D1( tmds_blue[ 1 ] ),
        .D2( tmds_blue[ 2 ] ),
        .D3( tmds_blue[ 3 ] ),
        .D4( tmds_blue[ 4 ] ),
        .D5( tmds_blue[ 5 ] ),
        .D6( tmds_blue[ 6 ] ),
        .D7( tmds_blue[ 7 ] ),
        .D8( tmds_blue[ 8 ] ),
        .D9( tmds_blue[ 9 ] ),
        .PCLK( clk_pixel ),
        .FCLK( clk_pixel_x5 ),
        .RESET(rst));
        
    assign tmds_clock = clk_pixel;
`endif
endmodule
