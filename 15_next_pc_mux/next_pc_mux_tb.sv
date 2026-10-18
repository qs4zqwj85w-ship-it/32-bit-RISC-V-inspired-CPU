module next_pc_mux_tb;
    logic [31:0] alu_result;
    logic [31:0] alu_reg_out;
    logic pc_sel;
    logic [31:0] next_pc_val;

    next_pc_mux dut(
        .alu_result(alu_result),
        .alu_out_reg_out(alu_reg_out),
        .pc_source_sel(pc_sel),
        .next_pc(next_pc_val)
    );

    initial begin
        alu_result = 32'd1;
        alu_reg_out = 32'd2;
        pc_sel = 1'b0;
        next_pc_val = 32'd0;

        //Test 1
        
        pc_sel = 1'b0;
        #1; 
        if (next_pc_val !== alu_result) begin 
            $display("Test 1 Failed: pc_sel = %b, output = %d, expected = %d", pc_sel, next_pc_val, alu_result);
        end else begin
            $display("Test 1 Passed: pc_sel = %b, output = %d", pc_sel, next_pc_val);
        end
        
        //Test 2
        pc_sel = 1'b1;
        #1; 
        if (next_pc_val !== alu_reg_out) begin 
            $display("Test 2 Failed: pc_sel = %b, output = %d, expected = %d", pc_sel, next_pc_val, alu_reg_out);
        end else begin
            $display("Test 2 Passed: pc_sel = %b, output = %d", pc_sel, next_pc_val);
        end
    end



endmodule
