module memory_4k_tb;

    logic       clk;
    logic [31:0] address;
    logic [31:0] write_data_in;
    logic write_enable;
    logic [31:0] read_data_out;

    memory_4k dut(
        .clk(clk),
        .address(address),
        .write_data_in(write_data_in),
        .write_enable(write_enable),
        .read_data_out(read_data_out)
    );

    initial clk = 0;

    // 10 time-unit clock
    always #5 clk = ~clk;

    initial begin
        address = 32'd0;
        write_data_in = 32'hABCD1234;
        write_enable = 1;

        @(posedge clk);
        #1;
        write_enable = 0; // Disable write after one clock cycle
        #1;
        $display("Address:  address=%h write_data_in=%h write_enable=%b read_data_out=%h",
                 address, write_data_in, write_enable, read_data_out);

        #1;

        address = 32'd4;
        write_data_in = 32'h12341234;
        write_enable = 1;

        @(posedge clk);
        #1;
        write_enable = 0; // Disable write after one clock cycle
        #1;
        $display("Address:  address=%h write_data_in=%h write_enable=%b read_data_out=%h",
                 address, write_data_in, write_enable, read_data_out);

        // Read back the first address
        address = 32'b0;
        @(posedge clk);
        #1;
        write_enable = 0; // Disable write after one clock cycle
        #1;
        $display("Address:  address=%h write_data_in=%h write_enable=%b read_data_out=%h",
                 address, write_data_in, write_enable, read_data_out);

        // Verify that a disabled write does not change memory
        address = 32'd0;
        write_data_in = 32'hDEADBEEF;
        write_enable = 0;

        @(posedge clk);
        #1;

        if (read_data_out !== 32'hABCD1234)
            $fatal(1, "Write-disabled test failed");

        $display("Write-disabled test passed!");

        // Verify that a disabled write does not change memory
        address = 32'd0;
        write_data_in = 32'hDEADBEEF;
        write_enable = 0;

        @(posedge clk);
        #1;

        if (read_data_out !== 32'hABCD1234)
            $fatal(1, "Write-disabled test failed");

        $display("Write-disabled test passed!");


        $finish;
    end

endmodule
