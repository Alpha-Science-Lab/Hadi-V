
module icarus_top;

    integer error_count = 0;

    /* verilator lint_off unusedsignal */
    logic        clk;
    logic  [4:0] buttons_async = 0;

    icarus_soc #(
        .CLK_FREQUENCY_MHZ(9.0)
    ) soc (
        .clk(clk),
        .buttons_async(buttons_async)
    );

    // System clock
    initial begin
        clk = 1;
        forever begin
            #(int'((1000.0 / 9.0) / 2)); // 9MHz system clock
            clk = ~clk;
        end
    end

    initial begin
        buttons_async = 5'b00001; // assert reset

        // hold reset for some cycles
        repeat (32) @(posedge clk);

        buttons_async = 5'b00000; // release reset
    end

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, icarus_top);

        // Run for 100000 cycles max
        repeat (100000) @(negedge clk);

        // Stop simulation
        $display("\033[0;33m"); // color_orange
        $display("Simulation timeout!");
        $display("\033[0m"); // color off
        $finish();
    end

    // Respond to test interface
    always @(posedge clk) begin
        if (soc.wb_test.test_stb) begin
            case (soc.wb_test.test_reg)
                0: $display("(%6d ps) Test pass!", $time());
                1: begin
                    $display("(%6d ps) Test fail!", $time());
                    error_count <= error_count + 1;
                end
                2: begin
                    print_test_done();
                    $fflush();
                    $finish();
                end
            endcase
        end

        if (soc.wb_test.scratchpad_stb) begin
            $display("\033[0;33m"); // color_orange
            $display("(%6d ps) Scratchpad: 0x%08h", 
                $time(), soc.wb_test.scratchpad_reg);
            $display("\033[0m"); // color off

        end

    end

    // ---------------------------------------------------------------------
    // print helper functions
    function void print_test_done();
        if (error_count > 0) begin
            $display("\033[0;31m"); // color_red
            $display("Some test(s) failed! (# Errors: %1d)", error_count);
        end
        else begin
            $display("\033[0;32m"); // color green
            $display("All tests passed! (# Errors: %1d)", error_count);
        end
        
        $display("TEST DONE");
        $display("\033[0m"); // color off
    endfunction
endmodule
