module machine_csrs #(
    parameter logic [31:0] RESET_MTVEC = 32'h0000_0100
) (
    input  logic        clk,
    input  logic        reset,

    // CSR access
    input  logic [11:0] csr_addr,
    input  logic        csr_write_enable,
    input  logic [31:0] csr_write_data,
    output logic [31:0] csr_read_data,
    output logic        csr_addr_valid,

    // Exception entry
    input  logic        trap_enter,
    input  logic [31:0] trap_pc,
    input  logic [31:0] trap_cause,
    input logic [31:0] trap_value,

    input logic mret_execute,

    // Outputs for CPU control
    output logic [31:0] mtvec_out,
    output logic [31:0] mepc_out,
    output logic csr_addr_read_only
);

    localparam logic [11:0] CSR_MSTATUS = 12'h300;
    localparam logic [11:0] CSR_MTVEC  = 12'h305;
    localparam logic [11:0] CSR_MEPC   = 12'h341;
    localparam logic [11:0] CSR_MCAUSE = 12'h342;
    localparam logic [11:0] CSR_MTVAL = 12'h343;
    localparam logic [11:0] CSR_MISA     = 12'h301;
    localparam logic [11:0] CSR_MSCRATCH = 12'h340;
    localparam logic [11:0] CSR_MHARTID  = 12'hF14;

    // RV32, I extension supported; M is added after RV32M is implemented.
    localparam logic [31:0] MISA_VALUE = 32'h4000_0100;


    logic [31:0] mtvec_q;
    logic [31:0] mepc_q;
    logic [31:0] mcause_q;
    logic [31:0] mtval_q;
    logic [31:0] mscratch_q;
    logic mstatus_mie_q;
    logic mstatus_mpie_q;
    logic [31:0] mstatus_read;

    assign mtvec_out = mtvec_q;
    assign mepc_out  = mepc_q;

    // =====================================================
    // CSR read and address validation
    // =====================================================

    always_comb begin
    mstatus_read = 32'd0;
    mstatus_read[3]     = mstatus_mie_q;   // MIE
    mstatus_read[7]     = mstatus_mpie_q;  // MPIE
    mstatus_read[12:11] = 2'b11;           // MPP = M

    // Defaults for combinational outputs
    csr_addr_valid     = 1'b1;
    csr_addr_read_only = 1'b0;
    csr_read_data      = 32'd0;

    case (csr_addr)
        CSR_MSTATUS: begin
            csr_read_data = mstatus_read;
        end

        CSR_MTVEC: begin
            csr_read_data = mtvec_q;
        end

        CSR_MEPC: begin
            csr_read_data = mepc_q;
        end

        CSR_MCAUSE: begin
            csr_read_data = mcause_q;
        end

        CSR_MTVAL: begin
            csr_read_data = mtval_q;
        end

        CSR_MSCRATCH: begin
            csr_read_data = mscratch_q;
        end

        CSR_MISA: begin
            csr_read_data = MISA_VALUE;
        end

        CSR_MHARTID: begin
            csr_read_data      = 32'd0;
            csr_addr_read_only = 1'b1;
        end

        default: begin
            csr_addr_valid = 1'b0;
            csr_read_data  = 32'd0;
        end
    endcase
end
    // =====================================================
    // CSR writes and trap-entry updates
    // =====================================================

    always_ff @(posedge clk) begin
        if (reset) begin
            mtvec_q         <= RESET_MTVEC & 32'hFFFF_FFFC;
            mepc_q          <= 32'd0;
            mcause_q        <= 32'd0;
            mstatus_mie_q   <= 1'b0;
            mstatus_mpie_q  <= 1'b0;
            mtval_q         <= 32'd0;
            mscratch_q <= 32'd0;
        end
        else if (trap_enter) begin
            // Save the instruction that raised the exception.
            mepc_q   <= {trap_pc[31:2], 2'b00};
            mcause_q <= trap_cause;
            mtval_q <= trap_value;

            // Machine-mode trap entry: MPIE <- MIE; MIE <- 0.
            mstatus_mpie_q <= mstatus_mie_q;
            mstatus_mie_q  <= 1'b0;
        end
        else if (mret_execute) begin
            // Machine-mode return from trap: MIE <- MPIE; MPIE <- 1.
            mstatus_mie_q  <= mstatus_mpie_q;
            mstatus_mpie_q <= 1'b1;
        end
        else if (csr_write_enable && csr_addr_valid) begin
            case (csr_addr)
                CSR_MSTATUS: begin
                    // Implement MIE and MPIE; keep MPP at M.
                    mstatus_mie_q  <= csr_write_data[3];
                    mstatus_mpie_q <= csr_write_data[7];
                end

                CSR_MTVEC: begin
                    // Support Direct mode only (MODE = 00).
                    mtvec_q <= csr_write_data & 32'hFFFF_FFFC;
                end

                CSR_MEPC: begin
                    // This core has IALIGN = 32.
                    mepc_q <= {csr_write_data[31:2], 2'b00};
                end

                CSR_MCAUSE: begin
                    mcause_q <= csr_write_data;
                end
                CSR_MTVAL: begin
                    mtval_q <= csr_write_data;
                end

                CSR_MSCRATCH: begin
                    mscratch_q <= csr_write_data;
                end

                CSR_MISA: begin
                    // Fixed WARL value. Writes have no effect.
                end

                CSR_MHARTID: begin
                    // Read-only. The CPU should reject write attempts.
                end

                default: begin
                end
            endcase
        end
    end

endmodule