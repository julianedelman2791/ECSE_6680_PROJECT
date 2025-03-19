// File: fir_parallel_3.v
// L = 3 Parallel (Polyphase) FIR Filter Implementation
// This module implements a FIR filter with 321 taps (coefficients).
// The coefficients are loaded from "fir_coefficients.txt" and partitioned
// into three branches. The outputs from branch1 and branch2 are delayed by
// 1 and 2 clock cycles respectively before being summed with branch0.

module fir_parallel_3 (
    input                    clk,
    input                    reset,
    input      signed [15:0] data_in,
    output reg signed [31:0] data_out
);
    // Total number of taps (coefficients)
    parameter TAP_NUM = 321;
    // Partition sizes (for a number divisible by 3 these will be equal)
    localparam SIZE0 = (TAP_NUM+2)/3; // Branch0: indices 0, 3, 6, ...
    localparam SIZE1 = (TAP_NUM+1)/3; // Branch1: indices 1, 4, 7, ...
    localparam SIZE2 = TAP_NUM/3;     // Branch2: indices 2, 5, 8, ...
    
    // Full coefficient array, then partitioned arrays for each branch
    reg signed [15:0] coeff_full [0:TAP_NUM-1];
    reg signed [15:0] coeff0 [0:SIZE0-1];
    reg signed [15:0] coeff1 [0:SIZE1-1];
    reg signed [15:0] coeff2 [0:SIZE2-1];
    
    // Shift register for input samples
    reg signed [15:0] shift_reg [0:TAP_NUM-1];
    
    // MAC sum variables (for each branch)
    reg signed [31:0] sum0, sum1, sum2;
    
    // Delay registers for aligning branch outputs:
    // branch1 is delayed by 1 clock cycle;
    // branch2 is delayed by 2 clock cycles.
    reg signed [31:0] delay1;   // branch1 delay (1 cycle)
    reg signed [31:0] delay2_1; // first delay stage for branch2
    reg signed [31:0] delay2_2; // second delay stage for branch2 (total 2-cycle delay)
    
    integer i, j;
    
    // Load coefficients from file and partition them into three branches.
    // The file "fir_coefficients.txt" should contain 321 lines of 16-bit binary numbers.
    initial begin
        $readmemb("fir_coefficients.txt", coeff_full);
        for (i = 0; i < TAP_NUM; i = i + 1) begin
            if (i % 3 == 0)
                coeff0[i/3] = coeff_full[i];
            else if (i % 3 == 1)
                coeff1[(i-1)/3] = coeff_full[i];
            else
                coeff2[(i-2)/3] = coeff_full[i];
        end
    end

    // Combined always block for shift register update and MAC computation.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Clear the shift register
            for (i = 0; i < TAP_NUM; i = i + 1)
                shift_reg[i] <= 16'd0;
            // Clear delay registers and output
            delay1   <= 32'd0;
            delay2_1 <= 32'd0;
            delay2_2 <= 32'd0;
            data_out <= 32'd0;
        end else begin
            // Update shift register: new sample enters at index 0, shifting all others.
            shift_reg[0] <= data_in;
            for (i = 1; i < TAP_NUM; i = i + 1)
                shift_reg[i] <= shift_reg[i-1];
            
            // Compute MAC for branch0: indices 0, 3, 6, ...
            sum0 = 32'd0;
            for (j = 0; j < SIZE0; j = j + 1)
                sum0 = sum0 + shift_reg[3*j] * coeff0[j];
            
            // Compute MAC for branch1: indices 1, 4, 7, ...
            sum1 = 32'd0;
            for (j = 0; j < SIZE1; j = j + 1)
                sum1 = sum1 + shift_reg[3*j+1] * coeff1[j];
            
            // Compute MAC for branch2: indices 2, 5, 8, ...
            sum2 = 32'd0;
            for (j = 0; j < SIZE2; j = j + 1)
                sum2 = sum2 + shift_reg[3*j+2] * coeff2[j];
            
            // Update delay registers:
            delay1   <= sum1;       // branch1 output delayed by 1 clock cycle
            delay2_1 <= sum2;       // branch2 first delay stage
            delay2_2 <= delay2_1;   // branch2 second delay stage (total 2-cycle delay)
            
            // Final output: sum0 (no delay) + branch1 delayed by 1 + branch2 delayed by 2.
            data_out <= sum0 + delay1 + delay2_2;
        end
    end

endmodule
