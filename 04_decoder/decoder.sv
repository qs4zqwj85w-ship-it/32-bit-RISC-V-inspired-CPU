module decoder (
    input  logic [31:0] instr,

    // Register addresses
    output logic [4:0] rd,
    output logic [4:0] rs1,
    output logic [4:0] rs2,

    // Decoded operation and immediate format
    output logic [3:0] alu_op,
    output logic [2:0] imm_type,

    // Instruction classification
    output logic is_alu_reg,
    output logic is_alu_imm,
    output logic [2:0] load_type,
    output logic [1:0] store_type,
    output logic [2:0] branch_type,
    output logic [1:0] jump_type,
    output logic is_lui,
    output logic is_auipc,

    // Additional decode information
    output logic writes_rd,
    output logic illegal,
    //ENVIRONMENTAL instructions
    output logic is_ecall,
    output logic is_ebreak,
    // CSR instructions
    output logic is_csr,
    output logic is_mret
);

    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;

    // Extract instruction fields
    assign opcode = instr[6:0];
    assign funct3 = instr[14:12];
    assign funct7 = instr[31:25];

    assign rd  = instr[11:7];
    assign rs1 = instr[19:15];
    assign rs2 = instr[24:20];

    always_comb begin
        // Default values
        alu_op     = 4'd0;
        imm_type   = 3'd0;

        is_alu_reg = 1'b0;
        is_alu_imm = 1'b0;
        load_type    = 3'b000;
        store_type   = 2'b00;
        branch_type = 3'b000;
        jump_type  = 2'd0;
        is_lui     = 1'b0;
        is_auipc   = 1'b0;

        writes_rd  = 1'b0;
        illegal    = 1'b1;
        is_ecall  = 1'b0;
        is_ebreak = 1'b0;

        is_csr = 1'b0;
        is_mret = 1'b0;

        case (opcode)

            // R-type instructions
            7'b0110011: begin
                is_alu_reg = 1'b1;

                // Decode funct7 and funct3 together
                case ({funct7, funct3})
                    {7'b0000000, 3'b000}: begin alu_op = 4'd0; illegal = 1'b0; end // ADD
                    {7'b0100000, 3'b000}: begin alu_op = 4'd1; illegal = 1'b0; end // SUB
                    {7'b0000000, 3'b100}: begin alu_op = 4'd2; illegal = 1'b0; end // XOR
                    {7'b0000000, 3'b110}: begin alu_op = 4'd3; illegal = 1'b0; end // OR
                    {7'b0000000, 3'b111}: begin alu_op = 4'd4; illegal = 1'b0; end // AND
                    {7'b0000000, 3'b001}: begin alu_op = 4'd5; illegal = 1'b0; end // SLL
                    {7'b0000000, 3'b101}: begin alu_op = 4'd6; illegal = 1'b0; end // SRL
                    {7'b0100000, 3'b101}: begin alu_op = 4'd7; illegal = 1'b0; end // SRA
                    {7'b0000000, 3'b010}: begin alu_op = 4'd8; illegal = 1'b0; end // SLT
                    {7'b0000000, 3'b011}: begin alu_op = 4'd9; illegal = 1'b0; end // SLTU

                    default: illegal = 1'b1;
                endcase

                writes_rd = !illegal;
            end

            // I-type ALU instructions (immediate)
            7'b0010011: begin
                is_alu_imm = 1'b1;
                imm_type   = 3'd0; // I-type

                case (funct3)
                    3'b000: begin alu_op = 4'd0; illegal = 1'b0; end // ADDI

                    3'b001: begin // SLLI
                        if (funct7 == 7'b0000000) begin
                            alu_op = 4'd5;
                            illegal = 1'b0;
                        end
                    end

                    3'b010: begin alu_op = 4'd8; illegal = 1'b0; end // SLTI
                    3'b011: begin alu_op = 4'd9; illegal = 1'b0; end // SLTIU
                    3'b100: begin alu_op = 4'd2; illegal = 1'b0; end // XORI

                    3'b101: begin // SRLI / SRAI
                        case (funct7)
                            7'b0000000: begin alu_op = 4'd6; illegal = 1'b0; end // SRLI
                            7'b0100000: begin alu_op = 4'd7; illegal = 1'b0; end // SRAI
                            default: illegal = 1'b1;
                        endcase
                    end

                    3'b110: begin alu_op = 4'd3; illegal = 1'b0; end // ORI
                    3'b111: begin alu_op = 4'd4; illegal = 1'b0; end // ANDI

                    default: illegal = 1'b1;
                endcase

                writes_rd = !illegal;
            end

            // Load instructions
            7'b0000011: begin
                imm_type = 3'd0; // I-type
                alu_op   = 4'd0; // ADD for effective address

                case (funct3)
                    3'b000: load_type = 3'b001; // LB
                    3'b001: load_type = 3'b010; // LH
                    3'b010: load_type = 3'b011; // LW
                    3'b100: load_type = 3'b100; // LBU
                    3'b101: load_type = 3'b101; // LHU
                    default: load_type = 3'b000;
                endcase

                if (load_type != 3'b000) begin
                    writes_rd = 1'b1;
                    illegal   = 1'b0;
                end
            end

            // Store instructions
            7'b0100011: begin
                imm_type = 3'd1; // S-type
                case (funct3)
                    3'b000: store_type = 2'b01; // SB
                    3'b001: store_type = 2'b10; // SH
                    3'b010: store_type = 2'b11; // SW
                    default: store_type = 2'b00;
                endcase

                if (store_type != 2'b00) begin
                    illegal = 1'b0;
                end else begin
                    illegal = 1'b1;
                end
            end

            // Branch instructions
            7'b1100011: begin
                imm_type = 3'd2; // B-type
                case (funct3)
                    3'b000: branch_type = 3'd1; // BEQ
                    3'b001: branch_type = 3'd2; // BNE
                    3'b100: branch_type = 3'd3; // BLT
                    3'b101: branch_type = 3'd4; // BGE
                    3'b110: branch_type = 3'd5; // BLTU
                    3'b111: branch_type = 3'd6; // BGEU
                    default: branch_type = 3'd0;
                endcase

                illegal = (branch_type == 3'd0);
            end

            // JAL
            7'b1101111: begin
                jump_type = 2'b01;
                imm_type  = 3'd4; // J-type immediate
                writes_rd = 1'b1;
                illegal   = 1'b0;
            end

            // JALR
            7'b1100111: begin
                if (funct3 == 3'b000) begin
                    jump_type = 2'b10;
                    writes_rd = 1'b1;
                    illegal   = 1'b0;
                end
            end

            // LUI
            7'b0110111: begin
                is_lui   = 1'b1;
                imm_type = 3'd3; // U-type
                writes_rd = 1'b1;
                illegal   = 1'b0;
            end

            // AUIPC
            7'b0010111: begin
                is_auipc = 1'b1;
                imm_type = 3'd3; // U-type
                alu_op   = 4'd0; // ADD
                writes_rd = 1'b1;
                illegal   = 1'b0;
            end
            
            //Environmental instructions (ECALL, EBREAK, CSR)
            7'b1110011: begin
                case (instr)
                    32'h0000_0073: begin
                        // ECALL
                        is_ecall = 1'b1;
                        illegal  = 1'b0;
                    end

                    32'h0010_0073: begin
                        // EBREAK
                        is_ebreak = 1'b1;
                        illegal   = 1'b0;
                    end

                    32'h3020_0073: begin
                        // MRET
                        is_mret = 1'b1;
                        illegal = 1'b0;
                    end

                    default: begin
                        case (funct3)
                            3'b001, // CSRRW
                            3'b010, // CSRRS
                            3'b011, // CSRRC
                            3'b101, // CSRRWI
                            3'b110, // CSRRSI
                            3'b111: begin // CSRRCI
                                is_csr  = 1'b1;
                                writes_rd = 1'b1;
                                illegal = 1'b0;
                            end

                            default: begin
                                // Unsupported SYSTEM instruction.
                                illegal = 1'b1;
                            end
                        endcase
                    end
                endcase
            end

            // MISC-MEM: FENCE
            7'b0001111: begin
                // Base FENCE: in-order implementation, so no extra
                // ordering operation is needed. Reject reserved FM values.
                if ((funct3 == 3'b000) &&
                    (instr[31:28] == 4'b0000)) begin
                    illegal = 1'b0;
                end else begin
                    illegal = 1'b1;
                end
            end     

            default: begin
                // Keep defaults: unsupported opcode, this might be a lil too hard, might do it later :|
            end

        endcase
    end

endmodule
