
module control_fsm (
    input logic clk,
    input logic rst,

    input logic is_alu_reg,
    input logic is_alu_imm,
    input logic [2:0] load_type,
    input logic [1:0] store_type,
    input logic [2:0] branch_type,
    input logic [1:0] jump_type,
    input logic is_lui,
    input logic is_auipc,
    input logic writes_rd,
    input logic illegal,

    input logic branch_taken,
    input logic [3:0] decoded_alu_op,

    //Environmental instructions
    input logic is_ecall,
    input logic is_ebreak,

    // CSR instructions
    input  logic is_csr,
    input logic is_mret,


    // PC and instruction fetch
    output logic pc_enable,
    output logic pc_source_sel,
    output logic ir_write_enable,

    // Memory and address selection
    output logic mem_addr_sel,
    output logic mar_write_enable,
    output logic mar_src_sel,
    output logic mem_read_enable,
    output logic mem_write_enable,
    output logic [1:0] access_size,
    output logic load_unsigned,

    // ALU
    output logic [1:0] alu_a_sel,
    output logic [1:0] alu_b_sel,
    output logic [3:0] alu_ctrl,

    // Other datapath registers
    output logic mdr_write_enable,
    output logic alu_out_reg_write_enable,
    output logic op_AB_reg_write_enable,

    // Register-file writeback
    output logic reg_write_enable,
    output logic [1:0] wb_sel,

    // JALR target mask
    output logic jalr_target_mask,

    // environmental trap
    output logic trap_enter,

    // CSR execution outoput
    output logic csr_execute,
    output logic mret_execute,

);

// State encodings
localparam logic [2:0] FETCH       = 3'b001;
localparam logic [2:0] DECODE      = 3'b010;
localparam logic [2:0] EXECUTE     = 3'b011;
localparam logic [2:0] MEMORY      = 3'b100;
localparam logic [2:0] WRITEBACK   = 3'b101;
localparam logic [2:0] FETCH_WAIT  = 3'b110;
localparam logic [2:0] MEMORY_WAIT = 3'b111;

localparam logic [2:0] TRAP = 3'b000;

logic [2:0] state;
logic [2:0] next_state;



// State register
always_ff @(posedge clk) begin
    if (rst)
        state <= FETCH;
    else
        state <= next_state;
end

