module memory_address_mux (
    input logic [31:0] pc_out,
    input logic [31:0] mar_out,
    input logic  memory_sel,
    output logic [31:0] memory_address
);

    always_comb begin
        if (memory_sel)
            memory_address = mar_out;
        else
            memory_address = pc_out;
    end

endmodule
