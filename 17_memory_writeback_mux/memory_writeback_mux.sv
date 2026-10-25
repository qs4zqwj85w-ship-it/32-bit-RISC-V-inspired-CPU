module memory_writeback_mux (
    input  logic [31:0] alu_out_reg_out,
    input  logic [31:0] mdr_out,
    input  logic [31:0] pc_out,
    input  logic [31:0] immediate,
    input  logic [31:0] m_result,
    input  logic [2:0]  wb_sel,

    output logic [31:0] writeback_data
);

    always_comb begin
        case (wb_sel)
            3'b000:  writeback_data = alu_out_reg_out;
            3'b001:  writeback_data = mdr_out;
            3'b010:  writeback_data = pc_out;
            3'b011:  writeback_data = immediate;
            3'b100:  writeback_data = m_result;
            default: writeback_data = 32'b0;
        endcase
    end

endmodule