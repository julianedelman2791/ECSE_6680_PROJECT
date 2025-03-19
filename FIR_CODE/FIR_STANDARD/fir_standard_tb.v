`timescale 1ns/1ps

module fir_standard_tb;

    // Testbench signals
    reg                clk;
    reg                reset;
    reg  signed [15:0] data_in;
    wire signed [31:0] data_out;
    
    // Instantiate the FIR filter module (DUT)
    fir_standard dut (
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .data_out(data_out)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // File handle for logging output samples
    integer out_file;

    // Stimulus generation and logging
    initial begin
        // Open a text file for writing output samples
        out_file = $fopen("output_samples.txt", "w");
        if (!out_file) begin
            $display("ERROR: Could not open output_samples.txt for writing.");
            $finish;
        end
        
        // Dump waveforms for simulation viewing
        $dumpfile("fir_standard_tb.vcd");
        $dumpvars(0, fir_standard_tb);
        
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
        
        // Run simulation for 3000 ns to capture the impulse response
        #3000;
        
        // Close the file and finish simulation
        $fclose(out_file);
        $finish;
    end

    // Log data_out on every rising edge of clk (after reset is deasserted)
    always @(posedge clk) begin
        if (!reset) begin
            $fwrite(out_file, "%d\n", data_out);
        end
    end

endmodule
