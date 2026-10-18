module program_counter_tb;

    logic       clk;
    logic       reset;
    logic       enable;
    logic [31:0] next_pc;
    logic [31:0] pc_out;

    pc dut(
        .clk(clk),
        .reset(reset),
        .pc_enable(enable),
        .next_pc(next_pc),
        .pc_out(pc_out)
    );

    // 10 time-unit clock
    always #5 clk = ~clk;

    initial begin
        // Initial values
        clk = 0;
        reset = 1;
        enable = 0;
        next_pc = 0;

        // Reset: PC should become 0
        @(posedge clk);
        #1;
        $display("Reset:    reset=%b enable=%b next_pc=%d pc_out=%d",
                 reset, enable, next_pc, pc_out);

        if (pc_out !== 32'd0)
            $error("Reset failed");


        // Load 4 into PC
        reset = 0;
        enable = 1;
        next_pc = 32'd4;

        @(posedge clk);
        #1;
        $display("Load 4:  reset=%b enable=%b next_pc=%d pc_out=%d",
                    reset, enable, next_pc, pc_out);

        if (pc_out !== 32'd4)
            $error("Load 4 failed");

        reset = 0;
        enable = 0;
        next_pc = 0;

        @(posedge clk);
        #1;
        $display("Load with enable 0:  reset=%b enable=%b next_pc=%d pc_out=%d",
                    reset, enable, next_pc, pc_out);
        
        if (pc_out !== 32'd4)
            $error("block failed");
        
        #1;

        reset = 0;
        enable = 1;
        next_pc = 100;

        @(posedge clk);
        #1;
        $display("Load with enable 1:  reset=%b enable=%b next_pc=%d pc_out=%d",
                    reset, enable, next_pc, pc_out);
        
        if (pc_out !== 32'd100)
            $error("Load 100 failed");

        $finish;
    end

endmodule
