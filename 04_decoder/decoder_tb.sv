// Note, this decoder was produced by AI, I specified my testing requirements
// but code was generated as it was too repetitive to write manually.

module decoder_tb;

    logic [31:0] instr;

    logic [4:0] rd, rs1, rs2;
    logic [3:0] alu_op;
    logic [2:0] imm_type;
    logic is_alu_reg, is_alu_imm;
    logic [2:0] load_type;
    logic [1:0] store_type;
    logic [2:0] branch_type;
    logic [1:0] jump_type;
    logic is_lui, is_auipc;
    logic writes_rd, illegal;

    decoder dut (
        .instr(instr),
        .rd(rd),
        .rs1(rs1),
        .rs2(rs2),
        .alu_op(alu_op),
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

    // Control-vector layout:
    // {alu_op, imm_type, load_type, store_type, branch_type,
    //  jump_type, is_alu_reg, is_alu_imm, is_lui, is_auipc,
    //  writes_rd, illegal}

    task automatic check_decode(
        input string test_name,
        input logic [31:0] instruction,
        input logic [22:0] expected_control
    );
        logic [22:0] actual_control;

        begin
            instr = instruction;
            #1;

            actual_control = {
                alu_op, imm_type, load_type, store_type,
                branch_type, jump_type,
                is_alu_reg, is_alu_imm, is_lui, is_auipc,
                writes_rd, illegal
            };

            if (actual_control !== expected_control)
                $fatal(1,
                    "FAIL: %s | instr=%h expected=%h got=%h",
                    test_name, instruction,
                    expected_control, actual_control);

            $display("PASS: %s", test_name);
        end
    endtask

    initial begin
        $display("Starting decoder tests...");

        instr = 32'd0;

        // --------------------------------------------------
        // R-type: all 10 ALU operations
        // --------------------------------------------------

        check_decode("R-type ADD",
            {7'b0000000,5'd2,5'd1,3'b000,5'd3,7'b0110011},
            {4'd0,3'd0,3'd0,2'd0,3'd0,2'd0,
             1'b1,1'b0,1'b0,1'b0,1'b1,1'b0});

        // Verify extraction of rd=x3, rs1=x1, rs2=x2
        if ({rd,rs1,rs2} !== {5'd3,5'd1,5'd2})
            $fatal(1, "FAIL: register field extraction");

        check_decode("R-type SUB",
            {7'b0100000,5'd2,5'd1,3'b000,5'd3,7'b0110011},
            {4'd1,3'd0,3'd0,2'd0,3'd0,2'd0,
             1'b1,1'b0,1'b0,1'b0,1'b1,1'b0});

        check_decode("R-type XOR",
            {7'b0000000,5'd2,5'd1,3'b100,5'd3,7'b0110011},
            {4'd2,3'd0,3'd0,2'd0,3'd0,2'd0,
             1'b1,1'b0,1'b0,1'b0,1'b1,1'b0});

        check_decode("R-type OR",
            {7'b0000000,5'd2,5'd1,3'b110,5'd3,7'b0110011},
            {4'd3,3'd0,3'd0,2'd0,3'd0,2'd0,
             1'b1,1'b0,1'b0,1'b0,1'b1,1'b0});

        check_decode("R-type AND",
            {7'b0000000,5'd2,5'd1,3'b111,5'd3,7'b0110011},
            {4'd4,3'd0,3'd0,2'd0,3'd0,2'd0,
             1'b1,1'b0,1'b0,1'b0,1'b1,1'b0});

        check_decode("R-type SLL",
            {7'b0000000,5'd2,5'd1,3'b001,5'd3,7'b0110011},
            {4'd5,3'd0,3'd0,2'd0,3'd0,2'd0,
             1'b1,1'b0,1'b0,1'b0,1'b1,1'b0});

        check_decode("R-type SRL",
            {7'b0000000,5'd2,5'd1,3'b101,5'd3,7'b0110011},
            {4'd6,3'd0,3'd0,2'd0,3'd0,2'd0,
             1'b1,1'b0,1'b0,1'b0,1'b1,1'b0});

        check_decode("R-type SRA",
            {7'b0100000,5'd2,5'd1,3'b101,5'd3,7'b0110011},
            {4'd7,3'd0,3'd0,2'd0,3'd0,2'd0,
             1'b1,1'b0,1'b0,1'b0,1'b1,1'b0});

        check_decode("R-type SLT",
            {7'b0000000,5'd2,5'd1,3'b010,5'd3,7'b0110011},
            {4'd8,3'd0,3'd0,2'd0,3'd0,2'd0,
             1'b1,1'b0,1'b0,1'b0,1'b1,1'b0});

        check_decode("R-type SLTU",
            {7'b0000000,5'd2,5'd1,3'b011,5'd3,7'b0110011},
            {4'd9,3'd0,3'd0,2'd0,3'd0,2'd0,
             1'b1,1'b0,1'b0,1'b0,1'b1,1'b0});

        check_decode("Illegal R-type funct combination",
            {7'b0100000,5'd2,5'd1,3'b100,5'd3,7'b0110011},
            {4'd0,3'd0,3'd0,2'd0,3'd0,2'd0,
             1'b1,1'b0,1'b0,1'b0,1'b0,1'b1});

        // --------------------------------------------------
        // OP-IMM: immediate ALU operations
        // --------------------------------------------------

        check_decode("ADDI",
            {12'd42,5'd1,3'b000,5'd3,7'b0010011},
            {4'd0,3'd0,3'd0,2'd0,3'd0,2'd0,
             1'b0,1'b1,1'b0,1'b0,1'b1,1'b0});

        check_decode("SLLI",
            {7'b0000000,5'd4,5'd1,3'b001,5'd3,7'b0010011},
            {4'd5,3'd0,3'd0,2'd0,3'd0,2'd0,
             1'b0,1'b1,1'b0,1'b0,1'b1,1'b0});

        check_decode("SLTI",
            {12'd42,5'd1,3'b010,5'd3,7'b0010011},
            {4'd8,3'd0,3'd0,2'd0,3'd0,2'd0,
             1'b0,1'b1,1'b0,1'b0,1'b1,1'b0});

        check_decode("SLTIU",
            {12'd42,5'd1,3'b011,5'd3,7'b0010011},
            {4'd9,3'd0,3'd0,2'd0,3'd0,2'd0,
             1'b0,1'b1,1'b0,1'b0,1'b1,1'b0});

        check_decode("XORI",
            {12'd42,5'd1,3'b100,5'd3,7'b0010011},
            {4'd2,3'd0,3'd0,2'd0,3'd0,2'd0,
             1'b0,1'b1,1'b0,1'b0,1'b1,1'b0});

        check_decode("SRLI",
            {7'b0000000,5'd4,5'd1,3'b101,5'd3,7'b0010011},
            {4'd6,3'd0,3'd0,2'd0,3'd0,2'd0,
             1'b0,1'b1,1'b0,1'b0,1'b1,1'b0});

        check_decode("SRAI",
            {7'b0100000,5'd4,5'd1,3'b101,5'd3,7'b0010011},
            {4'd7,3'd0,3'd0,2'd0,3'd0,2'd0,
             1'b0,1'b1,1'b0,1'b0,1'b1,1'b0});

        check_decode("ORI",
            {12'd42,5'd1,3'b110,5'd3,7'b0010011},
            {4'd3,3'd0,3'd0,2'd0,3'd0,2'd0,
             1'b0,1'b1,1'b0,1'b0,1'b1,1'b0});

        check_decode("ANDI",
            {12'd42,5'd1,3'b111,5'd3,7'b0010011},
            {4'd4,3'd0,3'd0,2'd0,3'd0,2'd0,
             1'b0,1'b1,1'b0,1'b0,1'b1,1'b0});

        check_decode("Illegal SLLI funct bits",
            {7'b0100000,5'd4,5'd1,3'b001,5'd3,7'b0010011},
            {4'd0,3'd0,3'd0,2'd0,3'd0,2'd0,
             1'b0,1'b1,1'b0,1'b0,1'b0,1'b1});

        // --------------------------------------------------
        // Loads and stores
        // --------------------------------------------------

        check_decode("LW",
            {12'd8,5'd1,3'b010,5'd3,7'b0000011},
            {4'd0,3'd0,3'b011,2'd0,3'd0,2'd0,
             1'b0,1'b0,1'b0,1'b0,1'b1,1'b0});

        check_decode("LBU",
            {12'd0,5'd1,3'b100,5'd3,7'b0000011},
            {4'd0,3'd0,3'b100,2'd0,3'd0,2'd0,
             1'b0,1'b0,1'b0,1'b0,1'b1,1'b0});

        check_decode("Illegal load funct3",
            {12'd0,5'd1,3'b011,5'd3,7'b0000011},
            {4'd0,3'd0,3'd0,2'd0,3'd0,2'd0,
             1'b0,1'b0,1'b0,1'b0,1'b0,1'b1});

        check_decode("SW",
            {7'b0000000,5'd2,5'd1,3'b010,5'd8,7'b0100011},
            {4'd0,3'd1,3'd0,2'b11,3'd0,2'd0,
             1'b0,1'b0,1'b0,1'b0,1'b0,1'b0});

        check_decode("Illegal store funct3",
            {7'b0000000,5'd2,5'd1,3'b011,5'd8,7'b0100011},
            {4'd0,3'd1,3'd0,2'd0,3'd0,2'd0,
             1'b0,1'b0,1'b0,1'b0,1'b0,1'b1});

        // --------------------------------------------------
        // Branches
        // --------------------------------------------------

        check_decode("BEQ",
            {1'b0,6'b0,5'd2,5'd1,3'b000,4'b0,1'b0,7'b1100011},
            {4'd0,3'd2,3'd0,2'd0,3'd1,2'd0,
             1'b0,1'b0,1'b0,1'b0,1'b0,1'b0});

        check_decode("BGEU",
            {1'b0,6'b0,5'd2,5'd1,3'b111,4'b0,1'b0,7'b1100011},
            {4'd0,3'd2,3'd0,2'd0,3'd6,2'd0,
             1'b0,1'b0,1'b0,1'b0,1'b0,1'b0});

        check_decode("Illegal branch funct3",
            {1'b0,6'b0,5'd2,5'd1,3'b010,4'b0,1'b0,7'b1100011},
            {4'd0,3'd2,3'd0,2'd0,3'd0,2'd0,
             1'b0,1'b0,1'b0,1'b0,1'b0,1'b1});

        // --------------------------------------------------
        // Jumps
        // --------------------------------------------------

        check_decode("JAL",
            {1'b0,10'd0,1'b0,8'h00,5'd3,7'b1101111},
            {4'd0,3'd4,3'd0,2'd0,3'd0,2'b01,
             1'b0,1'b0,1'b0,1'b0,1'b1,1'b0});

        check_decode("JALR",
            {12'd0,5'd1,3'b000,5'd3,7'b1100111},
            {4'd0,3'd0,3'd0,2'd0,3'd0,2'b10,
             1'b0,1'b0,1'b0,1'b0,1'b1,1'b0});

        check_decode("Illegal JALR funct3",
            {12'd0,5'd1,3'b001,5'd3,7'b1100111},
            {4'd0,3'd0,3'd0,2'd0,3'd0,2'd0,
             1'b0,1'b0,1'b0,1'b0,1'b0,1'b1});

        // --------------------------------------------------
        // U-type
        // --------------------------------------------------

        check_decode("LUI",
            {20'h12345,5'd5,7'b0110111},
            {4'd0,3'd3,3'd0,2'd0,3'd0,2'd0,
             1'b0,1'b0,1'b1,1'b0,1'b1,1'b0});

        check_decode("AUIPC",
            {20'h12345,5'd5,7'b0010111},
            {4'd0,3'd3,3'd0,2'd0,3'd0,2'd0,
             1'b0,1'b0,1'b0,1'b1,1'b1,1'b0});

        // --------------------------------------------------
        // Unsupported instructions
        // --------------------------------------------------

        check_decode("Unsupported SYSTEM instruction",
            32'h00000073,
            {4'd0,3'd0,3'd0,2'd0,3'd0,2'd0,
             1'b0,1'b0,1'b0,1'b0,1'b0,1'b1});

        check_decode("Unknown opcode",
            32'h00000000,
            {4'd0,3'd0,3'd0,2'd0,3'd0,2'd0,
             1'b0,1'b0,1'b0,1'b0,1'b0,1'b1});

        $display("SUCCESS: All decoder tests passed!");
        $finish;
    end

endmodule