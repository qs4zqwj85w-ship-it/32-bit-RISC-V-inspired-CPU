
module CPU #(
    parameter INIT_FILE = "program.hex",
    parameter logic [31:0] RESET_MTVEC = 32'h0000_0100
) (
    input  logic        clk,
    input  logic        reset,

    output logic [31:0] result,
    output logic        uart_wr_en,
    output logic [7:0]  uart_wr_data,
    input  logic        uart_busy,

// SDRAM expansion requires additional input and output since they are "leaving and entering the CPU and not just logic"
    input  logic        clk_sdram,
    inout  wire  [31:0] SDRAM_DQ,
    output wire  [10:0] SDRAM_A,
    output wire  [1:0]  SDRAM_BA,
    output wire         SDRAM_nCS,
    output wire         SDRAM_nWE,
    output wire         SDRAM_nRAS,
    output wire         SDRAM_nCAS,
    output wire         SDRAM_CLK,
    output wire         SDRAM_CKE,
    output wire  [3:0]  SDRAM_DQM
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

    //Environmental command
    logic is_ecall;
    logic is_ebreak;
    logic trap_enter;

    /* verilator lint_off UNUSEDSIGNAL */
    logic [31:0] mcause;
    /* verilator lint_on UNUSEDSIGNAL */

    // Register writeback
    logic        reg_write_enable;
    logic [2:0] wb_sel;
    logic [31:0] writeback_data;


    //memory fpga implementation
    logic mem_read_enable;

    // ---- Memory-mapped I/O ----
    localparam logic [31:0] UART_DATA_ADDR = 32'h1000_0000;
    localparam logic [31:0] UART_STAT_ADDR = 32'h1000_0004;

    logic        mmio_sel;
    logic [31:0] ram_read_data;
    logic        stat_sel_q = 1'b0;

    // CSR execution logic
    logic        is_csr;
    logic        csr_execute;

    logic [11:0] csr_addr;
    logic        csr_addr_valid;
    logic        csr_write_requested;
    logic        csr_write_enable_int;

    logic [31:0] csr_read_data;
    logic [31:0] csr_write_data;
    logic [31:0] csr_source_value;
    logic [31:0] csr_old_value;

    logic [31:0] normal_writeback_data;
    logic        instruction_illegal;

    logic is_mret;
    logic mret_execute; 

    logic [31:0] mtvec;
    logic [31:0] mepc;
    logic [31:0] trap_cause;
    logic [31:0] trap_value;
    logic csr_addr_read_only;

    // M-extension decoder outputs
    logic        is_mult;
    logic        is_div;
    logic [2:0]  m_type;

    // M-extension results
    logic [31:0] mult_result;
    logic [31:0] div_result;
    logic [31:0] m_result;

    // Divider handshake
    logic        div_start;
    logic        div_done;
    logic        div_ready;

    //SDRAM expansion
    logic sdram_address_sel;
    logic sdram_req;
    logic [31:0] sdram_rdata;
    logic bram_read_enable;
    logic bram_write_enable;
    logic sdram_req_ready;
    logic sdram_done;
    
    assign sdram_address_sel = (memory_address >= 32'h0000_1000) && (memory_address <= 32'h0080_0FFF);
    assign mmio_sel         = (memory_address[31:28] == 4'h1);
    assign bram_write_enable = mem_write_enable && !mmio_sel && !sdram_address_sel;
    assign bram_read_enable = mem_read_enable && !mmio_sel && !sdram_address_sel;
    assign uart_wr_en       = mem_write_enable && (memory_address == UART_DATA_ADDR);
    assign uart_wr_data     = operand_b[7:0];

    always_ff @(posedge clk)
        if (mem_read_enable)
            stat_sel_q <= (memory_address == UART_STAT_ADDR);

    always_comb begin
        if (stat_sel_q)
            memory_read_data = {31'b0, uart_busy};
        else if (sdram_address_sel)
            memory_read_data = sdram_rdata;
        else
            memory_read_data = ram_read_data;
    end


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

        .is_ecall(is_ecall),
        .is_ebreak(is_ebreak),

        .writes_rd(writes_rd),
        .illegal(illegal),
        .is_csr(is_csr),
        .is_mret(is_mret),

        .is_mult(is_mult),
        .is_div(is_div),
        .m_type(m_type)
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
        .read_enable(bram_read_enable),
        .write_enable(bram_write_enable),
        .access_size(access_size),
        .load_unsigned(load_unsigned),
        .read_data_out(ram_read_data)
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

    // JALR targets must have bit 0 cleared. For some reason i am not sure of.
    // Trap redirection takes priority over normal PC selection and JALR.

    next_pc_mux next_pc_mux_inst (
        .alu_result(alu_result),
        .alu_out_reg_out(alu_out_reg_out),
        .pc_source_sel(pc_source_sel),
        .next_pc(selected_next_pc)
    );

    assign pc_input = trap_enter
                    ? mtvec
                    : mret_execute
                        ? mepc
                        : jalr_target_mask
                            ? {selected_next_pc[31:1], 1'b0}
                            : selected_next_pc;

   // =====================================================
    // 16. Register Writeback Mux
    // =====================================================

    assign writeback_data =
        is_csr ? csr_old_value : normal_writeback_data;

    // Select the result from the active M-extension unit
    assign m_result = is_div ? div_result : mult_result;

    memory_writeback_mux writeback_mux_inst (
        .alu_out_reg_out (alu_out_reg_out),
        .mdr_out         (mdr_out),
        .pc_out          (pc_out),
        .immediate       (immediate),
        .m_result        (m_result),
        .wb_sel          (wb_sel),
        .writeback_data  (normal_writeback_data)
    );


    // =====================================================
    // 17. Multicycle Control FSM
    // =====================================================

    // Illegal instruction encoding or invalid CSR access.
    assign instruction_illegal =
        illegal ||
        (is_csr &&
            (!csr_addr_valid ||
            (csr_write_requested && csr_addr_read_only)));

    assign csr_write_enable_int =
        csr_execute &&
        csr_write_requested &&
        csr_addr_valid &&
        !csr_addr_read_only;

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
        .illegal(instruction_illegal),

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

        .is_ecall(is_ecall),
        .is_ebreak(is_ebreak),
        .trap_enter(trap_enter),

        .mdr_write_enable(mdr_write_enable),
        .alu_out_reg_write_enable(alu_out_reg_write_enable),
        .op_AB_reg_write_enable(op_AB_reg_write_enable),

        .reg_write_enable(reg_write_enable),
        .wb_sel(wb_sel),

        .mem_read_enable(mem_read_enable),

        .is_csr(is_csr),
        .csr_execute(csr_execute),

        .is_mret(is_mret),
        .mret_execute(mret_execute),

        .is_mult(is_mult),
        .is_div(is_div),
        .div_done(div_done),
        .div_ready(div_ready),
        .div_start(div_start),

        .sdram_address_sel(sdram_address_sel),
        .sdram_req_ready(sdram_req_ready),
        .sdram_done(sdram_done)
    );

    // =====================================================
    // 18. CSR instance
    // =====================================================

    // Select the exception cause.
    assign trap_cause =
        instruction_illegal ? 32'd2  :  // Illegal instruction
        is_ecall           ? 32'd11 :  // ECALL from machine mode
        is_ebreak           ? 32'd3  :  // Breakpoint
                            32'd0;

    // Save the instruction encoding for illegal-instruction traps.
    // For ECALL and EBREAK, mtval will be zero.
    assign trap_value =
        instruction_illegal ? instruction_out : 32'd0;
    

    machine_csrs #(
        .RESET_MTVEC(RESET_MTVEC)
    ) csr_bank_inst (
        .clk(clk),
        .reset(reset),

        .csr_addr(csr_addr),
        .csr_write_enable(csr_write_enable_int),
        .csr_write_data(csr_write_data),
        .csr_read_data(csr_read_data),
        .csr_addr_valid(csr_addr_valid),

        .trap_enter(trap_enter),
        .trap_pc(mar_out),
        .trap_cause(trap_cause),
        .trap_value(trap_value),

        .mret_execute(mret_execute),

        .mtvec_out(mtvec),
        .mepc_out(mepc),
        .csr_addr_read_only(csr_addr_read_only)
    );

    // =====================================================
    // 19. M-extension divider
    // =====================================================

    m_division m_division_inst (
        .clk       (clk),
        .reset_n   (~reset),       // CPU reset is active-high
        .start     (div_start),
        .dividend  (operand_a),
        .divisor   (operand_b),
        .operation (m_type),

        .busy      (),
        .ready     (div_ready),
        .done      (div_done),
        .result    (div_result)
    );

    // =====================================================
    // 20. M-extension multiplier
    // =====================================================

    m_extension m_extension_inst (
        .operand_a (operand_a),
        .operand_b (operand_b),
        .operation (m_type),
        .result    (mult_result)
    );

    // =====================================================
    // 21. SDRAM expansion
    // =====================================================

    assign sdram_req = sdram_address_sel && (mem_read_enable || mem_write_enable);

    sdram_adapter #(
        .FREQ_HZ   (27_000_000),
        .SDRAM_BASE(32'h0000_1000)
    ) sdram_adapter_inst (
        // Clocks and reset
        .clk          (clk),
        .clk_sdram    (clk_sdram),
        .reset        (reset),

        // CPU-side interface
        .req          (sdram_req),
        .req_ready    (sdram_req_ready),
        .we           (mem_write_enable),
        .addr         (memory_address),
        .wdata        (operand_b),
        .access_size  (access_size),
        .load_unsigned(load_unsigned),
        .rdata        (sdram_rdata),
        .done         (sdram_done),

        // Physical SDRAM pins
        .SDRAM_DQ     (SDRAM_DQ),
        .SDRAM_A      (SDRAM_A),
        .SDRAM_BA     (SDRAM_BA),
        .SDRAM_nCS    (SDRAM_nCS),
        .SDRAM_nWE    (SDRAM_nWE),
        .SDRAM_nRAS   (SDRAM_nRAS),
        .SDRAM_nCAS   (SDRAM_nCAS),
        .SDRAM_CLK    (SDRAM_CLK),
        .SDRAM_CKE    (SDRAM_CKE),
        .SDRAM_DQM    (SDRAM_DQM)
    );

    // =====================================================
    // Debug Result Monitor
    // =====================================================

    // Records the last value written to a nonzero
    // general-purpose register.
    always_ff @(posedge clk) begin
        if (reset)
            result <= 32'd0;
        else if (reg_write_enable && (rd != 5'd0))
            result <= writeback_data;
    end

    always_comb begin
        // funct3[2] distinguishes immediate CSR instructions.
        // Immediate source is a zero-extended zimm[4:0].
        if (instruction_out[14]) begin
            csr_source_value = {
                27'd0, instruction_out[19:15]
            };
        end
        else begin
            csr_source_value = operand_a;
        end

        // Default: preserve the old CSR value.
        csr_write_data      = csr_read_data;
        csr_write_requested = 1'b0;

        case (instruction_out[14:12])
            3'b001: begin // CSRRW
                csr_write_data      = csr_source_value;
                csr_write_requested = 1'b1;
            end

            3'b010: begin // CSRRS
                csr_write_data = csr_read_data | csr_source_value;

                // Suppress writes only when encoded rs1 = x0.
                csr_write_requested =
                    (instruction_out[19:15] != 5'd0);
            end

            3'b011: begin // CSRRC
                csr_write_data =
                    csr_read_data & ~csr_source_value;

                csr_write_requested =
                    (instruction_out[19:15] != 5'd0);
            end

            3'b101: begin // CSRRWI
                csr_write_data      = csr_source_value;
                csr_write_requested = 1'b1;
            end

            3'b110: begin // CSRRSI
                csr_write_data = csr_read_data | csr_source_value;
                csr_write_requested =
                    (instruction_out[19:15] != 5'd0);
            end

            3'b111: begin // CSRRCI
                csr_write_data =
                    csr_read_data & ~csr_source_value;

                csr_write_requested =
                    (instruction_out[19:15] != 5'd0);
            end

            default: begin
                csr_write_data      = csr_read_data;
                csr_write_requested = 1'b0;
            end
        endcase
    end

    assign csr_addr = instruction_out[31:20];

    always_ff @(posedge clk) begin
        if (reset)
            csr_old_value <= 32'd0;
        else if (csr_execute && csr_addr_valid)
            csr_old_value <= csr_read_data;
    end



endmodule
