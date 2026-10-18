
module CPU #(
    parameter INIT_FILE = "program.hex"
) (
    input  logic        clk,
    input  logic        reset,
    output logic [31:0] result
);

    // =====================================================
    // Internal signals
    // =====================================================

    // Program counter and next-PC path
    logic [31:0] pc_out;
    logic        pc_enable;
    logic        pc_source_sel;
    logic [31:0] selected_next_pc;
    logic [31:0] pc_input;
    logic        jalr_target_mask;

    // Instruction register and decoder
    logic        ir_write_enable;
    logic [31:0] instruction_out;

    logic [4:0]  rd;
    logic [4:0]  rs1;
    logic [4:0]  rs2;

    logic [3:0]  decoded_alu_op;
    logic [2:0]  imm_type;
    logic [31:0] immediate;

    logic        is_alu_reg;
    logic        is_alu_imm;
    logic [2:0]  load_type;
    logic [1:0]  store_type;
    logic [2:0]  branch_type;
    logic [1:0]  jump_type;
    logic        is_lui;
    logic        is_auipc;
    logic        writes_rd;
    logic        illegal;

    // Register file and operand registers
    logic [31:0] reg_data1;
    logic [31:0] reg_data2;

    logic [31:0] operand_a;
    logic [31:0] operand_b;
    logic        op_AB_reg_write_enable;

    // ALU datapath
    logic [1:0]  alu_a_sel;
    logic [1:0]  alu_b_sel;
    logic [3:0]  alu_ctrl;

    logic [31:0] alu_a;
    logic [31:0] alu_b;
    logic [31:0] alu_result;

    // The ALU's zero output is not used by this controller;
    // branch_control compares operands directly.
    /* verilator lint_off UNUSEDSIGNAL */
    logic        alu_zero;
    /* verilator lint_on UNUSEDSIGNAL */

    // ALU output register
    logic        alu_out_reg_write_enable;
    logic [31:0] alu_out_reg_out;

    // Memory address register
    logic        mar_write_enable;
    logic        mar_src_sel;
    logic [31:0] mar_in;
    logic [31:0] mar_out;

    // Shared memory
    logic        mem_addr_sel;
    logic        mem_write_enable;
    logic [1:0]  access_size;
    logic        load_unsigned;

    logic [31:0] memory_address;
    logic [31:0] memory_read_data;

    // Memory data register
    logic        mdr_write_enable;
    logic [31:0] mdr_out;

    // Branch control
    logic        branch_taken;

    // Register writeback
    logic        reg_write_enable;
    logic [1:0]  wb_sel;
    logic [31:0] writeback_data;

    //memory fpga implementation
    logic mem_read_enable;


    // =====================================================
    // 1. Program Counter
    // =====================================================

    pc pc_inst (
        .clk(clk),
        .reset(reset),
        .pc_enable(pc_enable),
        .next_pc(pc_input),
        .pc_out(pc_out)
    );


    // =====================================================
    // 2. Instruction Register
    // =====================================================

    instruction_reg ir_inst (
        .clk(clk),
        .reset(reset),
        .ir_write_enable(ir_write_enable),
        .instruction_in(memory_read_data),
        .instruction_out(instruction_out)
    );


    // =====================================================
    // 3. Decoder
    // =====================================================

    decoder decoder_inst (
        .instr(instruction_out),

        .rd(rd),
        .rs1(rs1),
        .rs2(rs2),

        .alu_op(decoded_alu_op),
        .imm_type(imm_type),

        .is_alu_reg(is_alu_reg),
        .is_alu_imm(is_alu_imm),
        .load_type(load_type),
        .store_type(store_type),
        .branch_type(branch_type),
        .jump_type(jump_type),
        .is_lui(is_lui),
        .is_auipc(is_auipc),

        .writes_rd(writes_rd),
        .illegal(illegal)
    );


    // =====================================================
    // 4. Immediate Generator
    // =====================================================

    imm_gen imm_gen_inst (
        .instr(instruction_out),
        .imm_type(imm_type),
        .imm(immediate)
    );


    // =====================================================
    // 5. Register File
    // =====================================================

    register_file regfile_inst (
        .clk(clk),

        .write_en(reg_write_enable),
        .write_addr(rd),
        .write_data(writeback_data),

        .read_addr1(rs1),
        .read_data1(reg_data1),

        .read_addr2(rs2),
        .read_data2(reg_data2)
    );


    // =====================================================
    // 6. Operand A/B Registers
    // =====================================================

    op_AB_reg operand_reg_inst (
        .clk(clk),
        .reset(reset),
        .op_AB_reg_write_enable(op_AB_reg_write_enable),

        .op_AB_reg_in1(reg_data1),
        .op_AB_reg_in2(reg_data2),

        .op_AB_reg_out1(operand_a),
        .op_AB_reg_out2(operand_b)
    );


    // =====================================================
    // 7. ALU Input Muxes
    // =====================================================

    alu_input_muxes alu_input_muxes_inst (
        .pc_out(pc_out),
        .mar_out(mar_out),
        .operand_a(operand_a),
        .operand_b(operand_b),
        .immediate(immediate),

        .alu_a_sel(alu_a_sel),
        .alu_b_sel(alu_b_sel),

        .alu_a(alu_a),
        .alu_b(alu_b)
    );


    // =====================================================
    // 8. ALU
    // =====================================================

    alu alu_inst (
        .a(alu_a),
        .b(alu_b),
        .alu_ctrl(alu_ctrl),
        .result(alu_result),
        .zero(alu_zero)
    );


    // =====================================================
    // 9. ALU Output Register
    // =====================================================

    alu_out_reg alu_out_reg_inst (
        .clk(clk),
        .reset(reset),
        .alu_out_reg_write_enable(alu_out_reg_write_enable),
        .alu_out_reg_in(alu_result),
        .alu_out_reg_out(alu_out_reg_out)
    );


    // =====================================================
    // 10. Memory Address Register
    // =====================================================

    // Select the source captured by MAR:
    // 0 = PC; 1 = ALU result.
    assign mar_in = mar_src_sel ? alu_result : pc_out;

    mar mar_inst (
        .clk(clk),
        .reset(reset),
        .mar_write_enable(mar_write_enable),
        .mar_in(mar_in),
        .mar_out(mar_out)
    );


    // =====================================================
    // 11. Memory Address Mux
    // =====================================================

    memory_address_mux memory_address_mux_inst (
        .pc_out(pc_out),
        .mar_out(mar_out),
        .memory_sel(mem_addr_sel),
        .memory_address(memory_address)
    );


    // =====================================================
    // 12. Shared Byte-Addressable Memory
    // =====================================================

    memory_subword #(
    .INIT_FILE(INIT_FILE)
    ) memory_inst (
        .clk(clk),
        .address(memory_address),
        .write_data_in(operand_b),
        .read_enable(mem_read_enable),
        .write_enable(mem_write_enable),
        .access_size(access_size),
        .load_unsigned(load_unsigned),
        .read_data_out(memory_read_data)
    );


    // =====================================================
    // 13. Memory Data Register
    // =====================================================

    mdr mdr_inst (
        .clk(clk),
        .reset(reset),
        .mdr_write_enable(mdr_write_enable),
        .mdr_in(memory_read_data),
        .mdr_out(mdr_out)
    );


    // =====================================================
    // 14. Branch Control
    // =====================================================

    branch_control branch_control_inst (
        .branch_type(branch_type),
        .operand_a(operand_a),
        .operand_b(operand_b),
        .branch_taken(branch_taken)
    );


    // =====================================================
    // 15. Next-PC Mux
    // =====================================================

    next_pc_mux next_pc_mux_inst (
        .alu_result(alu_result),
        .alu_out_reg_out(alu_out_reg_out),
        .pc_source_sel(pc_source_sel),
        .next_pc(selected_next_pc)
    );

    // JALR targets must have bit 0 cleared. For some reason i am not sure of.
    assign pc_input = jalr_target_mask
                    ? {selected_next_pc[31:1], 1'b0}
                    : selected_next_pc;


    // =====================================================
    // 16. Register Writeback Mux
    // =====================================================

    memory_writeback_mux writeback_mux_inst (
        .alu_out_reg_out(alu_out_reg_out),
        .mdr_out(mdr_out),
        .pc_out(pc_out),
        .immediate(immediate),
        .wb_sel(wb_sel),
        .writeback_data(writeback_data)
    );


    // =====================================================
    // 17. Multicycle Control FSM
    // =====================================================

    control_fsm control_fsm_inst (
        .clk(clk),
        .rst(reset),

        .is_alu_reg(is_alu_reg),
        .is_alu_imm(is_alu_imm),
        .load_type(load_type),
        .store_type(store_type),
        .branch_type(branch_type),
        .jump_type(jump_type),
        .is_lui(is_lui),
        .is_auipc(is_auipc),
        .writes_rd(writes_rd),
        .illegal(illegal),

        .branch_taken(branch_taken),
        .decoded_alu_op(decoded_alu_op),

        .pc_enable(pc_enable),
        .pc_source_sel(pc_source_sel),
        .jalr_target_mask(jalr_target_mask),
        .ir_write_enable(ir_write_enable),

        .mem_addr_sel(mem_addr_sel),
        .mar_write_enable(mar_write_enable),
        .mar_src_sel(mar_src_sel),
        .mem_write_enable(mem_write_enable),
        .access_size(access_size),
        .load_unsigned(load_unsigned),

        .alu_a_sel(alu_a_sel),
        .alu_b_sel(alu_b_sel),
        .alu_ctrl(alu_ctrl),

        .mdr_write_enable(mdr_write_enable),
        .alu_out_reg_write_enable(alu_out_reg_write_enable),
        .op_AB_reg_write_enable(op_AB_reg_write_enable),

        .reg_write_enable(reg_write_enable),
        .wb_sel(wb_sel),

        .mem_read_enable(mem_read_enable)
    );


    // =====================================================
    // 18. Debug Result Monitor
    // =====================================================

    // Records the last value written to a nonzero
    // general-purpose register.
    always_ff @(posedge clk) begin
        if (reset)
            result <= 32'd0;
        else if (reg_write_enable && (rd != 5'd0))
            result <= writeback_data;
    end

endmodule
