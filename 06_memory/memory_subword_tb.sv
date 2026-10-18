module memory_subword_tb;

    logic        clk;
    logic [31:0] address;
    logic [31:0] write_data_in;
    logic        write_enable;
    logic [31:0] read_data_out;
    logic        load_unsigned;
    logic [1:0]  access_size;

    memory_subword dut (
        .clk(clk),
        .address(address),
        .write_data_in(write_data_in),
        .write_enable(write_enable),
        .load_unsigned(load_unsigned),
        .access_size(access_size),
        .read_data_out(read_data_out)
    );

    // Generate a 10-time-unit clock
    initial clk = 1'b0;
    always #5 clk = ~clk;


    // Helper task: perform one memory write
    task automatic store_value(
        input logic [31:0] addr,
        input logic [31:0] value,
        input logic [1:0]  size
    );
        begin
            // Set inputs on the falling edge to avoid a race
            @(negedge clk);
            address       = addr;
            write_data_in = value;
            access_size   = size;
            load_unsigned = 1'b0;
            write_enable  = 1'b1;

            // Memory write occurs on the rising edge
            @(posedge clk);
            #1;
            write_enable = 1'b0;
            #1;
        end
    endtask


    // Helper task: perform a read and check its expected value
    task automatic check_read(
        input logic [31:0] addr,
        input logic [1:0]  size,
        input logic        unsigned_mode,
        input logic [31:0] expected,
        input string       test_name
    );
        begin
            @(negedge clk);
            address       = addr;
            access_size   = size;
            load_unsigned = unsigned_mode;
            write_enable  = 1'b0;

            // Allow combinational read logic to settle
            #1;

            if (read_data_out !== expected)
                $fatal(
                    1,
                    "FAIL: %s | addr=%08h size=%b unsigned=%b expected=%08h got=%08h",
                    test_name, addr, size, unsigned_mode,
                    expected, read_data_out
                );

            $display(
                "PASS: %s | addr=%08h read_data=%08h",
                test_name, addr, read_data_out
            );
        end
    endtask


    initial begin
        // Initialize all inputs
        address       = 32'd0;
        write_data_in = 32'd0;
        write_enable  = 1'b0;
        load_unsigned = 1'b0;
        access_size   = 2'b10;


        // =====================================================
        // TEST 1: Store and load a 32-bit word (SW / LW)
        // Expected word: ABCD1234
        // Little-endian bytes: 34, 12, CD, AB
        // =====================================================
        $display("\nTEST 1: Word store/load");

        store_value(32'd0, 32'hABCD1234, 2'b10);
        check_read(
            32'd0, 2'b10, 1'b0,
            32'hABCD1234, "SW/LW word roundtrip"
        );


        // =====================================================
        // TEST 2: Signed and unsigned byte loads (LB / LBU)
        // Address 3 contains AB.
        // Signed:   FFFFFFAB
        // Unsigned: 000000AB
        // =====================================================
        $display("\nTEST 2: Signed/unsigned byte loads");

        check_read(
            32'd3, 2'b00, 1'b0,
            32'hFFFFFFAB, "LB sign extension"
        );

        check_read(
            32'd3, 2'b00, 1'b1,
            32'h000000AB, "LBU zero extension"
        );


        // =====================================================
        // TEST 3: Signed and unsigned halfword loads (LH / LHU)
        // Address 2 contains the halfword ABCD.
        // Signed:   FFFFABCD
        // Unsigned: 0000ABCD
        // =====================================================
        $display("\nTEST 3: Signed/unsigned halfword loads");

        check_read(
            32'd2, 2'b01, 1'b0,
            32'hFFFFABCD, "LH sign extension"
        );

        check_read(
            32'd2, 2'b01, 1'b1,
            32'h0000ABCD, "LHU zero extension"
        );


        // =====================================================
        // TEST 4: Store one byte (SB)
        // Store FE at address 1.
        // Other three bytes must remain unchanged.
        // Expected word at address 0: ABCDFE34
        // =====================================================
        $display("\nTEST 4: Byte store preserves neighboring bytes");

        store_value(32'd1, 32'h000000FE, 2'b00);

        check_read(
            32'd0, 2'b10, 1'b0,
            32'hABCDFE34, "SB preserves other bytes"
        );


        // =====================================================
        // TEST 5: Store a halfword (SH)
        // Store 8001 at address 2.
        // Expected word at address 0: 8001FE34
        // =====================================================
        $display("\nTEST 5: Halfword store preserves neighboring bytes");

        store_value(32'd2, 32'h00008001, 2'b01);

        check_read(
            32'd0, 2'b10, 1'b0,
            32'h8001FE34, "SH preserves other bytes"
        );


        // =====================================================
        // TEST 6: Signed and unsigned loads of halfword 8001
        // Signed:   FFFF8001
        // Unsigned: 00008001
        // =====================================================
        $display("\nTEST 6: Sign extension of halfword with bit 15 set");

        check_read(
            32'd2, 2'b01, 1'b0,
            32'hFFFF8001, "LH sign extension of 8001"
        );

        check_read(
            32'd2, 2'b01, 1'b1,
            32'h00008001, "LHU zero extension of 8001"
        );


        // =====================================================
        // TEST 7: Disabled writes must not change memory
        // Attempt to write 00 to byte address 0 while disabled.
        // Expected word must remain 8001FE34.
        // =====================================================
        $display("\nTEST 7: Write disabled");

        @(negedge clk);
        address       = 32'd0;
        write_data_in = 32'h00000000;
        access_size   = 2'b00;
        load_unsigned = 1'b0;
        write_enable  = 1'b0;

        @(posedge clk);
        #1;

        check_read(
            32'd0, 2'b10, 1'b0,
            32'h8001FE34, "Disabled write leaves memory unchanged"
        );


        // =====================================================
        // TEST 8: Invalid reads
        // Misaligned halfword at address 1 -> zero
        // Misaligned word at address 2       -> zero
        // Out-of-range byte at address 4096  -> zero
        // =====================================================
        $display("\nTEST 8: Invalid reads");

        check_read(
            32'd1, 2'b01, 1'b0,
            32'h00000000, "Reject misaligned halfword read"
        );

        check_read(
            32'd2, 2'b10, 1'b0,
            32'h00000000, "Reject misaligned word read"
        );

        check_read(
            32'd4096, 2'b00, 1'b0,
            32'h00000000, "Reject out-of-range byte read"
        );


        // =====================================================
        // TEST 9: Invalid misaligned write must not corrupt memory
        // Attempt halfword write at address 1.
        // Word at address 0 must remain 8001FE34.
        // =====================================================
        $display("\nTEST 9: Reject invalid misaligned write");

        @(negedge clk);
        address       = 32'd1;
        write_data_in = 32'hDEADBEEF;
        access_size   = 2'b01;
        load_unsigned = 1'b0;
        write_enable  = 1'b1;

        @(posedge clk);
        #1;
        write_enable = 1'b0;

        check_read(
            32'd0, 2'b10, 1'b0,
            32'h8001FE34, "Invalid write does not corrupt memory"
        );


        // =====================================================
        // TEST 10: Out-of-range write must not alias address 0
        // Address 4096 exceeds the 4 KiB memory.
        // =====================================================
        $display("\nTEST 10: Reject out-of-range write");

        @(negedge clk);
        address       = 32'd4096;
        write_data_in = 32'h000000DE;
        access_size   = 2'b00;
        load_unsigned = 1'b0;
        write_enable  = 1'b1;

        @(posedge clk);
        #1;
        write_enable = 1'b0;

        check_read(
            32'd0, 2'b10, 1'b0,
            32'h8001FE34, "Out-of-range write does not alias address 0"
        );


        $display("\nALL MEMORY SUBWORD TESTS PASSED!");
        $finish;
    end

endmodule
