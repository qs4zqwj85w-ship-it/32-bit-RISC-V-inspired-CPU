module next_pc_mux (
    input logic [31:0] alu_result,
    input logic [31:0] alu_out_reg_out,
    input logic  pc_source_sel,
    output logic [31:0] next_pc
);

    always_comb begin
        if (pc_source_sel)
            next_pc = alu_out_reg_out;
        else
            next_pc = alu_result;
    end

endmodule
