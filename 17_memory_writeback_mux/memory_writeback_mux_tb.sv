module memory_writeback_mux_tb;

    logic [31:0] alu_out_reg_out;
    logic [31:0] mdr_out;
    logic [31:0] pc_out;
    logic [31:0] immediate;
    logic [1:0]  wb_sel;
    logic [31:0] writeback_data;

    memory_writeback_mux dut (
        .alu_out_reg_out(alu_out_reg_out),
        .mdr_out(mdr_out),
        .pc_out(pc_out),
        .immediate(immediate),
        .wb_sel(wb_sel),
        .writeback_data(writeback_data)
    );

    initial begin
        // Initialize inputs with distinct values
        alu_out_reg_out = 32'h11111111;
        mdr_out          = 32'h22222222;
        pc_out           = 32'h33333333;
        immediate        = 32'h44444444;
        wb_sel           = 2'b00;

        // =========================================
        // TEST 1: Select ALU output
        // =========================================
        $display("\nTEST 1: Select ALU output");

        wb_sel = 2'b00;
        #1;

        if (writeback_data !== 32'h11111111)
            $fatal(1, "FAIL: ALU output selection");

        $display("PASS: writeback_data = %08h", writeback_data);


        // =========================================
        // TEST 2: Select memory data
        // =========================================
        $display("\nTEST 2: Select MDR output");

        wb_sel = 2'b01;
        #1;

        if (writeback_data !== 32'h22222222)
            $fatal(1, "FAIL: MDR output selection");

        $display("PASS: writeback_data = %08h", writeback_data);


        // =========================================
        // TEST 3: Select PC
        // =========================================
        $display("\nTEST 3: Select PC");

        wb_sel = 2'b10;
        #1;

        if (writeback_data !== 32'h33333333)
            $fatal(1, "FAIL: PC selection");

        $display("PASS: writeback_data = %08h", writeback_data);


        // =========================================
        // TEST 4: Select immediate
        // =========================================
        $display("\nTEST 4: Select immediate");

        wb_sel = 2'b11;
        #1;

        if (writeback_data !== 32'h44444444)
            $fatal(1, "FAIL: Immediate selection");

        $display("PASS: writeback_data = %08h", writeback_data);


        $display("\nALL WRITEBACK MUX TESTS PASSED!");
        $finish;
    end

endmodule
