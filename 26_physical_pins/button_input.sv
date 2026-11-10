module button_input #(
    parameter integer DEBOUNCE_CYCLES = 270_000
) (
    input  logic clk,
    input  logic reset,
    input  logic button_n,

    output logic button_pressed
);

logic sync_ff1;
logic sync_ff2;
logic debounce_input;

logic button_state;
logic [18:0] debounce_counter;

always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        sync_ff1 <= 1'b1;
        sync_ff2 <= 1'b1;
    end else begin
        sync_ff1 <= button_n;
        sync_ff2 <= sync_ff1;
    end
end

assign debounce_input = ~sync_ff2;

always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        button_state <= 1'b0;
        debounce_counter <= 1'b0;
    end
    else if (debounce_input == button_state) begin
        debounce_counter <= 0;
    end
    else if (debounce_counter == DEBOUNCE_CYCLES - 1) begin
        button_state <= debounce_input;
        debounce_counter <= 0;
    end
    else begin
        debounce_counter <= debounce_counter + 1;
    end

end

assign button_pressed = button_state;

endmodule
