module memory_address_mux_tb;

    logic [31:0] pc_out;
    logic [31:0] mar_out;
    logic        memory_sel;
    logic [31:0] memory_address;

    memory_address_mux dut (
        .pc_out(pc_out),
        .mar_out(mar_out),
        .memory_sel(memory_sel),
        .memory_address(memory_address)
    );

    initial begin
        pc_out = 32'd1;
        mar_out = 32'd2;
        memory_sel = 1'b0;

        $display("\nTEST 1: Select PC address");

        memory_sel = 1'b0;
        #1;

        if (memory_address !== pc_out)
            $fatal(1, "TEST 1 FAILED: PC address selection");

        $display("TEST 1 PASSED: memory_address = %d",
                 memory_address);

        $display("\nTEST 2: Select MAR address");

        memory_sel = 1'b1;
        #1;

        if (memory_address !== mar_out)
            $fatal(1, "TEST 2 FAILED: MAR address selection");

        $display("TEST 2 PASSED: memory_address = %d",
                 memory_address);


        $display("\nALL MEMORY ADDRESS MUX TESTS PASSED!");
        $finish;
    end

endmodule
