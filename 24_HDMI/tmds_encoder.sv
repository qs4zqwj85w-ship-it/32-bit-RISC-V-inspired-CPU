
module tmds_encoder (
    input  logic       clk_pixel,
    input  logic       rst,

    input  logic       video_active,
    input  logic [1:0] control,

    input  logic [7:0] data,

    output logic [9:0] tmds
);

integer first_ones_count;
integer second_ones_count;
integer signed local_disparity;

integer i;

logic [8:0] intermediate;
logic use_xnor;

logic signed [5:0] running_disparity;
logic signed [5:0] next_running_disparity;

logic [9:0] encoded_symbol;


// ============================================================
// Combinational TMDS encoding
// ============================================================

always_comb begin

    // Default assignments
    first_ones_count = 0;
    second_ones_count = 0;
    local_disparity = 0;

    use_xnor = 1'b0;
    intermediate = 9'b0;

    encoded_symbol = 10'b0;
    next_running_disparity = running_disparity;

    // --------------------------------------------------------
    // Stage 1: Transition minimization
    // --------------------------------------------------------

    first_ones_count = $countones(data);

    use_xnor = (first_ones_count > 4) ||
               ((first_ones_count == 4) && (data[0] == 1'b0));

    intermediate[0] = data[0];

    for (i = 1; i < 8; i = i + 1) begin
        if (use_xnor)
            intermediate[i] = ~(intermediate[i-1] ^ data[i]);
        else
            intermediate[i] = intermediate[i-1] ^ data[i];
    end

    intermediate[8] = ~use_xnor;

    // --------------------------------------------------------
    // Stage 2: DC balancing
    // --------------------------------------------------------

    if (video_active) begin

        second_ones_count = $countones(intermediate[7:0]);

        local_disparity = 2 * second_ones_count - 8;

        // Case A: Running disparity or local disparity is zero
        if ((running_disparity == 0) ||
            (local_disparity == 0)) begin

            if (intermediate[8]) begin
                encoded_symbol = {2'b01, intermediate[7:0]};

                next_running_disparity =
                    running_disparity + local_disparity;
            end
            else begin
                encoded_symbol = {2'b10, ~intermediate[7:0]};

                next_running_disparity =
                    running_disparity - local_disparity;
            end

        end

        // Case B: Both disparities have the same sign
        else if (((running_disparity > 0) &&
                  (local_disparity > 0)) ||
                 ((running_disparity < 0) &&
                  (local_disparity < 0))) begin

            encoded_symbol = {1'b1, intermediate[8],
                              ~intermediate[7:0]};

            next_running_disparity =
                running_disparity - local_disparity +
                (intermediate[8] ? 2 : 0);

        end

        // Case C: Disparities have opposite signs
        else begin

            encoded_symbol = {1'b0, intermediate[8],
                              intermediate[7:0]};

            next_running_disparity =
                running_disparity + local_disparity -
                (intermediate[8] ? 0 : 2);

        end

    end

    // --------------------------------------------------------
    // Blanking period: Control symbols
    // --------------------------------------------------------

// these arbitrary bits are hdmi protocal
    else begin

        case (control)
            2'b00: encoded_symbol = 10'b1101010100;
            2'b01: encoded_symbol = 10'b0010101011;
            2'b10: encoded_symbol = 10'b0101010100;
            2'b11: encoded_symbol = 10'b1010101011;
        endcase

        // Reset running disparity during control periods
        next_running_disparity = 0;

    end

end


// ============================================================
// Sequential logic: Register output and running disparity
// ============================================================

always_ff @(posedge clk_pixel) begin

    if (rst) begin
        running_disparity <= 0;
        tmds <= 10'b1101010100;
    end
    else begin
        running_disparity <= next_running_disparity;
        tmds <= encoded_symbol;
    end

end

endmodule
