`timescale 1ns/1ps
// File: fir_parallel_pipelined_3_tb.v
// Testbench for Combined Pipelined and L=3 Parallel FIR Filter

module fir_parallel_pipelined_3_tb;

    // Testbench signals
    reg                clk;
    reg                reset;
    reg  signed [15:0] data_in;
    wire signed [31:0] data_out;
    
    // Instantiate the DUT
    fir_parallel_pipelined_3 dut (
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .data_out(data_out)
    );
    
    // Clock generation: 10 ns period (100 MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // File handle and simulation completion flag for logging
    integer out_file;
    reg sim_done;
    
    // Stimulus generation and logging
    initial begin
        sim_done = 0;
        out_file = $fopen("output_samples_parallel_pipelined_3.txt", "w");
        if (out_file == 0) begin
            $display("ERROR: Could not open output_samples_parallel_pipelined_3.txt for writing.");
            $finish;
        end
        
        // Optional: Dump waveforms for simulation viewing
        $dumpfile("fir_parallel_pipelined_3_tb.vcd");
        $dumpvars(0, fir_parallel_pipelined_3_tb);
        
        // Initialize signals
        reset   = 1;
        data_in = 16'sd0;
        #20;  // Hold reset for 20 ns (2 clock cycles)
        reset = 0;
        
        // Apply an impulse: data_in = 1 for one clock cycle
        data_in = 16'sd1;
        #10;
        data_in = 16'sd0;
        
        // Run simulation long enough to capture the impulse response
        #3000;
        
        sim_done = 1;
        #10;
        $fclose(out_file);
        $finish;
    end
    
    // Logging block: log data_out at each rising clock edge until simulation is done.
    initial begin
        @(negedge reset);
        while (!sim_done) begin
            @(posedge clk);
            if (!reset)
                $fwrite(out_file, "%d\n", data_out);
        end
    end

endmodule
