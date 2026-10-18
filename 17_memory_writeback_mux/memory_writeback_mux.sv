module memory_writeback_mux (
    input  logic [31:0] alu_out_reg_out,
    input  logic [31:0] mdr_out,
    input  logic [31:0] pc_out,
    input  logic [31:0] immediate,
    input  logic [1:0]  wb_sel,

    output logic [31:0] writeback_data
);

    always_comb begin
        case (wb_sel)
            2'b00:   writeback_data = alu_out_reg_out;
            2'b01:   writeback_data = mdr_out;
            2'b10:   writeback_data = pc_out;
            2'b11:   writeback_data = immediate;
            default: writeback_data = 32'b0;
        endcase
    end

endmodule
