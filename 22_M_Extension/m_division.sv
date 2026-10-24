module m_division (
    input  logic        clk,
    input  logic        reset_n,
    input  logic        start,
    input  logic [31:0] dividend,
    input  logic [31:0] divisor,
    input  logic [2:0]  operation,

    output logic        busy,
    output logic        ready,
    output logic        done,
    output logic [31:0] result
);

    // RISC-V M-extension funct3 values
    localparam logic [2:0] OP_DIV  = 3'b100;
    localparam logic [2:0] OP_DIVU = 3'b101;
    localparam logic [2:0] OP_REM  = 3'b110;
    localparam logic [2:0] OP_REMU = 3'b111;

    // Controller states
    typedef enum logic [1:0] {
        IDLE,
        CALC,
        OUT_FIX,
        DIV_ZERO
    } state_t;

    state_t state;

    // Iterative divider registers
    logic [5:0]  bit_ctr;
    logic [63:0] rem_div_reg;
    logic [31:0] divisor_reg;

    // Operation and sign tracking
    logic [2:0] operation_reg;
    logic       q_negative;
    logic       r_negative;

    // Arithmetic
    logic [32:0] sub_result;

    wire [32:0] trial_remainder = {
        rem_div_reg[63:32],
        rem_div_reg[31]
    };

    assign sub_result = trial_remainder - {1'b0, divisor_reg};

    // Handshake signals
    assign busy  = (state != IDLE);
    assign ready = (state == IDLE);

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state         <= IDLE;
            bit_ctr       <= '0;
            rem_div_reg   <= '0;
            divisor_reg   <= '0;
            operation_reg <= '0;
            q_negative    <= 1'b0;
            r_negative    <= 1'b0;
            done          <= 1'b0;
        end else begin
            // Completion is a one-cycle pulse
            done <= 1'b0;

            case (state)

                // Accept a new operation
                IDLE: begin
                    if (start) begin
                        operation_reg <= operation;

                        if (divisor == 32'b0) begin
                            // Quotient = -1; remainder = original dividend
                            rem_div_reg <= {dividend, 32'hFFFF_FFFF};

                            divisor_reg <= '0;
                            q_negative  <= 1'b0;
                            r_negative  <= 1'b0;

                            state <= DIV_ZERO;
                        end else begin
                            // Initialize normal division
                            bit_ctr <= 6'd32;

                            rem_div_reg[63:32] <= 32'b0;

                            if (operation == OP_DIV ||
                                operation == OP_REM) begin

                                q_negative <=
                                    dividend[31] ^ divisor[31];

                                r_negative <= dividend[31];

                                rem_div_reg[31:0] <=
                                    dividend[31] ? -dividend : dividend;

                                divisor_reg <=
                                    divisor[31] ? -divisor : divisor;

                            end else begin
                                q_negative <= 1'b0;
                                r_negative <= 1'b0;

                                rem_div_reg[31:0] <= dividend;
                                divisor_reg       <= divisor;
                            end

                            state <= CALC;
                        end
                    end
                end

                // One restoring-division iteration per cycle
                CALC: begin
                    bit_ctr <= bit_ctr - 1'b1;

                    if (trial_remainder >= {1'b0, divisor_reg}) begin
                        // Subtraction succeeds; append quotient bit 1
                        rem_div_reg <= {
                            sub_result[31:0],
                            rem_div_reg[30:0],
                            1'b1
                        };
                    end else begin
                        // Subtraction fails; preserve trial remainder
                        // and append quotient bit 0
                        rem_div_reg <= {
                            rem_div_reg[62:0],
                            1'b0
                        };
                    end

                    if (bit_ctr == 6'd1) begin
                        state <= OUT_FIX;
                    end
                end

                // Restore the signs of the final values
                OUT_FIX: begin
                    if (q_negative) begin
                        rem_div_reg[31:0] <= -rem_div_reg[31:0];
                    end

                    if (r_negative) begin
                        rem_div_reg[63:32] <= -rem_div_reg[63:32];
                    end

                    done  <= 1'b1;
                    state <= IDLE;
                end

                // Division-by-zero results are already stored
                DIV_ZERO: begin
                    done  <= 1'b1;
                    state <= IDLE;
                end

                default: begin
                    state <= IDLE;
                end

            endcase
        end
    end

    // Extract quotient and remainder
    logic [31:0] raw_quotient;
    logic [31:0] raw_remainder;

    assign raw_quotient  = rem_div_reg[31:0];
    assign raw_remainder = rem_div_reg[63:32];

    // Select the requested result
    always_comb begin
        case (operation_reg)
            OP_DIV,
            OP_DIVU: result = raw_quotient;

            OP_REM,
            OP_REMU: result = raw_remainder;

            default: result = 32'b0;
        endcase
    end

endmodule
