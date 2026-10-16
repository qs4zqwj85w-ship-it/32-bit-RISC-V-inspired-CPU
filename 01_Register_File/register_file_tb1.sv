module register_file_tb;

    logic       clk;
    logic       write_en;
    logic [4:0] write_addr;
    logic [31:0] write_data;
    logic [4:0] read_addr1;
    logic [31:0] read_data1;

    logic [4:0] read_addr2;
    logic [31:0] read_data2;

    register_file dut (
        .clk(clk),
        .write_en(write_en),
        .write_addr(write_addr),
        .write_data(write_data),
        .read_addr1(read_addr1),
        .read_data1(read_data1),
        .read_addr2(read_addr2),
        .read_data2(read_data2)
    );

    // Clock: 10 time units per cycle
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        write_en = 0;
        write_addr = 0;
        write_data = 0;
        read_addr1 = 0;
        read_addr2 = 0;

        // Write 10101010 to register 3
        write_en = 1;
        write_addr = 5'b00001;
        write_data = 32'd42;

        @(posedge clk);
        #1;
        write_en = 1;

        write_addr = 5'b00010;
        write_data = 32'd17;
        #1;

        @(posedge clk);
        #1;
        write_en = 0;

        // Read register 3
        read_addr1 = 5'b00001;
        read_addr2 = 5'b00010;
        #1;

        $display("Read R3 through port 1: %b", read_data1);
        $display("Read R3 through port 2: %b", read_data2);

        //explicit fail test

        if (read_data1 !== 32'd42)
            $fatal(1, "FAIL: x1 should contain 42");

        if (read_data2 !== 32'd17)
            $fatal(1, "FAIL: x2 should contain 17");

        // Write 11110000 to register 6
        write_en = 1;
        write_addr = 5'b00000;
        write_data = 32'd42;

        @(posedge clk);
        #1;
        write_en = 0;

        // Read register 6
        // Read register 6
        read_addr1 = 5'b00000;
        #1;

        $display("Read R6 through port 1: %b", read_data1);

        if (read_data1 !== 32'd0)
            $fatal(1, "FAIL: x0 should contain 0");

        


        $finish;
    end

endmodule