// Control logic
always_comb begin
    // Default: remain in current state
    next_state = state;

    // Default control signals
    pc_enable = 1'b0;
    pc_source_sel = 1'b0;
    ir_write_enable = 1'b0;

    mem_addr_sel = 1'b0;
    mar_write_enable = 1'b0;
    mar_src_sel = 1'b0;
    mem_read_enable = 1'b0;
    mem_write_enable = 1'b0;
    access_size = 2'b10;
    load_unsigned = 1'b0;

    alu_a_sel = 2'b00;
    alu_b_sel = 2'b10;
    alu_ctrl = 4'd0;

    mdr_write_enable = 1'b0;
    alu_out_reg_write_enable = 1'b0;
    op_AB_reg_write_enable = 1'b0;

    reg_write_enable = 1'b0;
    wb_sel = 2'b00;

    jalr_target_mask = 1'b0;

    trap_enter = 1'b0;

    csr_execute = 1'b0;
    mret_execute = 1'b0;

    case (state)

        // -----------------------------------------
        // FETCH: Request instruction from RAM
        // -----------------------------------------
        FETCH: begin
            mem_addr_sel = 1'b0;       // PC
            mem_read_enable = 1'b1;
            access_size = 2'b10;       // Full word

            // Synchronous RAM output becomes valid
            // after the clock edge.
            next_state = FETCH_WAIT;
        end

        // -----------------------------------------
        // FETCH_WAIT: Capture instruction and
        // increment PC by 4
        // -----------------------------------------
        FETCH_WAIT: begin
            ir_write_enable = 1'b1;

            // Save the instruction's original address
            mar_write_enable = 1'b1;
            mar_src_sel = 1'b0;        // PC

            // ALU = PC + 4
            alu_a_sel = 2'b00;         // PC
            alu_b_sel = 2'b10;         // Constant 4
            alu_ctrl = 4'd0;           // ADD

            alu_out_reg_write_enable = 1'b1;
            pc_source_sel = 1'b0;      // ALU result
            pc_enable = 1'b1;

            next_state = DECODE;
        end

        // -----------------------------------------
        // DECODE: Capture operands and calculate
        // branch target when needed
        // -----------------------------------------
        DECODE: begin
            op_AB_reg_write_enable = 1'b1;

            if (branch_type != 3'b000) begin
                alu_a_sel = 2'b01;     // MAR
                alu_b_sel = 2'b01;     // Immediate
                alu_ctrl = 4'd0;       // ADD
                alu_out_reg_write_enable = 1'b1;
            end

            next_state = EXECUTE;
        end

        // -----------------------------------------
        // EXECUTE
        // -----------------------------------------
        EXECUTE: begin
            if (is_ecall || is_ebreak) begin
                next_state = TRAP;
            end

            else if (illegal) begin
                next_state = TRAP;
            end

            else if (is_csr) begin
                csr_execute = 1'b1;
                next_state  = WRITEBACK;
            end
            else if (is_mret) begin
                mret_execute = 1'b1;
                pc_enable = 1'b1;
                next_state = FETCH;
            end

            // R-type ALU instructions
            else if (is_alu_reg) begin
                alu_a_sel = 2'b10;     // Operand A
                alu_b_sel = 2'b00;     // Operand B
                alu_ctrl = decoded_alu_op;

                alu_out_reg_write_enable = 1'b1;
                next_state = WRITEBACK;
            end

            // I-type ALU instructions
            else if (is_alu_imm) begin
                alu_a_sel = 2'b10;     // Operand A
                alu_b_sel = 2'b01;     // Immediate
                alu_ctrl = decoded_alu_op;

                alu_out_reg_write_enable = 1'b1;
                next_state = WRITEBACK;
            end

            // Loads and stores: calculate effective address
            else if ((load_type != 3'b000) ||
                     (store_type != 2'b00)) begin

                alu_a_sel = 2'b10;     // Base address
                alu_b_sel = 2'b01;     // Offset immediate
                alu_ctrl = 4'd0;       // ADD

                mar_src_sel = 1'b1;    // ALU result
                mar_write_enable = 1'b1;

                next_state = MEMORY;
            end

            // Conditional branches
            else if (branch_type != 3'b000) begin
                if (branch_taken) begin
                    pc_source_sel = 1'b1; // Saved target
                    pc_enable = 1'b1;
                end

                next_state = FETCH;
            end

            // JAL and JALR
            else if (jump_type != 2'b00) begin
                if (jump_type == 2'b01) begin
                    alu_a_sel = 2'b01; // MAR: instruction PC
                end
                else begin
                    alu_a_sel = 2'b10; // Operand A: rs1
                    jalr_target_mask = 1'b1;
                end

                alu_b_sel = 2'b01;     // Jump immediate
                alu_ctrl = 4'd0;       // ADD

                pc_source_sel = 1'b0;  // ALU result
                pc_enable = 1'b1;

                // Preserve ALU Out containing PC + 4
                // for the return-address writeback.
                next_state = WRITEBACK;
            end

            // LUI
            else if (is_lui) begin
                next_state = WRITEBACK;
            end

            // AUIPC
            else if (is_auipc) begin
                alu_a_sel = 2'b01;     // MAR: instruction PC
                alu_b_sel = 2'b01;     // U-type immediate
                alu_ctrl = 4'd0;       // ADD

                alu_out_reg_write_enable = 1'b1;
                next_state = WRITEBACK;
            end

            else begin
                next_state = FETCH;
            end
        end

        // -----------------------------------------
        // MEMORY: Request load or perform store
        // -----------------------------------------
        MEMORY: begin
            mem_addr_sel = 1'b1;       // MAR

            // LOAD: LB, LH, LW, LBU, LHU
            if (load_type != 3'b000) begin
                mdr_write_enable = 1'b0;
                mem_write_enable = 1'b0;

                case (load_type)
                    3'b001: begin       // LB
                        access_size = 2'b00;
                        load_unsigned = 1'b0;
                    end

                    3'b010: begin       // LH
                        access_size = 2'b01;
                        load_unsigned = 1'b0;
                    end

                    3'b011: begin       // LW
                        access_size = 2'b10;
                        load_unsigned = 1'b0;
                    end

                    3'b100: begin       // LBU
                        access_size = 2'b00;
                        load_unsigned = 1'b1;
                    end

                    3'b101: begin       // LHU
                        access_size = 2'b01;
                        load_unsigned = 1'b1;
                    end

                    default: begin
                        next_state = FETCH;
                    end
                endcase

                if ((load_type >= 3'b001) &&
                    (load_type <= 3'b101)) begin
                    mem_read_enable = 1'b1;
                    next_state = MEMORY_WAIT;
                end
            end

            // STORE: SB, SH, SW
            else if (store_type != 2'b00) begin
                mdr_write_enable = 1'b0;
                mem_write_enable = 1'b1;

                case (store_type)
                    2'b01: access_size = 2'b00; // SB
                    2'b10: access_size = 2'b01; // SH
                    2'b11: access_size = 2'b10; // SW

                    default: begin
                        mem_write_enable = 1'b0;
                    end
                endcase

                next_state = FETCH;
            end

            else begin
                next_state = FETCH;
            end
        end

        // -----------------------------------------
        // MEMORY_WAIT: Capture synchronous RAM output
        // -----------------------------------------
        MEMORY_WAIT: begin
            mdr_write_enable = 1'b1;
            next_state = WRITEBACK;
        end

        // -----------------------------------------
        // WRITEBACK
        // -----------------------------------------
        WRITEBACK: begin
            if (writes_rd && !illegal) begin
                reg_write_enable = 1'b1;

                // Load result from MDR
                if (load_type != 3'b000) begin
                    wb_sel = 2'b01;
                end

                // LUI immediate
                else if (is_lui) begin
                    wb_sel = 2'b11;
                end

                // ALU, AUIPC, JAL, JALR
                else begin
                    wb_sel = 2'b00;
                end
            end

            next_state = FETCH;
        end

        // -----------------------------------------
        // Invalid state recovery
        // -----------------------------------------
        default: begin
            next_state = FETCH;
        end

        TRAP: begin
            // Save exception state and redirect the PC on this clock edge.
            trap_enter = 1'b1;
            pc_enable  = 1'b1;
            next_state = FETCH;
        end
        
    endcase
end

endmodule
