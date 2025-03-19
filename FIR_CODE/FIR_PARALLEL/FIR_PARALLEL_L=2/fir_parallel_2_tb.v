`timescale 1ns/1ps
// File: fir_parallel_2_tb.v
// Testbench for the L=2 parallel (polyphase) FIR filter.

module fir_parallel_2_tb;

    // Testbench signals
    reg                clk;
    reg                reset;
    reg  signed [15:0] data_in;
    wire signed [31:0] data_out;
    
    // Instantiate the DUT (Device Under Test)
    fir_parallel_2 dut (
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
    
    // File handle for logging output samples
    integer out_file;
    reg sim_done;  // Flag to indicate simulation completion

    // Stimulus generation and logging
    initial begin
        sim_done = 0;
        // Open a text file for writing output samples
        out_file = $fopen("output_samples_parallel2.txt", "w");
        if (out_file == 0) begin
            $display("ERROR: Could not open output_samples_parallel2.txt for writing.");
            $finish;
        end
        
        // Optional: Dump waveforms for simulation viewing
        $dumpfile("fir_parallel_2_tb.vcd");
        $dumpvars(0, fir_parallel_2_tb);
        
        // Initialize signals
        reset   = 1;
        data_in = 16'sd0;
        
        // Hold reset for 20 ns (2 clock cycles)
        #20;
        reset = 0;
        
        // Apply an impulse: set data_in = 1 for one clock cycle
        data_in = 16'sd1;
        #10;
        data_in = 16'sd0;
        
        // Run simulation long enough to capture the impulse response
        #3000;
        
        // Indicate that simulation is done so logging stops
        sim_done = 1;
        // Close the file and finish simulation
        $fclose(out_file);
        $finish;
    end
    
    // Log data_out on every rising edge of clk (if not in reset and simulation not finished)
    always @(posedge clk) begin
        if (!reset && !sim_done) begin
            $fwrite(out_file, "%d\n", data_out);
        end
    end

endmodule
