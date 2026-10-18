//UART Translation to allow C output through macbook interface

module uart_transmitter #(
    parameter integer CLK_HZ = 27_000_000,
    parameter integer BAUD   = 115_200
) (
    input  logic       clk,
    input  logic       rst,
    input  logic [7:0] data_in,
    input  logic       start,
    output logic       tx,
    output logic       busy
);

    localparam integer CLKS_PER_BIT = CLK_HZ / BAUD;
    localparam integer COUNT_WIDTH  = $clog2(CLKS_PER_BIT);

    typedef enum logic [1:0] {
        IDLE,
        START_BIT,
        DATA_BITS,
        STOP_BIT
    } state_t;

    state_t state;

    logic [COUNT_WIDTH-1:0] clk_count;
    logic [2:0] bit_index;
    logic [7:0] data_reg;

    assign busy = (state != IDLE);

    always_ff @(posedge clk) begin
        if (rst) begin
            state     <= IDLE;
            tx        <= 1'b1;
            clk_count <= '0;
            bit_index <= '0;
            data_reg  <= '0;
        end else begin
            case (state)

                IDLE: begin
                    tx        <= 1'b1;
                    clk_count <= '0;

                    if (start) begin
                        data_reg  <= data_in;
                        tx        <= 1'b0;
                        bit_index <= 3'd0;
                        state     <= START_BIT;
                    end
                end

                START_BIT: begin
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= '0;
                        tx        <= data_reg[0];
                        bit_index <= 3'd0;
                        state     <= DATA_BITS;
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                DATA_BITS: begin
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= '0;

                        if (bit_index == 3'd7) begin
                            tx    <= 1'b1;
                            state <= STOP_BIT;
                        end else begin
                            bit_index <= bit_index + 1'b1;
                            tx <= data_reg[bit_index + 1'b1];
                        end
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                STOP_BIT: begin
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= '0;
                        tx        <= 1'b1;
                        state     <= IDLE;
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                default: begin
                    state     <= IDLE;
                    tx        <= 1'b1;
                    clk_count <= '0;
                end

            endcase
        end
    end

endmodule